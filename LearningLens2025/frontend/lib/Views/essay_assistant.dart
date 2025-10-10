import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';


import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';

class EssayAssistant extends StatefulWidget {
  const EssayAssistant({super.key});

  @override
  State<EssayAssistant> createState() => _EssayAssistantState();
}

// ---------------- Right sidebar (AI controls) state ----------------
// AI modes for the assistant controls
// - brainstorm: generate ideas, questions, theses, etc.
// - draftOutline: structure the essay into sections with points
// - revise: improve clarity, grammar, citations, etc.
enum AiMode { brainstorm, draftOutline, revise }

// ---------- Draft storage (per essay) ----------
class _EssayDraft {
  _EssayDraft({required this.deltaJson, required this.updatedAt});
  final List<dynamic> deltaJson; // Quill Delta JSON
  final DateTime updatedAt;
}

class _EssayAssistantState extends State<EssayAssistant> {
  // ---------------- Chat state ----------------
  final List<types.Message> _messages = [];
  late final types.User _me;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // ---------------- Left sidebar (essays) state ----------------
  int? _selectedSidebarIndex;

  // Real essay assignments loaded from LMS
  List<Assignment> _essays = [];

  // Load essays for the current user (all courses). You can pass a courseId if needed.
  Future<void> _loadEssays({int? courseId}) async {
    final items = await getAllEssays(courseId);
    if (mounted) {
      setState(() => _essays = items);
    }
  }
 

  //Get essay assignments from LMS
  Future<List<Assignment>> getAllEssays(int? courseID) async {
  List<Assignment> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (courseID == 0 || courseID == null || c.id == courseID) {
      result.addAll(c.essays ?? []);
    }
  }
  return result;
}

// Method to get an essay by its ID
Assignment? getEssay(int? essayID, int? courseID) {
  Assignment? result;
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (courseID == 0 || courseID == null || c.id == courseID) {
      for (Assignment a in c.essays ?? []) {
        if (a.id == essayID) {
          result = a;
        }
      }
    }
  }
  return result;
}

