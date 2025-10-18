// ─────────────────────────────────────────────────────────────────────────────
// Essay Assistant Screen
// Organized for clarity without changing behavior or identifiers.
// Sections:
//   1) Imports
//   2) Top-level types/utilities (enum, draft holder, helpers)
//   3) EssayAssistant widget + State
//      3.1) State fields
//      3.2) Lifecycle (init/dispose)
//      3.3) Chat handling (send/scroll)
//      3.4) LMS essay loading (left sidebar)
//      3.5) Quill editor state + draft persistence stubs
//      3.6) Build method (layout: Left | Center | Right)
//      3.7) Modals (Essay details, Submit confirm, Quill editor)
//   4) Pure helpers (top-level functions)
//   5) Small UI helpers (stateless widgets)
// ─────────────────────────────────────────────────────────────────────────────

/* ────────────────────────────────────────────────────────────────────────────
 * 1) Imports
 * Keep framework → domain → UI → 3rd-party consistent and grouped.
 * ──────────────────────────────────────────────────────────────────────────── */
//import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';

import 'package:learninglens_app/Views/essays_view.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:learninglens_app/beans/essay_assistant_session.dart';
import 'package:learninglens_app/services/LLMContextBuilder.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/prompt_builder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


/* ────────────────────────────────────────────────────────────────────────────
 * 2) Top-level types / utilities
 *  - Enum for AI modes (right sidebar)
 *  - Lightweight draft holder for Quill JSON
 *  - NOTE: Keep these top-level to avoid hot-reload reorder churn.
 * ──────────────────────────────────────────────────────────────────────────── */

/// AI modes for the assistant controls (right sidebar).
/// - brainstorm: generate ideas, questions, theses, etc.
/// - draftOutline: structure the essay into sections with points
/// - revise: improve clarity, grammar, citations, etc.
enum AiMode {
  brainstorm,
  revise,
  draftOutline,
  assistant
}
enum PreBuiltPrompt {
  GenerateTopicIdeas,
  QuestionsToExplore,
  FindSources,
  CreateOutline,
  GrammarToneSpellCheck,
  ClarityandConciseness,
  CitationsandFormatting,
}

/// Simple container for a saved essay draft.
/// `deltaJson` is the Quill Delta (ops) JSON shape.
class _EssayDraft {
  _EssayDraft({required this.deltaJson, required this.updatedAt});
  final List<dynamic> deltaJson; // Quill Delta JSON
  final DateTime updatedAt;
}
class _NotesDraft {
  _NotesDraft({required this.deltaJson, required this.updatedAt});
  final List<dynamic> deltaJson; // Quill Delta JSON
  final DateTime updatedAt;
}

/* ────────────────────────────────────────────────────────────────────────────
 * 3) EssayAssistant Widget
 * ──────────────────────────────────────────────────────────────────────────── */
class EssayAssistant extends StatefulWidget {
  const EssayAssistant({super.key});

  @override
  State<EssayAssistant> createState() => _EssayAssistantState();
}

class _EssayAssistantState extends State<EssayAssistant> {
  /* ──────────────────────────────────────────────────────────────────────────
   * 3.1) State fields
   *  - Session
   *  - Chat
   *  - Sidebars (left: essays; right: AI controls)
   *  - Quill editor
   *  - Draft storage (per essay)
   * ────────────────────────────────────────────────────────────────────────── */


  // ------------- Session state  -------------
  SharedPreferences? _prefs;
  EssaySession? _currentSession;     // currently active session (if any)
  final Map<String, EssaySession> _sessions = {}; // key: essayId (String), value: EssaySession
  
  bool get _sessionActive => _currentSession != null;
  String get essayID => _currentSession?.id ?? '';

