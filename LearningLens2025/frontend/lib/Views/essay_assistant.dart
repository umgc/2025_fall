// ─────────────────────────────────────────────────────────────────────────────
// Essay Assistant Screen
// Organized for clarity without changing behavior or identifiers.
// Sections:
//   1) Imports
//   2) Top-level types/utilities (enum, draft holder, helpers)
//   3) Pure helpers (top-level functions)
//   4) EssayAssistant widget + State
//      4.1) State fields
//      4.2) Lifecycle (init/dispose)
//      4.3) Chat handling (send/scroll)
//      4.4) LMS essay loading (left sidebar)
//      4.5) Quill editor state + draft persistence stubs
//      4.6) Build method (layout: Left | Center | Right)
//      4.7) Modals (Essay details, Submit confirm, Quill editor)
//   5) Pure helpers (top-level functions)
//   6) Small UI helpers (stateless widgets)
// ─────────────────────────────────────────────────────────────────

/* ────────────────────────────────────────────────────────────────────────────
 * 1) Imports
 * Keep framework → domain → UI → 3rd-party consistent and grouped.
 * ──────────────────────────────────────────────────────────────────────────── */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Third-party
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart'
    as qh;

// Api
import 'package:learninglens_app/Api/database/ai_logging_singleton.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
// Controller
import 'package:learninglens_app/Controller/custom_appbar.dart';
// beans
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/essay_assistant_session.dart';
import 'package:learninglens_app/beans/participant.dart';
// services
import 'package:learninglens_app/services/LLMContextBuilder.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/prompt_builder_service.dart';
import 'package:learninglens_app/Api/llm/local_llm_service.dart'; // local llm
import 'package:flutter/foundation.dart';

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
enum AiMode { brainstorm, revise, draftOutline, assistant }

enum PreBuiltPrompt {
  GenerateTopicIdeas,
  QuestionsToExplore,
  FindSources,
  CreateOutline,
  GrammarToneSpellCheck,
  ClarityandConciseness,
  CitationsandFormatting,
  Assistant,
}

enum EssayStatus { notStarted, inProgress, submitted }

/* ────────────────────────────────────────────────────────────────────────────
 * 3) Pure helpers (top-level)
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

/// Get the course for a given essay.
Future<Course?> getCourseForEssay(Assignment essay) async {
  for (Course c in LmsFactory.getLmsService().courses ?? []) {
    if (c.id == essay.courseId) {
      return c;
    }
  }
  return null;
}

Future<Participant?> getStudentForEssay(int courseId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final lms = LmsFactory.getLmsService();
  final uid = prefs.getString('userId');
  final int? uidInt = uid != null ? int.tryParse(uid) : null;

  final participants = await lms.getCourseParticipants(courseId.toString());
  for (final p in participants) {
    if (p.id == uidInt) return p;
  }
  return null;
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

/// Convert markdown text to HTML
String _markdownToHTML(String markdownText) {
  return md.markdownToHtml(markdownText);
}

String _markdownToPlain(String mdText) {
  // lightweight, good enough for fallback
  var s = mdText;

  // Replace fenced code blocks
  s = s.replaceAllMapped(RegExp(r'```[\s\S]*?```'), (m) {
    final inner = m
        .group(0)!
        .replaceFirst(RegExp(r'^```[^\n]*\n'), '')
        .replaceAll('```', '');
    return inner;
  });

  // Inline code
  s = s.replaceAll(RegExp(r'`([^`]*)`'), r'\1');

  // Images
  s = s.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');

  // Links → "text (url)"
  s = s.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (m) => '${m[1]} (${m[2]})');

  // Remove emphasis, quotes, tildes
  s = s.replaceAll(RegExp(r'(^|\s)[*_]{1,3}|\~\~|^>+\s*', multiLine: true), '');

  // Bullet points
  s = s.replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ');

  // Collapse triple newlines
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  s = s.replaceAll(RegExp(r'\r\n?'), '\n'); // unify line endings
  s = s.replaceAll(
      RegExp(r'\n{2,}'), '\n\n'); // one blank line between paragraphs

  return s.trim();
}

/// Copy rich markdown as HTML to clipboard
Future<void> _copyMarkdown(BuildContext context, String mdText) async {
  final htmlText = _markdownToHTML(mdText);
  final plain = _markdownToPlain(mdText);

  final item = DataWriterItem();
  item.add(Formats.htmlText(htmlText));
  item.add(Formats.plainText(plain));
  await SystemClipboard.instance?.write([item]);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied rich text to clipboard.')),
    );
  }
}

/* ────────────────────────────────────────────────────────────────────────────
 * 4) EssayAssistant Widget
 * ──────────────────────────────────────────────────────────────────────────── */
class EssayAssistant extends StatefulWidget {
  const EssayAssistant({super.key});

  @override
  State<EssayAssistant> createState() => _EssayAssistantState();
}

class _EssayAssistantState extends State<EssayAssistant> {
  /* ──────────────────────────────────────────────────────────────────────────
   * 4.1) State fields
   *  - Session
   *  - Chat
   *  - Sidebars (left: essays; right: AI controls)
   *  - Quill editor
   *  - Draft storage (per essay)
   * ────────────────────────────────────────────────────────────────────────── */

  // ------------- Session state  -------------
  SharedPreferences? _prefs; // for local persistence
  EssaySession? _currentSession; // currently active session (if any)
  final Map<String, EssaySession> _sessions =
      {}; // key: essayId (String), value: EssaySession
  // ignore: unused_field
  bool _isBusy = false; // loading/saving state

  // --- Streaming control ---
  bool _isStreaming = false;
  StreamSubscription<String>? _streamSub;
  int? _activeAssistantIndex; // which ChatTurn is streaming
  final StringBuffer _streamBuffer = StringBuffer(); // live text
  String? _activeAssistantMsgId; // for tracking streaming assistant message

