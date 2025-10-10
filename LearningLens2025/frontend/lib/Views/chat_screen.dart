import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/llm/DeepSeek_api.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/services/ContextBuilder.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving/loading chat history
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'dart:convert'; // For encoding and decoding chat history

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

  UserRole getUserRole() {
    return LmsFactory.getLmsService().role ?? UserRole.student;
  }

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _context = [];
  List<ChatTurn> _chatHistory = [];
  bool _isLoading = false;
  String _role = 'student'; // Role toggle for student/teacher
  final ScrollController _scrollController =
      ScrollController(); // For scrolling the chat
  SharedPreferences? _prefs; // SharedPreferences for saving chat history
  LlmType? selectedLLM;
  static  const String kChatHistoryKey = 'chat_history_v2';
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    _chatHistory = <ChatTurn>[]; 
    selectedLLM = LlmType.CHATGPT;
    _init();
  }
  Future<void> _init() async {
  await _loadChatHistory();
  if (mounted) setState(() => _historyLoaded = true);
}

Future<void> _loadChatHistory() async {
  _prefs = await SharedPreferences.getInstance();
  final saved = _prefs?.getString(kChatHistoryKey);

  // Migration: if old UI-style was saved under 'chat_history', try to convert
  if (saved == null) {
    final legacy = _prefs?.getString('chat_history');
    if (legacy != null) {
      final List<dynamic> raw = jsonDecode(legacy);
      // convert UI bubbles -> ChatTurn best-effort
      _chatHistory = raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final sender = (m['sender'] as String?) ?? 'user';
        final text = (m['text'] as String?) ?? '';
        return ChatTurn(
          role: sender == 'bot' ? 'assistant' : 'user',
          content: text,
        );
      }).toList();
      // rewrite in new format
      await _saveChatHistory();
    }
  } else {
    final List<dynamic> raw = jsonDecode(saved);
    _chatHistory =
        raw.map((e) => ChatTurn.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // Rebuild UI bubbles from _chatHistory
  if (_messages.isEmpty) {
    _rebuildMessagesFromHistory();
    if (mounted) setState(() {});
  }
}

// Save chat history to SharedPreferences
Future<void> _saveChatHistory() async {
  if (_prefs == null) return;
  final serialized = jsonEncode(_chatHistory.map((t) => t.toJson()).toList());
  await _prefs!.setString(kChatHistoryKey, serialized);
}

// Build UI bubbles from model history (idempotent)
void _rebuildMessagesFromHistory() {
  _messages = _chatHistory.map((t) => <String, dynamic>{
    'text': t.content,
    'sender': t.role == 'assistant' ? 'bot' : 'user',
  }).toList();
}


  // Function to handle user message sending and API response
  Future<void> _sendMessage() async {
    debugPrint('sendMessage start, input="${_controller.text}"');
    final input = _controller.text;
    if(input.isEmpty) {
      return; // Do not send empty messages
    }

    final userRole = getUserRole(); // 'student' or 'teacher'
    final instructions = userRole == UserRole.teacher
        ? """
            You are an AI teaching assistant that supports educators across subjects and grade levels.
            Your purpose is to save time, enhance learning, and provide reliable guidance in planning, assessment, and classroom support.

            Core Functions:

            -Answer teacher questions clearly and accurately.

            -Explain or simplify educational concepts for any grade level.

            -Provide ideas, examples, or strategies to improve instruction and engagement.

            -Suggest ways to adapt lessons for diverse learners and inclusive classrooms.

            -Maintain a professional, supportive tone and respect privacy and academic ethics.

            -When uncertain, ask clarifying questions before giving detailed answers.

            Focus on helpfulness, clarity, and accuracy — not creative writing or content generation handled by other features.
            Keep responses concise, practical, and ready for classroom use.

            IMPORTANT: Do not use any Markdown syntax (e.g., #, *, **, etc.). Use plain text only.

            You are an AI learning assistant that helps students understand and apply what they learn.
            Your purpose is to guide, explain, and encourage independent thinking, not just give answers.
            """
        : """
            You are an AI learning assistant that helps students understand and apply what they learn.
            Your purpose is to guide, explain, and encourage independent thinking, not just give answers.

            Core Functions:

            -Explain topics, assignments, or questions in clear, student-friendly terms.

            -Provide examples, hints, or step-by-step reasoning to help learning.

            -Encourage curiosity, problem-solving, and study skills.

            -Maintain a respectful, supportive, and motivating tone.

            -Never complete graded work or give full solutions without teaching the reasoning.

            -When unsure, ask clarifying questions before answering.

            -Focus on learning support, clarity, and encouragement — not doing the work for the student.
            -Keep responses concise, engaging, and easy to understand.

            IMPORTANT: Do not use any Markdown syntax (e.g., #, *, **, etc.). Use plain text only.
                    
          """;

    final LLM aiModel;
    if (selectedLLM == LlmType.CHATGPT) {
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    } else if (selectedLLM == LlmType.GROK) {
      aiModel = GrokLLM(LocalStorageService.getGrokKey());
    } else if (selectedLLM == LlmType.PERPLEXITY) {
      // aiModel = OpenAiLLM(perplexityApiKey);
      aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
    } else if (selectedLLM == LlmType.DEEPSEEK) {
      aiModel = DeepseekLLM(LocalStorageService.getDeepseekKey());
    } else {
      // default
      aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
    }

    // Update UI to show user's message and reset text field
    setState(() {
      _messages.add(<String, dynamic>{'text': input, 'sender': 'user'});
      _isLoading = true; // Show a loading indicator while waiting for response
    });

    _controller.clear(); // Clear the input field
    _scrollToBottom(); // Scroll to the bottom after sending the message

    _chatHistory.add(ChatTurn(role: 'user', content: input));
    await _saveChatHistory(); // Save chat history
   

    try {
      final ctx = buildContext(
        permTokens: PermTokens(core: instructions),
        chatHistory: _chatHistory,
        userPrompt: input,
        llmContextSize: aiModel.contextSize,
        maxOutputTokens: 500,
      );
      final response = await aiModel.chat(context: ctx);

      setState(() {
        _chatHistory.add(ChatTurn(role: 'assistant', content: response));
        _messages.add(<String, dynamic>{'text': response, 'sender': 'bot'});
        _isLoading = false;
      });

      await _saveChatHistory(); // Save chat history after bot response
      _scrollToBottom(); // Scroll to the bottom after receiving the bot response
    } catch (error) {
      setState(() {
        _messages.add({
          'text': 'Error: Could not fetch response. Please try again.',
          'sender': 'bot'
        });
        _isLoading = false;
      });
    }
  }

  // Function to clear chat history
  void _clearChat() {
    setState(() {
      _messages.clear();
      _chatHistory.clear();
    });
    _saveChatHistory(); // Save the empty state to clear saved chat history
  }

  // Scroll to the bottom of the chat list
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ask Chatbot!',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Main chat content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller:
                        _scrollController, // Attach the ScrollController
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUserMessage = message['sender'] == 'user';

                      return Align(
                        alignment: isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? Colors.deepPurple
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color:
                                  isUserMessage ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(), // Loading indicator
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Enter your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.purpleAccent),
                        onPressed: () {
                          debugPrint('SEND tapped, text="${_controller.text}"');
                          _sendMessage();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearChat, // Clear chat history
                      ),
                      // IconButton(
                      //   icon: Icon(Icons.switch_account),
                      //   onPressed: _toggleRole, // Toggle role between teacher and student
                      //   tooltip:
                      //       'Switch role to ${_role == 'student' ? 'Teacher' : 'Student'}',
                      // ),
                      DropdownButton<LlmType>(
                          value: selectedLLM,
                          onChanged: (LlmType? newValue) {
                            setState(() {
                              selectedLLM = newValue;
                            });
                          },
                          items: LlmType.values.map((LlmType llm) {
                            return DropdownMenuItem<LlmType>(
                              value: llm,
                              enabled: LocalStorageService.userHasLlmKey(llm),
                              child: Text(
                                llm.displayName,
                                style: TextStyle(
                                  color: LocalStorageService.userHasLlmKey(llm)
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                            );
                          }).toList()),
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
