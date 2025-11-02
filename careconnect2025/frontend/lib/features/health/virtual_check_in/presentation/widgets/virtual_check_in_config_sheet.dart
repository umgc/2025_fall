import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_question.dart';

import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_backend_question_model.dart';
import 'package:care_connect_app/features/health/virtual_check_in/models/question_type.dart'; // <-- BackendQuestionType lives here
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_mapper.dart' as vmap;

import 'package:care_connect_app/features/health/virtual_check_in/services/checkin_api.dart';    // if you fetch questions per check-in



VirtualCheckInQuestion _toUiQuestion(BackendQuestionDto dto) {
  late CheckInQuestionType uiType;
  switch (dto.type) {
    case BackendQuestionType.number:
      uiType = CheckInQuestionType.numerical;
      break;
    case BackendQuestionType.yesNo:
    case BackendQuestionType.trueFalse:
      uiType = CheckInQuestionType.yesNo;
      break;
    case BackendQuestionType.text:
      uiType = CheckInQuestionType.textInput;
      break;
  }

  return VirtualCheckInQuestion(
    id: dto.id.toString(),
    type: uiType,
    required: dto.required,
    text: dto.prompt,
  );
}

/// Bottom sheet that edits the patient's Virtual Check-In questions.
/// It fetches existing questions, allows local edits, and returns the edited list on Save.
class VirtualCheckInConfigSheet extends StatefulWidget {
  final int checkInId;
  final List<VirtualCheckInQuestion> initial; // optional seed

  const VirtualCheckInConfigSheet({
    super.key,
    required this.checkInId,
    required this.initial,
  });

  @override
  State<VirtualCheckInConfigSheet> createState() => _VirtualCheckInConfigSheetState();
}

class _VirtualCheckInConfigSheetState extends State<VirtualCheckInConfigSheet> {
  // Backend
  late final CheckInApi _api;
  bool _loading = true;
  String? _error;

  // The working list we render/edit
  late List<VirtualCheckInQuestion> _items;

  // Track which question IDs have been deleted (for deactivation)
  final Set<int> _deletedQuestionIds = {};

  // "Add New Question" form state
  CheckInQuestionType _newType = CheckInQuestionType.numerical;
  bool _newRequired = false;
  final TextEditingController _newTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final base = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
    _api = CheckInApi(base);
    _items = List<VirtualCheckInQuestion>.from(widget.initial);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<BackendQuestionDto> backend =
      await _api.getQuestions(widget.checkInId.toString()); // <-- convert to String