  Future<Course?> get _currentCourse =>
      getCourseForEssay(_currentSession!.essay); // course of current essay
  Future<Participant?> get _currentStudent => getStudentForEssay(
      _currentSession!.essay.courseId); // student using the assistant
  bool get _sessionActive =>
      _currentSession != null; // Check if a session is active
  String get essayID => _currentSession?.id ?? ''; // Current essay/session ID

  bool _localLlmAvail = !kIsWeb;

  /// Start or continue a session for the given essay.
  Future<void> _startSessionFor(Assignment essay, {bool replay = true}) async {
    // Get EssayKey
    final essayKey = _essayKeyOf(essay);
    _statusCache[essayKey] = EssayStatus.inProgress;

    // Load existing or create new session
    final session = _sessions[essayKey] ??
        EssaySession(essay: essay, id: essayKey, chatLog: []);

    // Update state
    setState(() {
      _currentSession = session;
      _sessions[essayKey] = session;
      // Clear chat messages for new session load
      _messages.clear();
      _inputCtrl.clear();
    });

    // Replay chat log if requested
    if (replay && _currentSession!.chatLog.isNotEmpty) {
      _postIntroMsg();
      setState(() {
        for (final turn in _currentSession!.chatLog) {
          if (turn.isUser) {
            _messages.add(
              types.TextMessage(
                id: const Uuid().v4(),
                author: _me,
                text: turn.content ?? '',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          } else {
            _messages.add(
              types.SystemMessage(
                id: const Uuid().v4(),
                text: turn.content ?? '',
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
          }
        }
      });
    } else {
      // Fresh system line so the chat isn’t empty
      _postIntroMsg();
      _appendSystemMessage('Starting session for "${essay.name}".');
    }

    //Persist right away so this session is saved separately
    await _saveCurrentSessionToPrefs();
    _scrollToBottom();
  }

  /// Show a snackbar if no session is active.
  void _guardNoSession() {
    if (!_sessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start or continue a session first.')),
      );
    }
  }

  /// Cancel any ongoing streaming LLM response.
  void _cancelStreaming() async {
    if (!_isStreaming) return;

    // local LLM has its own cancel
    if (_selectedLLM == LlmType.LOCAL) {
      LocalLLMService().cancel();
      return;
    }

    _isStreaming = false;
    await _streamSub?.cancel();
    _streamSub = null;

    // Whatever generated so far becomes the final message
    final partial = _streamBuffer.toString();
    final idx = _activeAssistantIndex;
    if (idx != null) {
      _finishAssistantStream(idx, partial.trim());
    }
    setState(() {}); // update UI (Stop→Send)
  }

  Future<void> _cancelActiveStreamsAndRequestsSafely() async {
    try {
      if (_isStreaming) {
        await Future<void>.microtask(_cancelStreaming);
      }
    } catch (_) {
      // swallow
    }
  }

// Select the active essay in the sidebar if any
  void _selectActiveEssayIfAny() {
    if (_currentSession == null) {
      setState(() => _selectedSidebarIndex = null);
      return;
    }
    final activeId = _currentSession!.essay.id;
    final idx = _essays.indexWhere((e) => e.id == activeId);
    setState(() => _selectedSidebarIndex = idx >= 0 ? idx : null);
  }

  // ---------------- Chat state ----------------
  final List<types.Message> _messages = []; // chat messages for Chat UI
  late final types.User _me; // current user identity

  final _inputCtrl = TextEditingController(); // input field controller
  final _scrollCtrl = ScrollController(); // chat scroll controller

  // ---------------- Left sidebar (essays) state ----------------
  int? _selectedSidebarIndex; // selected essay index in the left list
  List<Assignment> _essays = []; // loaded from LMS (all courses or filtered)
  final Map<String, EssayStatus> _statusCache =
      {}; // key = essayKey , value = EssayStatus

  // ---------------- Right sidebar (AI controls) state ----------------
  AiMode _mode = AiMode.brainstorm; // current AI mode
  PreBuiltPrompt? _selectedPrompt; // prompt within a mode (dropdown)
  late LlmType _selectedLLM; // your enum (with .displayName)
  double _temperature = 0.7; // 0.0–2.0 typical; start reasonable

  // Pre-built prompts available for each mode
  final Map<AiMode, Map<String, PreBuiltPrompt>> _promptsByMode = {
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
      '-': PreBuiltPrompt.Assistant,
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
    AiMode.assistant: 'More open-ended assistance with your essay.',
  };

  // General tooltip for the "Helpers" label
  final String _helpersTooltip =
      'Pre-built prompts to guide the AI in assisting you. Select one to get started.';

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
    );

    // Seed a welcome system message (renders as full-width text, no bubble)
    _postIntroMsg();

    // Quill controller with basic config (external rich paste enabled)
    _quillDraftController = quill.QuillController.basic();
    // Notes editor
    _quillNotesController = quill.QuillController.basic();

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
    _streamSub?.cancel();
    _streamSub = null;
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
  void _postIntroMsg() {
    _appendSystemMessage('''
## Welcome to the Essay Assistant!\n
This space is designed to help you plan, write, and refine your essay from start to finish. You can interact with the assistant through different Modes, use Helper Prompts for specific tasks, jot down quick thoughts in Notes, and compose or edit your full essay in the Draft Editor.

## Modes:\n
Each mode changes how the assistant responds:\n
• **Assistant** – a general-purpose mode for open discussion, quick questions, or feedback that doesn’t fit a specific phase of writing. *Good for models with smaller context windows.*\n
• **Brainstorm** – generate ideas and clarify your topic.\n
• **Outline** – build structure with main points and supporting details.\n
• **Revise** – improve clarity, grammar, and flow in your draft.\n

**Helper Prompts:**\n
These are pre-built tools that perform focused tasks — such as checking grammar, suggesting sources, or creating outlines. You can use them anytime to get targeted help without switching modes.

**Notes Section:**\n
Use this to capture quick ideas, reminders, or references as you work. Notes stay linked to your essay session so you won’t lose your thoughts between sessions.

**Draft Editor:**\n
This is your main writing space. You can write freely, review feedback from the assistant, and make revisions directly here. When you’re ready, you can export or submit your final essay.\n

**Select an essay from the left sidebar to get started!**\n

Tip: The assistant adapts to your mode and notes, so the more context you provide, the better it can help.\n

⚠️ **Important Notice** ⚠️\n

**The Essay Assistant provides AI-generated feedback and content suggestions. While it strives for accuracy and quality, it is your responsibility to verify all information, citations, and factual claims before submission. Always review and edit the final essay to ensure it meets your academic standards and requirements.**
      ''');
  }

// Handle user pressing "Send" in chat input
  Future<void> _handleSendPressed(types.PartialText partial) async {
    if (partial.text.trim().isEmpty) return;
    _appendUserMessage(partial.text.trim());
    _inputCtrl.clear();

    // Let getLLMResponse handle ALL assistant/error UI.
    try {
      await getLLMResponse(
        partial.text.trim(),
        _selectedLLM,
        _temperature,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('There was a problem generating a reply: $e')),
      );
    }
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

  // Start streaming assistant response in chat log
  String _beginAssistantUiMessage() {
    final id = const Uuid().v4();
    setState(() {
      _messages.add(
        types.SystemMessage(
          id: id,
          text: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
    _scrollToBottom();
    return id;
  }

  // Append chunk to streaming assistant UI message
  void _appendAssistantUiChunk(String id, String chunk) {
    final index = _messages.indexWhere((msg) => msg.id == id);
    if (index == -1) return; // not found

    final old = _messages[index];
    final prev = (old is types.SystemMessage)
        ? old.text
        : (old is types.CustomMessage
            ? (old.metadata?['text'] as String? ?? '')
            : '');

    setState(() {
      _messages[index] = types.SystemMessage(
        id: id,
        text: prev + chunk,
        createdAt: old.createdAt,
      );
    });
    _scrollToBottom();
  }

  void _finalizeAssistantUi(String id, String fullText) {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i != -1) {
      final old = _messages[i];
      setState(() {
        _messages[i] = types.SystemMessage(
          id: id,
          text: fullText,
          createdAt: old.createdAt,
        );
      });
    }
    _activeAssistantMsgId = null;
  }

  /// Core method to get LLM response based on current session and context
  Future<String?> getLLMResponse(
      String userPrompt, LlmType llm, double temperature) async {
    if (!_sessionActive) {
      _appendSystemMessage('No active session.');
      return null;
    }

    // Description → plain text
    final essayDescription = removeHtmlTags(
      _currentSession!.essay.description,
    ).trim();

    // Draft / Notes → plain text
    String? submissionText;
    if (_currentSession!.draftDeltaOps != null) {
      try {
        submissionText =
            quill.Document.fromJson(_currentSession!.draftDeltaOps!)
                .toPlainText()
                .trim();
        if (submissionText.isEmpty) submissionText = null;
      } catch (_) {}
    }

    String? notesText;
    if (_currentSession!.notesDeltaOps != null) {
      try {
        notesText = quill.Document.fromJson(_currentSession!.notesDeltaOps!)
            .toPlainText()
            .trim();
        if (notesText.isEmpty) notesText = null;
      } catch (_) {}
    }

    final permContext = essayAssistPromptBuilder(
      _mode,
      submissionText,
      notesText,
      essayDescription,
    );

    final chatLog = _currentSession!.chatLog;

    // ----- Pick model -----
    LLM? aiModel;
    switch (_selectedLLM) {
      case LlmType.CHATGPT:
        final key = LocalStorageService.getOpenAIKey();
        if (key.isEmpty) return _appendError('OpenAI key missing');
        aiModel = OpenAiLLM(key);

      case LlmType.GROK:
        final key = LocalStorageService.getGrokKey();
        if (key.isEmpty) return _appendError('Grok key missing');
        aiModel = GrokLLM(key);

      case LlmType.PERPLEXITY:
        final key = LocalStorageService.getPerplexityKey();
        if (key.isEmpty) return _appendError('Perplexity key missing');
        aiModel = PerplexityLLM(key);

      case LlmType.DEEPSEEK:
        final key = LocalStorageService.getDeepseekKey();
        if (key.isEmpty) return _appendError('Deepseek key missing');
        aiModel = DeepseekLLM(key);
      case LlmType.LOCAL:
        aiModel = LocalLLMService();
    }
    final fullContext = generateContext(
      permTokens: permContext,
      chatHistory: chatLog,
      userPrompt: userPrompt,
      llmContextSize: aiModel.contextSize,
      maxOutputTokens: aiModel.maxOutputTokens,
    );
    //print('Full context for LLM:\n$fullContext');

    // Log the user's turn immediately
    _currentSession!.chatLog.add(ChatTurn(role: 'user', content: userPrompt));

    final buffer = _streamBuffer..clear();
    try {
      // Create the assistant placeholders
      final int assistantIndex = _beginAssistantStream();
      _activeAssistantIndex = assistantIndex;

      // Start streaming
      _isStreaming = true;
      setState(() {}); // to flip the Send→Stop button

      final stream = aiModel.chatStream(
        context: fullContext,
        temperature: temperature,
      );

      _streamSub = stream.listen(
        (token) {
          buffer.write(token);
          if (_activeAssistantMsgId == null) {
            _activeAssistantMsgId = _beginAssistantUiMessage();
            _appendAssistantUiChunk(_activeAssistantMsgId!, token);
          }
          _appendAssistantStream(
              assistantIndex, token); // updates log + UI bubble
        },
        onError: (e, st) async {
          _isStreaming = false;
          await _streamSub?.cancel();
          _streamSub = null;

          final err = '[Error: $e]';
          _finishAssistantStream(assistantIndex, err);
          _appendError(e.toString());
          await _saveCurrentSessionToPrefs();
          setState(() {}); // button state
        },
        onDone: () async {
          _isStreaming = false;
          _streamSub = null;

          final fullText = buffer.toString().trim();
          _finishAssistantStream(assistantIndex, fullText);

          await _logAiInteraction(
            userMsg: userPrompt,
            systemResponse: fullText,
          );
          await _saveCurrentSessionToPrefs();
          setState(() {}); // button state
        },
        cancelOnError: true,
      );

      // NOTE: don’t await here; subscription will call onDone/onError.
      return null;
    } catch (e) {
      // ---- Fallback: non-streaming call (not cancellable) ----
      try {
        final fallback = await aiModel.chat(
          context: fullContext,
          temperature: temperature,
        );
        final fullText = fallback.trim();

        // Make sure placeholders exist if we didn’t start them yet
        final idx = _activeAssistantIndex ?? _beginAssistantStream();
        _activeAssistantMsgId ??= _beginAssistantUiMessage();
        _finishAssistantStream(idx, fullText);

        await _logAiInteraction(userMsg: userPrompt, systemResponse: fullText);
        await _saveCurrentSessionToPrefs();
        return fullText.isEmpty ? null : fullText;
      } catch (inner) {
        _appendError(inner.toString());
        await _saveCurrentSessionToPrefs();
        return null;
      }
    }
  }

  // Append chunk to streaming assistant message in chat log
  Future<void> _logAiInteraction({
    required String userMsg,
    required String systemResponse,
  }) async {
    try {
      final Course? course = await _currentCourse;
      final Assignment essay = _currentSession!.essay;
      final Participant? student = await _currentStudent;

      final microReflectionChoices = [
        "Stop and think…",
        "Ask yourself…",
        "Take a moment to reflect…"
      ];

      if (course == null || student == null) return;

      RegExpMatch? match;
      for (String c in microReflectionChoices) {
        // 🔍 Create regex to find the "**Micro-Reflection:**" marker

        final RegExp regex = RegExp(
          r'\*\*'
          '$c'
          r'\*\*', // matches the literal bold markdown
          caseSensitive: false, // makes it case-insensitive
        );

        // Find the marker in the system response
        match = regex.firstMatch(systemResponse);
        if (match != null) {
          break;
        }
      }

      String mainResponse = systemResponse;
      String? microReflection;

      if (match != null) {
        // Split the text into before and after the marker
        microReflection = systemResponse.substring(match.start).trim();
        mainResponse = systemResponse.substring(0, match.start).trim();
      }

      // Log both (or just the full response if you prefer)
      final log = AiLog(
        course,
        essay,
        student,
        userMsg,
        mainResponse,
        _selectedLLM,
        microReflection ?? '',
      );
      await AILoggingSingleton().addLog(log);
      print('AI interaction logged successfully.');
    } catch (err, st) {
      print('AI logging failed: $err\n$st');
    }
  }

  ///Methods to push Draft to LMS
  Future<void> _pushCurrentDraftToMoodle(Assignment essay) async {
    if (_currentSession?.draftDeltaOps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No draft to upload.')),
      );
      return;
    }

    final lms = LmsFactory.getLmsService();
    final ops = _currentSession!.draftDeltaOps!;
    final html = deltaToHtml(ops);

    // If you handle images, upload them here (optional)
    int? draftItemId;
    // draftItemId = await lms.uploadFileToDraft(file: myFile, contextId: contextId);

    // Save the text itself as draft (format=1 for HTML)
    final visible = RegExp(r'[^\s\u00A0]')
        .hasMatch(html.replaceAll(RegExp(r'<[^>]+>'), ''));
    if (!visible) {
      // Show a message or send a minimal placeholder
      print('Warning: Draft appears to be empty after stripping HTML tags.');
    }
    await lms.saveAssignmentSubmissionOnlineText(
      assignId: essay.id,
      text: html,
      format: 1,
      draftItemId: draftItemId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Draft saved to Moodle for "${essay.name}"')),
    );
  }

  Future<void> _submitNow(Assignment essay) async {
    if (_currentSession?.draftDeltaOps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No draft to submit. Open editor and save first.')),
      );
      return;
    }

    final lms = LmsFactory.getLmsService();
    final ops = _currentSession!.draftDeltaOps!;
    final html = deltaToHtml(ops).trim();

    final hasVisibleText = RegExp(r'[^\s\u00A0]').hasMatch(
      html.replaceAll(RegExp(r'<[^>]+>'), ''),
    );
    if (!hasVisibleText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Your draft is empty. Type something and Save draft first.')),
      );
      return;
    }

    try {
      // --- Preferred: Online-text path
      await lms.saveAssignmentSubmissionOnlineText(
        assignId: essay.id,
        text: html,
        format: 1, // HTML
        // draftItemId: (optional) pass if you also uploaded images for editor
      );

      await lms.submitAssignmentForGrading(assignId: essay.id);

      final key = _essayKeyOf(essay);
      final s = _sessions[key];
      if (s != null) {
        _statusCache[key] = EssayStatus.submitted;
        await _saveCurrentSessionToPrefs();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submitted “${essay.name}” for grading.')),
        );
      }
    } catch (e) {
      // If the assignment doesn’t support online text, fall back to Files:
      final msg = e.toString();
      final notSupported = msg.contains('submissionpluginnotsupported') ||
          msg.contains('onlinetext');

      if (!notSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submit failed: $msg')),
          );
        }
        return;
      }

      // --- Fallback: Files-only (upload .html and save)
      try {
        final ctxId =
            await lms.getContextId(essay.id, essay.courseId.toString()) ?? 0;

        // write HTML to a temp file
        final tmp =
            File('${Directory.systemTemp.path}/submission_${essay.id}.html');
        await tmp.writeAsString(html);

        final itemId = await lms.uploadFileToDraft(file: tmp, contextId: ctxId);
        await lms.saveAssignmentSubmissionFiles(
            assignId: essay.id, draftItemId: itemId);

        await lms.submitAssignmentForGrading(assignId: essay.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submitted “${essay.name}” as file.')),
        );
      } catch (f) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submit failed (files path): $f')),
          );
        }
      }
    }
  }

  /// ----- Helpers for streaming UI / model log -----
  /// Adds an empty assistant message to the log so we can mutate it as tokens arrive.
  /// Returns the index of that message in _currentSession!.chatLog.

  int _beginAssistantStream() {
    final turn = const ChatTurn(role: 'assistant', content: '');
    _currentSession!.chatLog.add(turn);
    _emitUiUpdate();
    return _currentSession!.chatLog.length - 1;
  }

  /// Append chunk: replace ChatTurn immutably and update UI bubble
  void _appendAssistantStream(int assistantIndex, String chunk) {
    final turn = _currentSession!.chatLog[assistantIndex];
    final updated = turn.copyWith(content: (turn.content ?? '') + chunk);
    _currentSession!.chatLog[assistantIndex] = updated;
    _emitUiUpdate();

    if (_activeAssistantMsgId != null) {
      _appendAssistantUiChunk(_activeAssistantMsgId!, chunk);
    }
  }

  /// Finalize: replace ChatTurn immutably and finalize UI bubble
  void _finishAssistantStream(int assistantIndex, String finalText) {
    final turn = _currentSession!.chatLog[assistantIndex];
    _currentSession!.chatLog[assistantIndex] =
        turn.copyWith(content: finalText);
    _emitUiUpdate();

    if (_activeAssistantMsgId != null) {
      _finalizeAssistantUi(_activeAssistantMsgId!, finalText);
    }
  }

  void _emitUiUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  /// Append error message to chat as System line
  String? _appendError(String msg) {
    _appendSystemMessage('Error: $msg');
    return null;
  }

  /// Scroll chat to bottom
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
    if (!mounted) return;
    try {
      final all = await getAllEssays(courseId);
      final filtered = all.where((a) => !_isOverdue(a)).toList()
        ..sort((a, b) {
          final ad = _effectiveDue(a);
          final bd = _effectiveDue(b);
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });

      if (mounted) setState(() => _essays = filtered);
    } catch (_) {
      // optional: you can log or ignore silently
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
        cutoffDate: (e['cutoffDate'] is String &&
                (e['cutoffDate'] as String).isNotEmpty)
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
          .map((x) => ChatTurn(
              role: x['role'] ?? 'assistant', content: x['content'] ?? ''))
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

  String deltaToHtml(List<dynamic> ops) {
    final converter = QuillDeltaToHtmlConverter(
      ops.cast<Map<String, dynamic>>(),
      ConverterOptions(),
    );
    return converter.convert();
  }

  /// Helper to get essay key for sessions map
  String _essayKeyOf(Assignment e) => e.id.toString();

  /// Check if we have a saved session for this essay
  bool _hasSessionFor(Assignment e) => _sessions.containsKey(_essayKeyOf(e));

  DateTime? _effectiveDue(Assignment a) {
    final d = a.cutoffDate ?? a.dueDate;
    return d;
  }

  DateTime _normalizeToComparableLocal(DateTime d) {
    final local = d.toLocal();
    final isMidnight =
        local.hour == 0 && local.minute == 0 && local.second == 0;
    if (isMidnight) {
      return DateTime(local.year, local.month, local.day, 23, 59, 59);
    }
    return local;
  }

  bool _isOverdue(Assignment a) {
    final d = _effectiveDue(a);
    if (d == null) return false; // No date → show it
    final deadline = _normalizeToComparableLocal(d);
    return DateTime.now().isAfter(deadline);
  }

  EssayStatus _deriveStatusLocal(EssaySession? s) {
    if (s == null) return EssayStatus.notStarted;
    final hasDraft = s.draftDeltaOps != null &&
        (() {
          try {
            return quill.Document.fromJson(s.draftDeltaOps!)
                .toPlainText()
                .trim()
                .isNotEmpty;
          } catch (_) {
            return false;
          }
        })();
    if (hasDraft || (s.chatLog.isNotEmpty)) return EssayStatus.inProgress;
    return EssayStatus.notStarted;
  }

  EssayStatus _statusOf(Assignment a) {
    final key = _essayKeyOf(a);
    final cached = _statusCache[key];
    if (cached != null) return cached;
    final s = _sessions[key];
    final derived = _deriveStatusLocal(s);
    _statusCache[key] = derived;
    return derived;
  }

  String _statusTextFor(Assignment a) {
    switch (_statusOf(a)) {
      case EssayStatus.notStarted:
        return 'Not started';
      case EssayStatus.inProgress:
        return 'In progress';
      case EssayStatus.submitted:
        return 'Submitted';
    }
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
                child: Column(children: [
                  // Sidebar header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Essay Assignments',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        // (removed reload button)
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
                            : assignment.dueDate!
                                .toLocal()
                                .toIso8601String()
                                .split('T')
                                .first;
                        final status = _statusOf(assignment);

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
                          trailing: _statusChip(status),
                          onTap: () async {
                            setState(() => _selectedSidebarIndex = i);
                            final started =
                                await _openEssayDialog(context, assignment);
                            if (!started && mounted) {
                              _selectActiveEssayIfAny();
                            }
                          },
                        );
                      },
                    ),
                  )
                ])),
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
                                (m is types.CustomMessage &&
                                    (m.metadata?['kind'] == 'bot_text'))) {
                              final text = (m is types.SystemMessage)
                                  ? m.text
                                  : ((m as types.CustomMessage)
                                          .metadata?['text'] as String? ??
                                      '');

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                child: _AssistantMessageCard(
                                  text:
                                      text, // raw markdown that you already computed above
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: MarkdownBody(
                                      data: text,
                                      selectable:
                                          true, // lets users highlight/copy text
                                      styleSheet: MarkdownStyleSheet.fromTheme(
                                              Theme.of(context))
                                          .copyWith(
                                              p: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                  height: 1.46),
                                              strong: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              em: const TextStyle(
                                                  fontStyle: FontStyle.italic),
                                              a: const TextStyle(
                                                color: Colors.blueAccent,
                                                decoration:
                                                    TextDecoration.underline,
                                              )),
                                    ),
                                  ),
                                ),
                              );
                            }

                            // (2) User messages (right-aligned bubble)
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
                                          color: Colors.black.withOpacity(0.08),
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
                                    child: Focus(
                                      onKeyEvent: (node, event) {
                                        // Only intercept physical keyboard presses
                                        if (event is KeyDownEvent &&
                                            event.logicalKey ==
                                                LogicalKeyboardKey.enter &&
                                            // Allow Shift+Enter for newline
                                            !HardwareKeyboard
                                                .instance.isShiftPressed &&
                                            // Avoid sending if Ctrl/Cmd/Alt are pressed
                                            !HardwareKeyboard
                                                .instance.isControlPressed &&
                                            !HardwareKeyboard
                                                .instance.isMetaPressed &&
                                            !HardwareKeyboard
                                                .instance.isAltPressed &&
                                            // Don’t trigger while streaming
                                            !_isStreaming) {
                                          _sendFromField(); // calls your existing handler
                                          return KeyEventResult
                                              .handled; // prevent newline insertion
                                        }
                                        return KeyEventResult
                                            .ignored; // let TextField handle others
                                      },
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
                              ),
                              const SizedBox(width: 8),

                              // Send OR Stop button (depending on streaming state)
                              if (_isStreaming)
                                ElevatedButton.icon(
                                  onPressed: _cancelStreaming,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: const StadiumBorder(),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _sessionActive
                                      ? _sendFromField
                                      : _guardNoSession,
                                  style: ElevatedButton.styleFrom(
                                      shape: const StadiumBorder()),
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
                            value: AiMode.assistant, child: Text('Assistant')),
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
                          _selectedPrompt =
                              null; // Reset prompt when mode changes
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // --- Helpers: label + tooltip
                    Row(
                      children: [
                        Text('Helper Prompts',
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
                    Tooltip(
                      message: _mode == AiMode.assistant
                          ? 'Helper prompts are not used in Assistant mode.'
                          : 'Select a prebuilt helper prompt.',
                      child: IgnorePointer(
                        ignoring: _mode == AiMode.assistant,
                        child: Opacity(
                          opacity: _mode == AiMode.assistant ? 0.5 : 1.0,
                          child: DropdownButtonFormField<PreBuiltPrompt>(
                            value: _selectedPrompt,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: _promptsByMode[_mode]!
                                .entries
                                .map(
                                    (entry) => DropdownMenuItem<PreBuiltPrompt>(
                                          value: entry.value,
                                          child: Text(entry.key),
                                        ))
                                .toList(),
                            onChanged: (_mode == AiMode.assistant)
                                ? null
                                : (val) =>
                                    setState(() => _selectedPrompt = val),
                            hint: const Text('Choose a helper prompt'),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // --- Button to submit Pre-built prompt as user message.
                    FilledButton.icon(
                      onPressed: (!_sessionActive ||
                              _mode == AiMode.assistant ||
                              _selectedPrompt == null ||
                              _isStreaming)
                          ? null
                          : () {
                              final submittedPrompt = types.PartialText(
                                text: getPreBuiltPrompt(_selectedPrompt),
                              );
                              _handleSendPressed(submittedPrompt);
                              _scrollToBottom();
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Send Prompt'),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // ───────────────────────── LLM picker ─────────────────────────
                    Row(
                      children: [
                        Text('Model',
                            style: Theme.of(context).textTheme.titleMedium),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
                          if (newValue == LlmType.LOCAL ||
                              _hasKeyFor(newValue)) {
                            setState(() => _selectedLLM = newValue);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'No API key set for ${newValue.displayName}.')),
                            );
                          }
                        },
                        items: LlmType.values.map((llm) {
                          final enabled = (llm == LlmType.LOCAL &&
                                  LocalStorageService.getLocalLLMPath() != "" &&
                                  _localLlmAvail) ||
                              _hasKeyFor(llm);
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
                      max: 2.0, // adjust to your model’s max if needed
                      divisions: 40, // 0.05 steps
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
                              final essay = (_essays.isEmpty ||
                                      _selectedSidebarIndex == null)
                                  ? null
                                  : _essays[_selectedSidebarIndex!];
                              _openQuillEditorDialogFor(essay);
                            }
                          : _guardNoSession,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Open Draft Editor'),
                    ),
                    const SizedBox(height: 8),

                    // --- Open notes editor (Quill)
                    OutlinedButton.icon(
                      onPressed: _sessionActive
                          ? () {
                              final essay = (_essays.isEmpty ||
                                      _selectedSidebarIndex == null)
                                  ? null
                                  : _essays[_selectedSidebarIndex!];
                              _openNotesEditorDialogFor(essay);
                            }
                          : _guardNoSession,
                      icon: const Icon(Icons.sticky_note_2_outlined),
                      label: const Text('Open Notes'),
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

  // status chip widget for essay list items
  Widget _statusChip(EssayStatus s) {
    switch (s) {
      case EssayStatus.notStarted:
        return Chip(
          label: const Text('Not started'),
          visualDensity: VisualDensity.compact,
        );
      case EssayStatus.inProgress:
        return Chip(
          label: const Text('In progress'),
          visualDensity: VisualDensity.compact,
          backgroundColor: Colors.amber.withOpacity(.2),
        );
      case EssayStatus.submitted:
        return Chip(
          label: const Text('Submitted'),
          visualDensity: VisualDensity.compact,
          backgroundColor: Colors.green.withOpacity(.2),
        );
    }
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
  Future<bool> _openEssayDialog(BuildContext context, Assignment essay) {
    final course = LmsFactory.getLmsService().courses?.firstWhere(
        (c) => c.id == essay.courseId,
        orElse: () => Course.empty());

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx).size;
        final maxW = mq.width < 720 ? mq.width - 32 : 640.0;

        final key = _essayKeyOf(essay);
        final hasSession = _hasSessionFor(essay);
        final primaryLabel =
            hasSession ? 'Continue Session' : 'Start New Session';

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: maxW, maxHeight: mq.height * .85),
            child: _EssayModalContent(
              essay: essay,
              course: course,
              statusText: _statusTextFor(essay),
              primaryLabel: primaryLabel,
              hasSession: hasSession,
              onReset: hasSession
                  ? () async {
                      await _confirmClearSessionFor(essay);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop(true); // session restarted
                      }
                    }
                  : null,
              onPrimary: () {
                Navigator.of(ctx).pop(true); // <-- user chose start/continue
                final session = _sessions[key] ??
                    EssaySession(essay: essay, id: key, chatLog: []);
                _sessions[key] = session;
                _startSessionFor(essay);
                _scrollToBottom();
              },
            ),
          ),
        );
      },
    ).then((value) => value ?? false); // barrier dismiss => false
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

  Future<void> _confirmClearSessionFor(Assignment essay) async {
    // 1st confirm
    final ok1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm reset'),
        content: const Text(
            'This will permanently wipe all messages, notes, and drafts for this session. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue')),
        ],
      ),
    );
    if (ok1 != true) return;

    // 2nd confirm (type RESET)
    final controller = TextEditingController();
    final ok2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Type to confirm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type RESET to permanently erase this session.'),
            const SizedBox(height: 12),
            TextField(
                autofocus: true,
                controller: controller,
                decoration: const InputDecoration(hintText: 'RESET')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(
                context, controller.text.trim().toUpperCase() == 'RESET'),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok2 != true) return;

    // Wipe + restart
    await _clearAndRestartSessionFor(essay);
  }

  Future<void> _clearAndRestartSessionFor(Assignment essay) async {
    setState(() => _isBusy = true);
    try {
      await _cancelActiveStreamsAndRequestsSafely();

      final sessionId = _essayKeyOf(essay);

      _sessions.remove(sessionId);
      _statusCache[sessionId] = EssayStatus.notStarted;
      await _saveAllSessionToPrefs();

      _messages.clear();
      _streamBuffer.clear();
      _activeAssistantIndex = null;
      _activeAssistantMsgId = null;

      // reset editors
      _quillDraftController.document = quill.Document();
      _quillNotesController.document = quill.Document();

      _currentSession = null;

      _postIntroMsg();
      await _startSessionFor(essay);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Session cleared. Started a fresh session.')),
        );
      }
    } catch (e, st) {
      debugPrint('Reset failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _richPaste(
      BuildContext editorCtx, quill.QuillController controller) async {
    final sys = SystemClipboard.instance;
    if (sys == null) {
      // super_clipboard not available → let default paste run
      Actions.invoke(
          editorCtx, const PasteTextIntent(SelectionChangedCause.keyboard));
      return;
    }

    final reader = await sys.read();

    String normalizeLineBreaks(String rawHtml) {
      var h = rawHtml;
      final startIdx = h.indexOf('<!--StartFragment-->');
      final endIdx = h.indexOf('<!--EndFragment-->');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        h = h.substring(startIdx + '<!--StartFragment-->'.length, endIdx);
      }
      h = h.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
      h = h.replaceAll(RegExp(r'\n{2,}'), '</p><p>');
      if (!RegExp(r'</?(p|div|ul|ol|h[1-6])\b', caseSensitive: false)
          .hasMatch(h)) {
        h = '<p>$h</p>';
      }
      h = h.replaceAll('\n', '<br/>');
      return h;
    }

    if (reader.canProvide(Formats.htmlText)) {
      var html = await reader.readValue(Formats.htmlText);
      if (html != null && html.trim().isNotEmpty) {
        html = normalizeLineBreaks(html);
        final delta = qh.HtmlToDelta().convert(html);

        final sel = controller.selection;
        final base = sel.baseOffset;
        final extent = sel.extentOffset;
        final deleteLen = (extent - base).abs();

        controller.replaceText(
          base,
          deleteLen,
          '',
          TextSelection.collapsed(offset: base),
        );
        controller.compose(
            delta, controller.selection, quill.ChangeSource.local);
        controller.updateSelection(
          TextSelection.collapsed(offset: base + delta.length),
          quill.ChangeSource.local,
        );
        return;
      }
    }

    // fallback to normal paste (plain text)
    Actions.invoke(
        editorCtx, const PasteTextIntent(SelectionChangedCause.keyboard));
  }

  Widget _richPasteWrapper({
    required quill.QuillController controller,
    required Widget child,
    void Function(BuildContext ctx)? onInnerContext,
  }) {
    late BuildContext editorCtx;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
            const PasteTextIntent(SelectionChangedCause.keyboard),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV):
            const PasteTextIntent(SelectionChangedCause.keyboard),
      },
      child: Actions(
        actions: {
          PasteTextIntent: CallbackAction<PasteTextIntent>(
            onInvoke: (_) => _richPaste(editorCtx, controller),
          ),
        },
        child: Builder(
          builder: (inner) {
            editorCtx = inner;
            onInnerContext?.call(editorCtx);
            return child;
          },
        ),
      ),
    );
  }

  /// Open the Quill editor dialog for a given essay (or "general draft" if null).
  /// Saves the draft (Quill delta JSON) locally in `_drafts` and via stubbed backend.
  void _openQuillEditorDialogFor(Assignment? essay) async {
    if (!_sessionActive) return;

    BuildContext? draftEditorCtx;

    Widget editorWithContextMenuForDraft() {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapDown: (details) async {
          // Show a desktop-style context menu with Paste (rich)
          final selected = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: const [
              PopupMenuItem(value: 'paste_rich', child: Text('Paste (rich)')),
            ],
          );
          if (selected == 'paste_rich' && draftEditorCtx != null) {
            _richPaste(draftEditorCtx!, _quillDraftController);
          }
        },
        child: quill.QuillEditor(
          focusNode: _draftFocus,
          scrollController: _quillDraftScrollController,
          controller: _quillDraftController,
          config: const quill.QuillEditorConfig(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
            placeholder: 'Write your essay here…',
          ),
        ),
      );
    }

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

        const double kMaxDocWidth = 960;
        const double kMaxDocHeight = 900;

        final double w = (mq.width * 0.90).clamp(480.0, kMaxDocWidth);
        final double h = (mq.height * 0.90).clamp(520.0, kMaxDocHeight);

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Builder(
            builder: (ctx) {
              return SizedBox(
                width: w,
                height: h,
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
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Paste (rich)',
                            icon: const Icon(Icons.content_paste),
                            onPressed: () {
                              final ctx = draftEditorCtx ?? context;
                              _richPaste(ctx, _quillDraftController);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: quill.QuillSimpleToolbar(
                              controller: _quillDraftController,
                              config: const quill.QuillSimpleToolbarConfig(
                                multiRowsDisplay: true,
                                showDividers: true,
                                showClipboardPaste: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // ----- Editor area -----
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _richPasteWrapper(
                            controller: _quillDraftController,
                            onInnerContext: (ctx) => draftEditorCtx = ctx,
                            child: editorWithContextMenuForDraft(),
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
                          // Submit (only show when tied to a real assignment)
                          if (essay != null)
                            FilledButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Submit'),
                              onPressed: () async {
                                // Optional: quick confirm
                                final ok =
                                    await _showSubmitConfirmation(context);
                                if (!ok) return;

                                try {
                                  final deltaJson = _quillDraftController
                                      .document
                                      .toDelta()
                                      .toJson();
                                  setState(() => _currentSession!
                                      .draftDeltaOps = deltaJson);
                                  await _saveCurrentSessionToPrefs();
                                  await _pushCurrentDraftToMoodle(essay);
                                  await _submitNow(essay);

                                  if (mounted) {
                                    Navigator.of(ctx)
                                        .pop(); // close editor after submit
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Submitted “${essay.name}”.')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Submit failed: $e')),
                                    );
                                  }
                                }
                              },
                            ),

                          const SizedBox(width: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save draft'),
                            onPressed: () async {
                              final deltaJson = _quillDraftController.document
                                  .toDelta()
                                  .toJson();
                              setState(() {
                                _currentSession!.draftDeltaOps = deltaJson;
                                _statusCache[_currentSession!.id] =
                                    EssayStatus.inProgress;
                              });
                              await _saveCurrentSessionToPrefs();

                              if (essay?.id != null) {
                                try {
                                  await _pushCurrentDraftToMoodle(essay!);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Moodle draft save failed: $e')),
                                  );
                                }
                              }

                              if (mounted) {
                                Navigator.of(ctx).pop();
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

    BuildContext? notesEditorCtx;

    Widget editorWithContextMenuForNotes() {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapDown: (details) async {
          // Show a desktop-style context menu with Paste (rich)
          final selected = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: const [
              PopupMenuItem(value: 'paste_rich', child: Text('Paste (rich)')),
            ],
          );
          // ignore: unnecessary_null_comparison
          if (selected == 'paste_rich' && notesEditorCtx != null) {
            _richPaste(notesEditorCtx!, _quillNotesController);
          }
        },
        child: quill.QuillEditor(
          focusNode: _notesFocus,
          scrollController: _quillNotesScrollController,
          controller: _quillNotesController,
          config: const quill.QuillEditorConfig(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
            placeholder: 'Take your notes here…',
          ),
        ),
      );
    }

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Toolbar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Paste (rich)',
                        icon: const Icon(Icons.content_paste),
                        onPressed: () {
                          final ctx = notesEditorCtx ?? context;
                          _richPaste(ctx, _quillNotesController);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: quill.QuillSimpleToolbar(
                          controller: _quillNotesController,
                          config: const quill.QuillSimpleToolbarConfig(
                            multiRowsDisplay: true,
                            showDividers: true,
                            showClipboardPaste: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Editor
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _richPasteWrapper(
                          controller: _quillNotesController,
                          onInnerContext: (ctx) => notesEditorCtx = ctx,
                          child: editorWithContextMenuForNotes(),
                        )),
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
    if (_isStreaming) return; // ignore while the model is talking
    final txt = _inputCtrl.text;
    _handleSendPressed(types.PartialText(text: txt));
  }
}

/* ────────────────────────────────────────────────────────────────────────────
 * 5) Small UI helpers (stateless widgets)
 *  - _EssayModalContent: the centered dialog content for an assignment
 *  - _LabeledRow: neat label/value row used in the dialog body
 * ──────────────────────────────────────────────────────────────────────────── */

class _AssistantMessageCard extends StatelessWidget {
  const _AssistantMessageCard({
    required this.text,
    required this.child,
  });
  final String text;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            tooltip: 'Copy to clipboard',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyMarkdown(context, text),
          ))
    ]);
  }
}