  Future<void> _startSessionFor(Assignment essay, {bool replay = true}) async {
    //Clear chat UI
    setState(() {
      _messages.clear();
      _inputCtrl.clear(); 
    });
    // Get EssayKey
    final String essayKey =
      (essay.id != null) ? essay.id.toString() : 'general_${essay.name.hashCode}';
    if (replay && _currentSession!.chatLog.isNotEmpty) {
    setState(() {
      for (final turn in _currentSession!.chatLog) {
        if (turn.isUser) {
          _messages.add(
            types.TextMessage(
              id: const Uuid().v4(),
              author: _me,
              text: turn.content,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        } else {
          _messages.add(
            types.SystemMessage(
              id: const Uuid().v4(),
              text: turn.content,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }
    });
  } else {
    // Fresh system line so the chat isn’t empty
    _appendSystemMessage('Starting session for "${essay.name}".');
  }

  //Persist right away so this session is saved separately
  await _saveCurrentSessionToPrefs();

  _scrollToBottom();
}


  void _guardNoSession() {
    if (!_sessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start or continue a session first.')),
      );
    }
  }

  // ---------------- Chat state ----------------
  final List<types.Message> _messages = [];
  late final types.User _me;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  // ---------------- Left sidebar (essays) state ----------------
  int? _selectedSidebarIndex;        // selected essay index in the left list
  List<Assignment> _essays = [];     // loaded from LMS (all courses or filtered)

  // ---------------- Right sidebar (AI controls) state ----------------
  AiMode _mode = AiMode.brainstorm;  // current AI mode
  PreBuiltPrompt? _selectedHelper;  // helper within a mode (dropdown)
  late LlmType _selectedLLM;          // your enum (with .displayName)
  double _temperature = 0.7;      // 0.0–2.0 typical; start reasonable

  // Helpers available for each mode
  final Map<AiMode, Map<String, PreBuiltPrompt>> _helpersByMode = {
    AiMode.brainstorm: {
      'Generate topic ideas': PreBuiltPrompt.GenerateTopicIdeas,
      'Questions to explore': PreBuiltPrompt.QuestionsToExplore,
      'Find sources': PreBuiltPrompt.FindSources,
    },
    AiMode.draftOutline: {
      'Create outline': PreBuiltPrompt.CreateOutline,
    },
    AiMode.revise: {
      'General Revision': PreBuiltPrompt.GrammarToneSpellCheck,
      'Clarity and conciseness': PreBuiltPrompt.ClarityandConciseness,
      'Citations and formatting': PreBuiltPrompt.CitationsandFormatting,
    },
    AiMode.assistant: {
      '-': PreBuiltPrompt.GenerateTopicIdeas, // Placeholder
    }
  };

  // Tooltip text for each mode (shown on hover/long-press)
  final Map<AiMode, String> _modeTooltips = {
    AiMode.brainstorm:
        'Explore topics, angles, and theses. Great for starting from a blank page.',
    AiMode.draftOutline:
        'Turn your idea into a structured outline with sections and evidence.',
    AiMode.revise:
        'Improve clarity, flow, grammar, or citations on an existing draft.',
    AiMode.assistant:
        'More open-ended assistance with your essay.',
  };

  // General tooltip for the "Helpers" label
  final String _helpersTooltip =
      'Contextual helpers that change with the selected mode.';

  // ---------------- Quill editor state ----------------
  late final quill.QuillController _quillDraftController;
  final FocusNode _draftFocus = FocusNode();
  final ScrollController _quillDraftScrollController = ScrollController();

  late final quill.QuillController _quillNotesController;
  final FocusNode _notesFocus = FocusNode();
  final ScrollController _quillNotesScrollController = ScrollController();

  /* ──────────────────────────────────────────────────────────────────────────
   * 3.2) Lifecycle
   * ────────────────────────────────────────────────────────────────────────── */

  @override
   void initState() {
    super.initState();
    _loadAllSessionsFromPrefs(); 

    // Current chat user identity (with optional profile image from LMS)
    _me = types.User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      firstName: 'You',
      imageUrl: LmsFactory.getLmsService().profileImage,
    );

    // Seed a welcome system message (renders as full-width text, no bubble)
    _appendSystemMessage('Welcome to the Essay Assistant!');
    _loadAllSessionsFromPrefs();

    // Quill controller with basic config (external rich paste enabled)
    _quillDraftController = quill.QuillController.basic(
      config: const quill.QuillControllerConfig(
        clipboardConfig: quill.QuillClipboardConfig(
          enableExternalRichPaste: true,
        ),
      ),
    );
    // Notes editor
    _quillNotesController = quill.QuillController.basic(
      config: const quill.QuillControllerConfig(
        clipboardConfig: quill.QuillClipboardConfig(
          enableExternalRichPaste: true,
        ),
      ),
    );

    // Load essays from LMS into left sidebar
    _loadEssays();

    // Pick first LLM that has a configured key; else first enum value
    _selectedLLM = LlmType.values.firstWhere(
      (llm) => LocalStorageService.userHasLlmKey(llm),
    orElse: () => LlmType.values.first,
    );
  }

  @override
  void dispose() {
    // Clean up controllers/focus to avoid leaks
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _draftFocus.dispose();
    _quillDraftController.dispose();
    _quillDraftScrollController.dispose();
    _notesFocus.dispose();
    _quillNotesController.dispose();
    _quillNotesScrollController.dispose();
    super.dispose();
  }


  /* ──────────────────────────────────────────────────────────────────────────
   * 3.3) Chat handling (send / scroll)
   *  - _handleSendPressed: adds user message and gets LLM response
   *  - _scrollToBottom: keep the view pinned to latest
   * ────────────────────────────────────────────────────────────────────────── */

  void _handleSendPressed(types.PartialText partial) {
    if (partial.text.trim().isEmpty) return;
    _appendUserMessage(partial.text.trim());
    _inputCtrl.clear();

    //Get LLM response
    getLLMResponse(partial.text.trim(), _selectedLLM, _temperature).then((response) {
      if (response != null && response.isNotEmpty) {
        _appendAssistantMessage(response);
        _scrollToBottom();
      } else {
        _appendSystemMessage('Error: No response from the AI model.');
      }
    }).catchError((error) {
      _appendSystemMessage('Error getting AI response: $error');
    });
    _scrollToBottom();
  }

  // Helper to append user message (GenerateContext appends to ChatLog)
  void _appendUserMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // UI (SetState)
    setState(() {
      _messages.add(
        types.TextMessage(
          id: const Uuid().v4(),
          author: _me,
          text: trimmed,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  // Helper to append AI/assistant message and log it if session active
  void _appendAssistantMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // UI (SetState)
    setState(() {
      _messages.add(
        types.SystemMessage(
          id: const Uuid().v4(),
          text: trimmed,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  // Helper to append System lines only
  void _appendSystemMessage(String text) {
    setState(() {
      _messages.add(
        types.SystemMessage(
          id: const Uuid().v4(),
          text: text.trim(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }
    /// Core method to get LLM response based on current session and context
    Future<String?> getLLMResponse(String userPrompt, LlmType llm, double temperature) async {
    if (!_sessionActive) {
      _appendSystemMessage('No active session.');
      return null;
    }

    // Description (already in session.essay)
    final essayDescription = removeHtmlTags(
      _currentSession!.essay.description?.toString() ?? '',
    ).trim();

    // Draft / Notes → plain text
    String? submissionText;
    if (_currentSession!.draftDeltaOps != null) {
      try {
        submissionText = quill.Document.fromJson(_currentSession!.draftDeltaOps!)
            .toPlainText()
            .trim();
        if (submissionText!.isEmpty) submissionText = null;
      } catch (_) {}
    }

    String? notesText;
    if (_currentSession!.notesDeltaOps != null) {
      try {
        notesText = quill.Document.fromJson(_currentSession!.notesDeltaOps!)
            .toPlainText()
            .trim();
        if (notesText!.isEmpty) notesText = null;
      } catch (_) {}
    }

    final permContext = essayAssistPromptBuilder(
      _mode,
      submissionText,
      notesText,
      essayDescription,
    );

    final chatLog = _currentSession!.chatLog;

    // pick model (your existing switch, but return if no key)
    LLM? aiModel;
    switch (_selectedLLM) {
      case LlmType.CHATGPT:
        final key = LocalStorageService.getOpenAIKey();
        if (key.isEmpty) return _appendError('OpenAI key missing');
        aiModel = OpenAiLLM(key);
        break;
      case LlmType.GROK:
        final key = LocalStorageService.getGrokKey();
        if (key.isEmpty) return _appendError('Grok key missing');
        aiModel = GrokLLM(key);
        break;
      case LlmType.PERPLEXITY:
        final key = LocalStorageService.getPerplexityKey();
        if (key.isEmpty) return _appendError('Perplexity key missing');
        aiModel = PerplexityLLM(key);
        break;
      case LlmType.DEEPSEEK:
        final key = LocalStorageService.getDeepseekKey();
        if (key.isEmpty) return _appendError('Deepseek key missing');
        aiModel = DeepseekLLM(key);
        break;
    }
    if (aiModel == null) return null;

    final fullContext = generateContext(
      permTokens: permContext,
      chatHistory: chatLog,
      userPrompt: userPrompt,
      llmContextSize: aiModel.contextSize,
      maxOutputTokens: aiModel.maxOutputTokens,
    );

    final response = await aiModel.chat(
      context: fullContext,
      temperature: temperature,
    );

    // Log + persist after each round
    _currentSession!.chatLog.add(ChatTurn(role: 'user', content: userPrompt));
    if (response != null && response.isNotEmpty) {
      _currentSession!.chatLog.add(ChatTurn(role: 'assistant', content: response));
    }
    await _saveCurrentSessionToPrefs();

    return response;
  }

  String? _appendError(String msg) {
    _appendSystemMessage('Error: $msg');
    return null;
  }

  void _scrollToBottom() {
    // Schedule after frame so list length/size is final
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


  /* ──────────────────────────────────────────────────────────────────────────
   * 3.4) LMS essay loading (left sidebar)
   *  - _loadEssays(): wraps the top-level getAllEssays() call and sets state
   *    NOTE: getAllEssays/getEssay are top-level functions at the bottom.
   * ────────────────────────────────────────────────────────────────────────── */

  /// Load essays for the current user (all courses). Pass a courseId if needed.
  Future<void> _loadEssays({int? courseId}) async {
    final items = await getAllEssays(courseId);
    if (mounted) {
      setState(() => _essays = items);
    }
  }


  /* ──────────────────────────────────────────────────────────────────────────
   * 3.5) Quill editor + draft/notes/session persistence
   *  - _saveDraftToBackend / _loadDraftFromBackend: placeholders for wiring
   *  - _openQuillEditorDialogFor: modal editor flows with Save Draft
   * ────────────────────────────────────────────────────────────────────────── */

  // ------ Session -----
  /// Key for local storage of essay sessions
  static const String _kSessionKey = 'essay_sessions_v1';
  //  Helper to convert EssaySession map for storage
  Map<String, dynamic> _sessionToMap(EssaySession session) {
    return {
      'id': session.id,
      'mode': session.mode.name,
      'essay': {
        'id': session.essay.id,
        'name': session.essay.name,
        'description': session.essay.description,
        'dueDate': session.essay.dueDate?.toIso8601String(),
        'cutoffDate': session.essay.cutoffDate?.toIso8601String(),  
        'isDraft': session.essay.isDraft,
        'maxAttempts': session.essay.maxAttempts,
        'gradingStatus': session.essay.gradingStatus,
        'courseId': session.essay.courseId,
      },
      'chatLog': session.chatLog
          .map((turn) => {'role': turn.role, 'content': turn.content})
          .toList(),
      'finalText': session.finalText,
      'notesText': session.notesText,
      'draftDeltaOps': session.draftDeltaOps,
      'notesDeltaOps': session.notesDeltaOps,
    };
  }
  // Helper to rebuild EssaySession from Map
  EssaySession _sessionFromMap(Map<String, dynamic> m) {
  final e = (m['essay'] as Map).cast<String, dynamic>();
  return EssaySession(
    essay: Assignment(
      id: e['id'],
      name: e['name'],
      description: e['description'],
      dueDate: (e['dueDate'] is String && (e['dueDate'] as String).isNotEmpty)
          ? DateTime.parse(e['dueDate'])
          : null,
      cutoffDate: (e['cutoffDate'] is String && (e['cutoffDate'] as String).isNotEmpty)
          ? DateTime.parse(e['cutoffDate'])
          : null,
      isDraft: e['isDraft'] ?? false,
      maxAttempts: e['maxAttempts'] ?? 0,
      gradingStatus: e['gradingStatus'] ?? 0,
      courseId: e['courseId'] ?? 0,
    ),
    id: m['id'],
    mode: AiMode.values.firstWhere(
      (x) => x.name == (m['mode'] ?? 'brainstorm'),
      orElse: () => AiMode.brainstorm,
    ),
    chatLog: ((m['chatLog'] as List?) ?? const [])
        .whereType<Map>()
        .map((x) => ChatTurn(role: x['role'] ?? 'assistant', content: x['content'] ?? ''))
        .toList(),
    finalText: m['finalText'],
    notesText: m['notesText'],
    // If you added these fields to EssaySession, pass them in:
    draftDeltaOps: (m['draftDeltaOps'] as List?)?.toList(),
    notesDeltaOps: (m['notesDeltaOps'] as List?)?.toList(),
  );
}

  /// Save ALL sessions to backend/local storage
  Future<void> _saveAllSessionToPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    final payload = _sessions.map((k, v) => MapEntry(k, _sessionToMap(v)));
    await _prefs?.setString(_kSessionKey, jsonEncode(payload));
  }

  /// Load ALL sessions from backend/local storage
  Future<void> _loadAllSessionsFromPrefs() async {
  _prefs ??= await SharedPreferences.getInstance();
  final raw = _prefs?.getString(_kSessionKey);
  if (raw == null || raw.isEmpty) return;

  final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
  final rebuilt = <String, EssaySession>{};
  decoded.forEach((key, value) {
    rebuilt[key] = _sessionFromMap((value as Map).cast<String, dynamic>());
  });

  setState(() {
    _sessions
      ..clear()
      ..addAll(rebuilt);
  });
}

/// Save only the *current* session (lightweight call).
Future<void> _saveCurrentSessionToPrefs() async {
  if (_currentSession == null) return;
  final id = _currentSession!.id;
  _sessions[id] = _currentSession!;
  await _saveAllSessionToPrefs();
}



  /* ──────────────────────────────────────────────────────────────────────────
   * 3.6) Build Method – Main layout:
   *       [Left: Essay list] | [Center: Chat] | [Right: AI controls]
   * ────────────────────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    // Show messages oldest → newest (top → bottom)
    final List<types.Message> chronological = List.of(_messages)
      ..sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CustomAppBar(
        title: 'Essay Assistant',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =================== LEFT: Essay list ===================
          SizedBox(
            width: 280,
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

                  // List of essay items (from LMS)
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
                            : '${assignment.dueDate!
                                .toLocal()
                                .toIso8601String()
                                .split('T')
                                .first}';

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

                          // (1) AI/system messages (full-width text, no bubble)
                          if (m is types.SystemMessage ||
                              (m is types.CustomMessage && (m.metadata?['kind'] == 'bot_text'))) {
                            final text = (m is types.SystemMessage)
                                ? m.text
                                : ((m as types.CustomMessage).metadata?['text'] as String? ?? '');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: MarkdownBody(
                                  data: text,
                                  selectable: true, // lets users highlight/copy text
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                    p: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.46),
                                    strong: const TextStyle(fontWeight: FontWeight.bold),
                                    em: const TextStyle(fontStyle: FontStyle.italic),
                                    a: const TextStyle(
                                      color: Colors.blueAccent,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                            // (2) User messages (right-aligned bubble)
                            if (m is types.TextMessage && m.author.id == _me.id) {
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                alignment: Alignment.centerRight,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    // Keep bubble readable on large screens
                                    maxWidth:
                                        MediaQuery.of(context).size.width * .70,
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

                            // (3) Fallback for any other types
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
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: TextField(
                                      controller: _inputCtrl,
                                      enabled: _sessionActive,
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
                                onPressed: _sessionActive ? _sendFromField : _guardNoSession,
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
            width: 280,
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
                          triggerMode: TooltipTriggerMode.longPress,
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: AiMode.assistant,
                            child: Text('Assistant')),
                        DropdownMenuItem(
                            value: AiMode.brainstorm,
                            child: Text('Brainstorm')),
                        DropdownMenuItem(
                            value: AiMode.draftOutline,
                            child: Text('Draft outline')),
                        DropdownMenuItem(
                            value: AiMode.revise,
                            child: Text('Revise')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _mode = val;      // Update mode
                          _selectedHelper = null; // Reset helper when mode changes
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
                    DropdownButtonFormField<PreBuiltPrompt>(
                      value: _selectedHelper,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _helpersByMode[_mode]!
                          .entries
                          .map((entry) => DropdownMenuItem<PreBuiltPrompt>(
                                value: entry.value,
                                child: Text(entry.key),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedHelper = val);
                      },
                      hint: const Text('Choose a helper'),
                    ),

                    const SizedBox(height: 8),

                    // --- Button to submit Pre-built prompt as user message.
                   FilledButton.icon(
                    onPressed: _sessionActive
                        ? () {
                          var submittedPrompt = types.PartialText(text: getPreBuiltPrompt(_selectedHelper));
                            _handleSendPressed(submittedPrompt);
                            _scrollToBottom();
                          }
                        : _guardNoSession,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Send helper Prompt'),
                ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),


                    // ───────────────────────── LLM picker ─────────────────────────
                    Row(
                      children: [
                        Text('Model', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Choose which LLM to use for replies.',
                          preferBelow: false,
                          child: const Icon(Icons.help_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: DropdownButton<LlmType>(
                        isExpanded: true,
                        value: _selectedLLM,
                        underline: const SizedBox.shrink(),
                        onChanged: (LlmType? newValue) {
                          if (newValue == null) return;
                          if (_hasKeyFor(newValue)) {
                            setState(() => _selectedLLM = newValue);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No API key set for ${newValue.displayName}.')),
                            );
                          }
                        },
                        items: LlmType.values.map((llm) {
                          final enabled = _hasKeyFor(llm);
                          return DropdownMenuItem<LlmType>(
                            value: llm,
                            enabled: enabled,
                            child: Text(
                              llm.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: enabled ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // ───────────────────────── Temperature slider ─────────────────────────
                    Row(
                      children: [
                        Text('Creativity (temperature)',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 6),
                        Tooltip(
                          message:
                              'Lower = focused/deterministic. Higher = creative/diverse.\nTypical range 0.0–1.2; some models allow up to 2.0.',
                          preferBelow: false,
                          child: const Icon(Icons.help_outline, size: 18),
                        ),
                        const Spacer(),
                        // live value readout
                        Text(_temperature.toStringAsFixed(2),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    Slider(
                      value: _temperature,
                      min: 0.0,
                      max: 2.0,          // adjust to your model’s max if needed
                      divisions: 40,     // 0.05 steps
                      label: _temperature.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _temperature = v),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),



                    const SizedBox(height: 8),

                    // --- Open text editor (Quill)
                    OutlinedButton.icon(
                      onPressed: _sessionActive
                          ? () {
                        // Use currently selected essay from left list, or null for a general draft
                        final essay = (_essays.isEmpty || _selectedSidebarIndex == null)
                            ? null
                            : _essays[_selectedSidebarIndex!];
                        _openQuillEditorDialogFor(essay);
                      }
                      : _guardNoSession,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Open text editor'),
                    ),
                    const SizedBox(height: 8),
                    
                    // --- Open notes editor (Quill)
                    OutlinedButton.icon(
                      onPressed: _sessionActive
                          ? () {
                              final essay = (_essays.isEmpty || _selectedSidebarIndex == null)
                                  ? null
                                  : _essays[_selectedSidebarIndex!];
                              _openNotesEditorDialogFor(essay);
                            }
                          : _guardNoSession,
                      icon: const Icon(Icons.sticky_note_2_outlined),
                      label: const Text('Open notes'),
                    ),

                    // Push controls to top, leave some breathing room
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


  /* ──────────────────────────────────────────────────────────────────────────
   * 3.7) Modals
   *  - _openEssayDialog: centered modal with assignment info
   *  - _showSubmitConfirmation: confirmation dialog before submit
   *  - _openQuillEditorDialogFor: draft editor and Save Draft flow
   * ────────────────────────────────────────────────────────────────────────── */

  /// Show a read-only details dialog for a given assignment with actions:
  ///   - Start/Continue session (posts system message to chat)
  ///   - Submit (requires saved draft, confirms, then snackbar)
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
              maxWidth: maxW,              // Cap width for readability
              maxHeight: mq.height * .85,  // Allow scrolling for tall content
            ),
            child: _EssayModalContent(
              title: essay.name,
              due: essay.dueDate.toString(),
              description: essay.description,

              // Start/Continue session → posts a system message to the chat
              onStart: () {
                Navigator.of(ctx).pop();
                _startSessionFor(essay);

                setState(() {
                  _messages.add(
                    types.SystemMessage(
                      id: const Uuid().v4(),
                      text: 'Starting session for "${essay.name}".',
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                });

                // If you need to save an existing session, do it here, then continue.

                // Build the key for this essay and get/create the session
                final String essayKey =
                    (essay.id != null) ? essay.id.toString() : 'general_${essay.name.hashCode}';

                _currentSession = _sessions[essayKey] ?? EssaySession(essay: essay);
                _sessions[essayKey] = _currentSession!;

                // Replay prior chat safely (null-safe + no duplicate instructions)
                final prior = _currentSession!.chatLog ?? [];
                if (prior.isNotEmpty) {
                  setState(() {
                    for (final turn in prior) {
                      if (turn.isUser) {
                        _messages.add(
                          types.TextMessage(
                            author: _me,
                            id: const Uuid().v4(),
                            text: turn.content,
                            createdAt: DateTime.now().millisecondsSinceEpoch,
                          ),
                        );
                      } else {
                        _messages.add(
                          types.SystemMessage(
                            id: const Uuid().v4(),
                            text: turn.content,
                            createdAt: DateTime.now().millisecondsSinceEpoch,
                          ),
                        );
                      }
                    }
                  });
                  _scrollToBottom();
                }
              },
              // Submit → asks for confirmation first, then posts a success msg
              onSubmit: () async {
                final essayId =
                    essay.id != null ? essay.id.toString() : 'general_draft';

                // Require a saved draft
                if (_currentSession?.draftDeltaOps == null) {
                  final goEdit = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('No draft found'),
                          content: const Text(
                              'You need to save a draft before submitting. Open the editor now?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                child: const Text('Open editor')),
                          ],
                        ),
                      ) ??
                      false;

                  if (goEdit) {
                    Navigator.of(context).pop(); // close the essay modal first
                    _openQuillEditorDialogFor(essay); // open editor for that essay
                  }
                  return;
                }

                // If you want, also sync the draft once more before final submit:
                // await _saveDraftToBackend(essayId, _drafts[essayId]!.deltaJson);

                // Confirm submission
                final confirmed = await _showSubmitConfirmation(context);
                if (!confirmed) return;

                Navigator.of(context).pop(); // close the essay modal

                // TODO: real submission using _drafts[essayId]!.deltaJson
                // await _submitEssay(essayId, _drafts[essayId]!.deltaJson);

                // Notify user (decoupled from chat—snackbar is fine)
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

  /// Small confirmation dialog for Submit.
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

  /// Open the Quill editor dialog for a given essay (or "general draft" if null).
  /// Saves the draft (Quill delta JSON) locally in `_drafts` and via stubbed backend.
    void _openQuillEditorDialogFor(Assignment? essay) async {
      if (!_sessionActive) return;

      // Load current session draft
      if (_currentSession!.draftDeltaOps != null) {
        _quillDraftController.document =
            quill.Document.fromJson(_currentSession!.draftDeltaOps!);
      } else {
        _quillDraftController.document = quill.Document();
      }
    // Show the editor dialog
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
              final double w = mq.width.clamp(480, 1100);
              final double h = mq.height.clamp(420, 900);

              return SizedBox(
                width: w * 0.85,
                height: h * 0.85,
                child: Column(
                  children: [
                    // ----- Header -----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_outlined, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Editor • ${essay?.name ?? 'General Draft'}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // ----- Toolbar (simple) -----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: quill.QuillSimpleToolbar(
                        controller: _quillDraftController,
                        config: const quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showDividers: true,
                          showClipboardPaste: true,
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // ----- Editor -----
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: quill.QuillEditor(
                          focusNode: _draftFocus,
                          scrollController: _quillDraftScrollController,
                          controller: _quillDraftController,
                          config: const quill.QuillEditorConfig(
                            placeholder: 'Write your essay here…',
                            padding: EdgeInsets.all(8),
                            // No embedBuilders yet; keep simple while stabilizing
                          ),
                        ),
                      ),
                    ),

                    // ----- Footer (Save / Cancel) -----
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
                              final deltaJson = _quillDraftController.document
                                  .toDelta()
                                  .toJson();

                              setState(() {
                                _currentSession!.draftDeltaOps = deltaJson;           
                              });

                              await _saveCurrentSessionToPrefs();

                              if (mounted) Navigator.of(ctx).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Draft saved')),
                                );
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
      },
    );
  }

  /// Open the Quill notes editor dialog for a given essay (or "general notes" if null).
  void _openNotesEditorDialogFor(Assignment? essay) async {
    if (!_sessionActive) return;

      if (_currentSession!.notesDeltaOps != null) {
        _quillNotesController.document =
            quill.Document.fromJson(_currentSession!.notesDeltaOps!);
      } else {
        _quillNotesController.document = quill.Document();
      }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx).size;
        final double w = mq.width.clamp(480, 1100);
        final double h = mq.height.clamp(420, 900);

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: w * 0.85,
            height: h * 0.85,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Notes • ${essay?.name ?? 'Notes'}',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Toolbar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: quill.QuillSimpleToolbar(
                    controller: _quillNotesController,
                    config: const quill.QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                      showDividers: true,
                      showClipboardPaste: true,
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Editor
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: quill.QuillEditor(
                      focusNode: _notesFocus,
                      scrollController: _quillNotesScrollController,
                      controller: _quillNotesController,
                      config: const quill.QuillEditorConfig(
                        placeholder: 'Your private notes (not submitted)…',
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save notes'),
                        onPressed: () async {
                          final deltaJson =
                              _quillNotesController.document.toDelta().toJson();
                          setState(() {
                            _currentSession!.notesDeltaOps = deltaJson;
                          });

                          await _saveCurrentSessionToPrefs();

                          if (mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notes saved')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // Convenience: send from input field
  void _sendFromField() {
    final txt = _inputCtrl.text;
    _handleSendPressed(types.PartialText(text: txt));
  }
}


/* ────────────────────────────────────────────────────────────────────────────
 * 4) Pure helpers (top-level)
 *  - NOTE: These intentionally remain top-level so they can be reused across
 *          files later without reaching into a specific State class.
 * ──────────────────────────────────────────────────────────────────────────── */

/// Get essay assignments from LMS.
/// If `courseID` is null or 0 => include all courses.
Future<List<Assignment>> getAllEssays(int? courseID) async {
  List<Assignment> result = [];
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (courseID == 0 || courseID == null || c.id == courseID) {
      result.addAll(c.essays ?? []);
    }
  }
  return result;
}

/// Get a single essay by its ID, with optional course filter.
/// If `courseID` is null or 0 => search all courses.
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

/// Strip HTML tags (useful if LMS descriptions are rich-text).
String removeHtmlTags(String htmlText) {
  final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
  return htmlText.replaceAll(regex, '');
}

// Check if user has API key for selected LLM
bool _hasKeyFor(LlmType llm) {
  return LocalStorageService.userHasLlmKey(llm);
}


/* ────────────────────────────────────────────────────────────────────────────
 * 5) Small UI helpers (stateless widgets)
 *  - _EssayModalContent: the centered dialog content for an assignment
 *  - _LabeledRow: neat label/value row used in the dialog body
 * ──────────────────────────────────────────────────────────────────────────── */

/// Essay details modal content (title, due, description, actions).
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
                  style: const TextStyle(height: 1.4),
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

/// Small labeled row used in the dialog body for clean label/value display.
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