      setState(() {
        _items = backend.map(vmap.toUiQuestion).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfiguration(BuildContext context) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Step 1: Deactivate deleted questions
      for (final deletedId in _deletedQuestionIds) {
        await _api.deactivateQuestion(deletedId);
      }

      // Step 2: Create or update each question
      for (int i = 0; i < _items.length; i++) {
        final uiQuestion = _items[i];
        final backendDto = _toBackendDto(uiQuestion, i);

        if (backendDto.id != null) {
          // Existing question - update it
          await _api.updateQuestion(backendDto.id!, backendDto);
        } else {
          // New question - create it
          await _api.createQuestion(backendDto);
        }
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questions saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Close the config sheet and return the updated list
      if (mounted) {
        Navigator.pop(context, _items);
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _newTextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final border = cs.outlineVariant.withValues(alpha: .35);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Configure Virtual Check-In Questions',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $_error',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
                  ),
                )
              else
              // ── Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Current Questions
                        Text(
                          'Current Questions',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),

                        ..._items.asMap().entries.map((e) {
                          final i = e.key;
                          final q = e.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // row: icon • type badge • required • index • trash
                                Row(
                                  children: [
                                    _typeLeadingIcon(q.type, cs),
                                    const SizedBox(width: 8),
                                    _pillOutlined(
                                      context,
                                      label: _prettyTypeLabel(q.type),
                                      borderColor: cs.outlineVariant,
                                      textColor: cs.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    if (q.required)
                                      _pillFilled(
                                        context,
                                        label: 'Required',
                                        bg: cs.error,
                                        fg: cs.onError,
                                      ),
                                    const SizedBox(width: 8),
                                    _pillOutlined(
                                      context,
                                      label: '#${i + 1}',
                                      borderColor: cs.surfaceContainerHighest.withValues(alpha: .25),
                                      textColor: cs.onSurfaceVariant,
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Delete question',
                                      onPressed: () {
                                        setState(() {
                                          // Track deleted question ID for backend deactivation
                                          final questionId = int.tryParse(q.id);
                                          if (questionId != null) {
                                            _deletedQuestionIds.add(questionId);
                                          }
                                          _items.removeAt(i);
                                        });
                                      },
                                      icon: Icon(Icons.delete_outline, color: cs.error),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  q.text,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _typeHelperText(q.type),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.70),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 24),

                        // ── Add New Question
                        Text(
                          'Add New Question',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        // Subtitles
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Question Type',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurface.withValues(alpha: .8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Options',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurface.withValues(alpha: .8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Dropdown (left) + Required checkbox (right)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownMenu<CheckInQuestionType>(
                                initialSelection: _newType,
                                onSelected: (v) =>
                                    setState(() => _newType = v ?? CheckInQuestionType.numerical),
                                requestFocusOnTap: true,
                                enableFilter: false,
                                expandedInsets: EdgeInsets.zero,
                                textStyle: theme.textTheme.bodyLarge,
                                leadingIcon: _typeLeadingIcon(_newType, cs),
                                menuStyle: MenuStyle(
                                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                inputDecorationTheme: InputDecorationTheme(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: cs.primary),
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(
                                    value: CheckInQuestionType.numerical,
                                    label: 'Numerical (1–10 scale)',
                                    leadingIcon: Icon(Icons.onetwothree, size: 18),
                                  ),
                                  DropdownMenuEntry(
                                    value: CheckInQuestionType.textInput,
                                    label: 'Text Input',
                                    leadingIcon: Icon(Icons.edit, size: 18),
                                  ),
                                  DropdownMenuEntry(
                                    value: CheckInQuestionType.yesNo,
                                    label: 'Yes/No',
                                    leadingIcon: Icon(Icons.task_alt, size: 18),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CheckboxListTile(
                                value: _newRequired,
                                onChanged: (v) => setState(() => _newRequired = v ?? false),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('Required question'),
                                side: const BorderSide(color: Colors.grey),
                                fillColor: WidgetStateProperty.all(Colors.white),
                                checkColor: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Question Text',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: .8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        TextField(
                          controller: _newTextCtrl,
                          textInputAction: TextInputAction.done,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Enter your check-in question...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary),
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .25)
                                  : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .12),
                              foregroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              disabledBackgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                              disabledForegroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: .45),
                            ),
                            onPressed: _newTextCtrl.text.trim().isEmpty
                                ? null
                                : () {
                              setState(() {
                                _items.add(
                                  VirtualCheckInQuestion(
                                    id: DateTime.now()
                                        .microsecondsSinceEpoch
                                        .toString(),
                                    type: _newType,
                                    required: _newRequired,
                                    text: _newTextCtrl.text.trim(),
                                  ),
                                );
                                _newTextCtrl.clear();
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Question'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Divider(height: 1),

              // ── Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: .8),
                          width: 1.2,
                        ),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        textStyle: Theme.of(context).textTheme.labelLarge,
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimary,
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _saveConfiguration(context),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Configuration'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers

  /// Convert UI question to backend DTO for API calls
  BackendQuestionDto _toBackendDto(VirtualCheckInQuestion uiQuestion, int index) {
    BackendQuestionType backendType;
    switch (uiQuestion.type) {
      case CheckInQuestionType.numerical:
        backendType = BackendQuestionType.number;
        break;
      case CheckInQuestionType.yesNo:
        backendType = BackendQuestionType.yesNo;
        break;
      case CheckInQuestionType.textInput:
        backendType = BackendQuestionType.text;
        break;
    }

    // Try to parse the ID as an integer (existing questions)
    // New questions will have timestamp-based IDs that won't parse
    int? questionId;
    try {
      questionId = int.parse(uiQuestion.id);
    } catch (_) {
      questionId = null; // New question without backend ID
    }

    return BackendQuestionDto(
      id: questionId,
      prompt: uiQuestion.text,
      type: backendType,
      required: uiQuestion.required,
      active: true,
      ordinal: index,
    );
  }

  Widget _pillOutlined(
      BuildContext context, {
        required String label,
        required Color borderColor,
        required Color textColor,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest.withValues(alpha: .18) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? cs.outlineVariant.withValues(alpha: .45) : borderColor,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isDark ? cs.onSurface : textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }

  Widget _pillFilled(
      BuildContext context, {
        required String label,
        required Color bg,
        required Color fg,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }

  Widget _typeLeadingIcon(CheckInQuestionType t, ColorScheme cs) {
    switch (t) {
      case CheckInQuestionType.numerical:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2666F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '123',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        );
      case CheckInQuestionType.yesNo:
        return Icon(Icons.task_alt, color: Colors.green.shade600, size: 20);
      case CheckInQuestionType.textInput:
        return const Icon(Icons.edit, color: Color(0xFFFF7A00), size: 20);
    }
  }

  String _prettyTypeLabel(CheckInQuestionType t) {
    switch (t) {
      case CheckInQuestionType.numerical:
        return 'Numerical';
      case CheckInQuestionType.yesNo:
        return 'Yes/No';
      case CheckInQuestionType.textInput:
        return 'Input';
    }
  }

  String _typeHelperText(CheckInQuestionType t) {
    switch (t) {
      case CheckInQuestionType.numerical:
        return 'Expects a number input';
      case CheckInQuestionType.yesNo:
        return 'Yes/No selection';
      case CheckInQuestionType.textInput:
        return 'Free text input';
    }
  }
}