/// Essay details modal content (title, due, description, actions).
class _EssayModalContent extends StatelessWidget {
  const _EssayModalContent({
    required this.essay,
    required this.course,
    required this.statusText,
    required this.onPrimary,
    required this.primaryLabel,
    this.hasSession = false,
    this.onReset,
  });

  final Assignment essay;
  final Course? course;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final String statusText;

  final bool hasSession;
  final Future<void> Function()? onReset;

  @override
  Widget build(BuildContext context) {
    final String dueText = (essay.dueDate != null)
        ? essay.dueDate!.toLocal().toIso8601String().split('T').first
        : 'No due date';
    final String descriptionText = removeHtmlTags(essay.description);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  essay.name,
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

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LabeledRow(label: 'Status', value: statusText),
                const SizedBox(height: 8),
                _LabeledRow(
                    label: 'Course',
                    value: course?.fullName ?? 'Unknown Course'),
                const SizedBox(height: 8),
                _LabeledRow(label: 'Due', value: dueText),
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
                  descriptionText,
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ),

        // Footer: primary + optional destructive reset button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              if (hasSession && onReset != null) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Reset Session'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () async {
                    await onReset!(); // parent handles 2-step confirm + wipe + restart
                    // if parent also restarts, it's fine to close the dialog here:
                    // Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
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