String removeHtmlTags(String htmlText) {
  final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
  return htmlText.replaceAll(regex, '');
}


  // ---------------- Right sidebar (AI controls) state ----------------
  AiMode _mode = AiMode.brainstorm;

  // Selected helper dropdown value (changes based on mode)
  String? _selectedHelper;

  // Helpers available for each mode
  final Map<AiMode, List<String>> _helpersByMode = {
    AiMode.brainstorm: [
      'Generate topic ideas',
      'Pros & cons list',
      'Thesis suggestions',
      'Questions to explore',
    ],
    AiMode.draftOutline: [
      '5-paragraph outline',
      'Detailed section outline',
      'Evidence planner',
      'Counterargument outline',
    ],
    AiMode.revise: [
      'Clarity pass',
      'Conciseness pass',
      'Citations/MLA hints',
      'Grammar & tone tips',
    ],
  };

  // Tooltip text for each mode (shown on hover/long-press)
  final Map<AiMode, String> _modeTooltips = {
    AiMode.brainstorm:
        'Explore topics, angles, and theses. Great for starting from a blank page.',
    AiMode.draftOutline:
        'Turn your idea into a structured outline with sections and evidence.',
    AiMode.revise:
        'Improve clarity, flow, grammar, or citations on an existing draft.',
  };

  // General tooltip for the "Helpers" label
  final String _helpersTooltip =
      'Contextual helpers that change with the selected mode.';
  
    // Key your drafts by an essay id (use your real id when you wire LMS data)
  final Map<String, _EssayDraft> _drafts = {};

  // Helper: derive an essayId for the fake list (use real ID later)
  String _essayIdFrom(Map<String, String> essay) => (essay['title'] ?? '').trim();

  // Quick check
  bool _hasDraft(String essayId) => _drafts.containsKey(essayId);

  // ---------------- Quill editor state ----------------
  late final quill.QuillController _quillController;
  final FocusNode _quillFocus = FocusNode();
  final ScrollController _quillScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Current chat user identity (with optional profile image from LMS)
    _me = types.User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      firstName: 'You',
      imageUrl: LmsFactory.getLmsService().profileImage,
    );

    // Seed a welcome system message (renders as full-width text, no bubble)
    _messages.add(
      types.SystemMessage(
        id: const Uuid().v4(),
        text: 'Welcome! Tell me your topic and thesis.',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _quillController = quill.QuillController.basic(
        config: const quill.QuillControllerConfig(
    clipboardConfig: quill.QuillClipboardConfig(
      enableExternalRichPaste: true,
        ),
      ),
    );
    // Load essays from LMS
    _loadEssays();
  }

  // ---------------- Chat: sending messages ----------------
  void _handleSendPressed(types.PartialText partial) {
    if (partial.text.trim().isEmpty) return;

    // Create the user's text message (right-aligned bubble)
    final msg = types.TextMessage(
      id: const Uuid().v4(),
      author: _me,
      text: partial.text.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() => _messages.add(msg));
    _inputCtrl.clear();

    // Simulate an AI system reply (full-width, no bubble)
    Future.delayed(const Duration(milliseconds: 500), () {
      final reply = types.SystemMessage(
        id: const Uuid().v4(),
        text:
            "Testing full-width, no-bubble rendering. This should span the entire chat container so long responses have room for formatting.\n\nAlso handles veryyyyyyyyloooooooongwooooordwithnospaces without overflow on web.",
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      setState(() => _messages.add(reply));
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  // Scroll chat to bottom after new messages render
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
  // ---------------- Cleanup ----------------
  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _quillFocus.dispose();
    _quillController.dispose();
    _quillScrollController.dispose();
    super.dispose();
  }

  // Stub: save a draft to backend (replace with your API)
  Future<void> _saveDraftToBackend(String essayId, List<dynamic> deltaJson) async {
  // TODO: Replace with your real persistence:
  // - Send to your server as JSON
  // - Or store locally (e.g., SharedPreferences / hive) if offline first
  await Future<void>.delayed(const Duration(milliseconds: 150)); // fake I/O
}

// Load a draft from backend (returns null if none found)
Future<_EssayDraft?> _loadDraftFromBackend(String essayId) async {
  // TODO: Replace with your real load call
  return null;
}

  @override
  Widget build(BuildContext context) {
    // Show messages oldest → newest (top → bottom)
    final List<types.Message> chronological = List.of(_messages)
      ..sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Page background
      appBar: CustomAppBar(
        title: 'Essay Assistant',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),

      // Main layout row:
      // [Left: Essay list] | [Center: Chat] | [Right: AI controls]
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =================== LEFT: Essay list (static/fake for now) ===================
          SizedBox(
            width: 280, // Fixed width for the left sidebar
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  // Sidebar header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Essay Assignments',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // List of fake essay items
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      itemCount: _essays.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final assignment = _essays[i];
                        final selected = _selectedSidebarIndex == i;
                        final dueText = assignment.dueDate == null
                            ? 'No due date'
                            : '${assignment.dueDate!.toLocal().toIso8601String().split('T').first}';

                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.08),
                          title: Text(
                            assignment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('Due: $dueText'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            setState(() => _selectedSidebarIndex = i);
                            _openEssayDialog(context, assignment);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =================== CENTER: Chat column ===================
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // ------------- Messages list -------------
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          itemCount: chronological.length,
                          itemBuilder: (context, index) {
                            final m = chronological[index];

                            // 1) AI/system messages (full-width text, no bubble)
                            if (m is types.SystemMessage ||
                                (m is types.CustomMessage &&
                                    (m.metadata?['kind'] == 'bot_text'))) {
                              final text = (m is types.SystemMessage)
                                  ? m.text
                                  : ((m as types.CustomMessage)
                                          .metadata?['text'] as String? ??
                                      '');

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: SelectableText(
                                  text,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.46,
                                  ),
                                ),
                              );
                            }

                            // 2) User messages (right-aligned chat bubble)
                            if (m is types.TextMessage &&
                                m.author.id == _me.id) {
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                alignment: Alignment.centerRight,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    // Keep bubble readable on large screens
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.70,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryFixedDim,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        m.text,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            // 3) Fallback for any other types
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                '(unsupported message type)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ------------- Input bar -------------
                      SafeArea(
                        top: false,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Row(
                            children: [
                              // Text input (multiline)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border:
                                        Border.all(color: Colors.black12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: TextField(
                                      controller: _inputCtrl,
                                      minLines: 1,
                                      maxLines: 6,
                                      decoration: const InputDecoration(
                                        hintText: 'Type a message…',
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendFromField(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Send button
                              ElevatedButton(
                                onPressed: _sendFromField,
                                style: ElevatedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // =================== RIGHT: AI controls column ===================
          SizedBox(
            width: 280, // Fixed width for the right sidebar
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- AI Mode: label + tooltip
                    Row(
                      children: [
                        Text('AI Mode',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: _modeTooltips[_mode]!,
                          triggerMode: TooltipTriggerMode
                              .longPress, // also shows on hover (web/desktop)
                          preferBelow: false,
                          child: const Icon(Icons.help_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // --- AI Mode dropdown
                    DropdownButtonFormField<AiMode>(
                      value: _mode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: AiMode.brainstorm,
                            child: Text('Brainstorm')),
                        DropdownMenuItem(
                            value: AiMode.draftOutline,
                            child: Text('Draft outline')),
                        DropdownMenuItem(
                            value: AiMode.revise, child: Text('Revise')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _mode = val; // Update mode
                          _selectedHelper =
                              null; // Reset helper when mode changes
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // --- Helpers: label + tooltip
                    Row(
                      children: [
                        Text('Helpers',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: _helpersTooltip,
                          preferBelow: false,
                          child: const Icon(Icons.help_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // --- Helpers dropdown (options depend on selected mode)
                    DropdownButtonFormField<String>(
                      value: _selectedHelper,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: _helpersByMode[_mode]!
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(h,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedHelper = val);
                      },
                      hint: const Text('Choose a helper'),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // --- Summary of current selections
                    const SizedBox(height: 12),
                    Text('Current selection',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        'Mode: ${_mode == AiMode.brainstorm ? 'Brainstorm' : _mode == AiMode.draftOutline ? 'Draft outline' : 'Revise'}'
                        '${_selectedHelper == null ? '' : '\nHelper: $_selectedHelper'}',
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                      // === Moved up: action buttons go RIGHT UNDER the summary ===
                      const SizedBox(height: 12),

                    // --- Quick action: inject a system message applying the selection
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _messages.add(
                            types.SystemMessage(
                              id: const Uuid().v4(),
                              text:
                                  'AI mode set to ${_mode == AiMode.brainstorm ? 'Brainstorm' : _mode == AiMode.draftOutline ? 'Draft outline' : 'Revise'}'
                                  '${_selectedHelper == null ? '' : ' • Helper: $_selectedHelper'}',
                              createdAt:
                                  DateTime.now().millisecondsSinceEpoch,
                            ),
                          );
                        });
                        _scrollToBottom();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Apply to next reply'),
                    ),
                     const SizedBox(height: 8),

                    // Open text editor (Quill) — calls a stub for now
                    OutlinedButton.icon(
                      onPressed: () {
                        // Use currently selected essay from left list, or null for a general draft
                        final essay = (_essays.isEmpty || _selectedSidebarIndex == null)
                            ? null
                            : _essays[_selectedSidebarIndex!];
                        _openQuillEditorDialogFor(essay);
                      },
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Open text editor'),
                    ),

                    // Spacer now goes AFTER the two buttons so they sit higher
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================== Essay dialog (centered modal) ===================
  void _openEssayDialog(BuildContext context, Assignment essay) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx).size;
        final maxW = mq.width < 720 ? mq.width - 32 : 640.0;

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,          // Cap width for readability
              maxHeight: mq.height * .85, // Allow scrolling for tall content
            ),
            child: _EssayModalContent(
              title: essay.name,
              due: essay.dueDate.toString(),
              description: essay.description,

              // Start/Continue session → posts a system message to the chat
              onStart: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _messages.add(
                    types.SystemMessage(
                      id: const Uuid().v4(),
                      text:
                          'Starting session for "${essay.name}".',
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                });
                //Creates a new session for the assignment
                
                _scrollToBottom();
              },

              // Submit → asks for confirmation first, then posts a success msg
              onSubmit: () async {
                final essayId = essay.id != null ? essay.id.toString() : 'general_draft';

                // Require a saved draft
                if (!_hasDraft(essayId)) {
                  final goEdit = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('No draft found'),
                      content: const Text('You need to save a draft before submitting. Open the editor now?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Open editor')),
                      ],
                    ),
                  ) ?? false;

                  if (goEdit) {
                    Navigator.of(context).pop(); // close the essay modal first
                    _openQuillEditorDialogFor(essay); // open editor for that essay
                  }
                  return;
                }

                // If you want, also sync the draft once more before final submit
                // await _saveDraftToBackend(essayId, _drafts[essayId]!.deltaJson);

                // Confirm submission
                final confirmed = await _showSubmitConfirmation(context);
                if (!confirmed) return;

                Navigator.of(context).pop(); // close the essay modal

                // TODO: real submission using _drafts[essayId]!.deltaJson
                // await _submitEssay(essayId, _drafts[essayId]!.deltaJson);

                // (Optional) notify user (no chat coupling needed; a snackbar is fine)
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('“${essay.name}” submitted.')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Small confirmation dialog for Submit
  Future<bool> _showSubmitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text('Confirm Submission'),
              content: const Text(
                'Are you sure you want to submit this essay?\n'
                'After submitting, it will be locked for editing.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

 void _openQuillEditorDialogFor(Assignment? essay) async {
  // Decide which essay this draft belongs to
  final essayId = essay?.id.toString() ?? 'general_draft';
  final essayTitle = essay?.name ?? 'General Draft';

  // Load existing draft if present
    if (_drafts.containsKey(essayId)) {
      final ops = _drafts[essayId]!.deltaJson; // List<dynamic> of delta ops
      _quillController.document = quill.Document.fromJson(ops);
    } else {
      _quillController.document = quill.Document(); // empty
    }

  // Show the editor
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx).size;
      final maxW = mq.width < 900 ? mq.width - 32 : 820.0;
      final maxH = mq.height < 700 ? mq.height - 80 : 600.0;

      return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Builder(
            builder: (ctx) {
              final mq = MediaQuery.of(ctx).size;
              final double w = mq.width.clamp(480, 1100);   // min/max guard
              final double h = mq.height.clamp(420, 900);   // min/max guard

              return SizedBox(                 // <- tight constraints (fixes viewport)
                width: w * 0.85,
                height: h * 0.85,
                child: Column(
                  children: [
                    // ----- header -----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_outlined, size: 22),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Editor • $essayTitle',
                              style: Theme.of(context).textTheme.titleMedium)),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // ----- toolbar (no embeds while we stabilize) -----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: quill.QuillSimpleToolbar(
                        controller: _quillController,
                        config: const quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showDividers: true,
                          showClipboardPaste: true,
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // ----- editor (stable scrollController) -----
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: quill.QuillEditor(
                          focusNode: _quillFocus,
                          scrollController: _quillScrollController,
                          controller: _quillController,
                          config: const quill.QuillEditorConfig(
                            placeholder: 'Write your essay here…',
                            padding: EdgeInsets.all(8),
                            // no embedBuilders yet
                          ),
                        ),
                      ),
                    ),

                    // ----- footer -----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save draft'),
                            onPressed: () async {
                              final deltaJson = _quillController.document.toDelta().toJson();
                              setState(() {
                                _drafts[essayId] = _EssayDraft(
                                  deltaJson: deltaJson,
                                  updatedAt: DateTime.now(),
                                );
                              });
                              await _saveDraftToBackend(essayId, deltaJson);
                              if (mounted) Navigator.of(ctx).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Draft saved')));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
    });
 }


  void _sendFromField() {
    final txt = _inputCtrl.text;
    _handleSendPressed(types.PartialText(text: txt));
  }
}

// =================== Essay modal content (inside centered dialog) ===================
class _EssayModalContent extends StatelessWidget {
  const _EssayModalContent({
    required this.title,
    required this.due,
    required this.description,
    required this.onStart,
    required this.onSubmit, 
  });

  final String title;
  final String due;
  final dynamic description;
  final VoidCallback onStart;
  final VoidCallback onSubmit;
  
  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- Header row with title + close button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ---- Scrollable body with details/prompt
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LabeledRow(label: 'Status', value: 'Not started'),
                const SizedBox(height: 8),
                _LabeledRow(label: 'Due', value: due),
                const SizedBox(height: 8),
                Text(
                  'Description',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ),

        // ---- Footer action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onStart, // Triggers session start
                  child: const Text('Start / Continue session'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onSubmit, // Opens confirmation, then submit
                    child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Small labeled row used in the dialog body
class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styleLabel = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey[700]);
    final styleValue = Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: styleLabel)),
        Expanded(child: Text(value, style: styleValue)),
      ],
    );
  }
}
