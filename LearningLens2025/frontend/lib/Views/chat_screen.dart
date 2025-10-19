import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';

import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';

import 'package:learninglens_app/beans/chatLog.dart';

import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/services/LLMContextBuilder.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:learninglens_app/Api/llm/local_llm_service.dart'; // local llm
import 'package:flutter/foundation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // --- UI controllers ---
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- State ---
  final List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  final List<ChatTurn> _chatHistory = <ChatTurn>[];
  bool _isLoading = false;

  // LLM selection
  LlmType _selectedLLM = LlmType.CHATGPT;
  bool _localLlmAvail = !kIsWeb;

  // Check if user has API key for selected LLM
  bool _hasKeyFor(LlmType llm) {
    return (llm == LlmType.LOCAL &&
            LocalStorageService.getLocalLLMPath() != "" &&
            _localLlmAvail) ||
        LocalStorageService.userHasLlmKey(llm);
  }

  // Persistence
  SharedPreferences? _prefs;
  static const String kChatHistoryKey = 'chat_history';

  /// Initialize the chat screen.
  @override
  void initState() {
    super.initState();
    _init();
  }

  // Clean up controllers
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------- Init / persistence ----------

  // Initialize state, load history
  Future<void> _init() async {
    await _loadChatHistory();
  }

  // Ensure SharedPreferences instance
  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    await _ensurePrefs();

    try {
      final saved = _prefs?.getString(kChatHistoryKey);
      if (saved?.isNotEmpty == true) {
        final List<dynamic> raw = jsonDecode(saved!);
        _chatHistory
          ..clear()
          ..addAll(
            raw.map((e) {
              final map = (e is Map)
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{};
              return ChatTurn.fromJson(map);
            }),
          );
      } else {
        _chatHistory.clear();
      }
    } catch (e, st) {
      debugPrint('$e\n$st');
      _chatHistory.clear();
      await _prefs?.remove(kChatHistoryKey);
    }

    // Rebuild UI messages
    _rebuildMessagesFromHistory();
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    await _ensurePrefs();
    try {
      final serialized =
          jsonEncode(_chatHistory.map((t) => t.toJson()).toList());
      await _prefs!.setString(kChatHistoryKey, serialized);
    } catch (e, st) {
      debugPrint('[chat] save failed: $e\n$st');
    }
  }

  // ---------- Helpers ----------

  // Rebuild UI messages from chat history
  void _rebuildMessagesFromHistory() {
    _messages
      ..clear()
      ..addAll(
        _chatHistory.map((t) => <String, dynamic>{
              'text': t.content,
              'sender': t.role == 'assistant' ? 'bot' : 'user',
            }),
      );
  }

  // Determine user role from LMS service
  UserRole _getUserRole() {
    // Safe default to student
    return LmsFactory.getLmsService().role ?? UserRole.student;
  }

  // Build system instructions based on user role
  String _buildInstructions(UserRole role) {
    if (role == UserRole.teacher) {
      return '''
    You are an AI assistant for teachers. Be concise, practical, accurate.
    - Answer educator questions clearly.
    - Explain concepts at any grade level.
    - Offer strategies for planning, assessment, engagement, and inclusion.
    - Maintain professional, supportive tone; respect privacy and academic ethics.
    - Ask clarifying questions when uncertain.
    IMPORTANT: Use plain text only (no Markdown).
    ''';
    }
    // Student
    return '''
    You are an AI learning assistant for students. Be concise, supportive, and clear.
    - Explain topics in student-friendly terms.
    - Provide examples, hints, or step-by-step reasoning.
    - Encourage problem-solving and study skills.
    - Do not complete graded work outright; teach the reasoning.
    - Ask clarifying questions when unsure.
    IMPORTANT: Use plain text only (no Markdown).
    ''';
  }

  //---------- Scrolling ----------
  // Scroll to bottom of chat
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // Schedule scroll after frame
  void _postFrameScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Append message bubble and scroll
  void _appendMessageBubble(String text, String sender) {
    _messages.add({'text': text, 'sender': sender});
    _postFrameScroll();
  }

  // Show a SnackBar message
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Sending ----------

  Future<void> _sendMessage() async {
    if (_isLoading) return; // prevent double-send
    await _ensurePrefs();

    final input = _controller.text.trim();
    if (input.isEmpty) return;

    // Ensure selected model has a usable key before doing anything else
    if (!_hasKeyFor(_selectedLLM)) {
      _showSnack('Missing API key for ${_selectedLLM.displayName}.');
      return;
    }

    // Select model
    final LLM aiModel;
    switch (_selectedLLM) {
      case LlmType.CHATGPT:
        final key = LocalStorageService.getOpenAIKey();
        if (key.isEmpty) {
          _showSnack('OpenAI API key is missing.');
          return;
        }
        aiModel = OpenAiLLM(key);
      case LlmType.GROK:
        final key = LocalStorageService.getGrokKey();
        if (key.isEmpty) {
          _showSnack('Grok API key is missing.');
          return;
        }
        aiModel = GrokLLM(key);
      case LlmType.PERPLEXITY:
        final key = LocalStorageService.getPerplexityKey();
        if (key.isEmpty) {
          _showSnack('Perplexity API key is missing.');
          return;
        }
        aiModel = PerplexityLLM(key);
      case LlmType.DEEPSEEK:
        final key = LocalStorageService.getDeepseekKey();
        if (key.isEmpty) {
          _showSnack('DeepSeek API key is missing.');
          return;
        }
        aiModel = DeepseekLLM(key);
      case LlmType.LOCAL:
        final llmPath = LocalStorageService.getLocalLLMPath();
        if (llmPath == "" || !_localLlmAvail) {
          _showSnack('Local LLM is not loaded.');
          return;
        }
        aiModel = LocalLLMService();
    }

    // Optimistic UI
    setState(() {
      _isLoading = true;
      _appendMessageBubble(input, 'user');
    });
    _controller.clear();

    // Persist user turn
    _chatHistory.add(ChatTurn(role: 'user', content: input));
    await _saveChatHistory();

    // Build context & call model
    final role = _getUserRole();
    final instructions = _buildInstructions(role);

    // Call model
    try {
      final ctx = generateContext(
        permTokens: PermTokens(core: instructions),
        chatHistory: _chatHistory,
        userPrompt: input,
        llmContextSize: aiModel.contextSize,
        maxOutputTokens: 500,
      );
      print(ctx);
      final response = await aiModel.chat(context: ctx);

      if (!mounted) return;
      setState(() {
        _chatHistory.add(ChatTurn(role: 'assistant', content: response));
        _appendMessageBubble(response, 'bot');
        _isLoading = false;
      });
      await _saveChatHistory();
    } catch (e, st) {
      debugPrint('[chat] error: $e\n$st');
      if (!mounted) return;
      const errText = 'Error: Could not fetch response. Please try again.';
      setState(() {
        // Keep error in history for transparency
        _chatHistory.add(const ChatTurn(role: 'assistant', content: errText));
        _appendMessageBubble(errText, 'bot');
        _isLoading = false;
      });
      await _saveChatHistory();
    }
  }

  // ---------- Clear ----------

  // Clear chat history
  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
      _chatHistory.clear();
    });
    await _ensurePrefs();
    await _prefs!.remove(kChatHistoryKey);
    debugPrint('[chat] cleared history');
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final canSend = !_isLoading &&
        _hasKeyFor(_selectedLLM); // disable send when loading/missing key

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ask Chatbot!',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      backgroundColor: scheme.surface,
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['sender'] == 'user';

                      final bubbleColor =
                          isUser ? scheme.primary : scheme.surfaceVariant;
                      final textColor =
                          isUser ? scheme.onPrimary : scheme.onSurfaceVariant;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Input
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Enter your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor ??
                                scheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                          ),
                          onSubmitted: (_) {
                            if (canSend) _sendMessage();
                          },
                          enabled: !_isLoading,
                        ),
                      ),

                      // Send
                      IconButton(
                        icon:
                            const Icon(Icons.send, color: Colors.purpleAccent),
                        onPressed: canSend ? _sendMessage : null,
                        tooltip: canSend
                            ? 'Send'
                            : 'Unavailable (loading or missing API key)',
                      ),

                      // Clear
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearChat,
                        tooltip: 'Clear chat history',
                      ),

                      // LLM picker
                      DropdownButton<LlmType>(
                        value: _selectedLLM,
                        onChanged: (LlmType? newValue) {
                          if (newValue == null) return;
                          if (_hasKeyFor(newValue)) {
                            setState(() => _selectedLLM = newValue);
                          } else {
                            _showSnack(
                                'No API key set for ${newValue.displayName}.');
                          }
                        },
                        items: LlmType.values.map((llm) {
                          final enabled = _hasKeyFor(llm);
                          return DropdownMenuItem<LlmType>(
                            value: llm,
                            enabled: enabled,
                            child: Text(
                              llm.displayName,
                              style: TextStyle(
                                color: enabled ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
