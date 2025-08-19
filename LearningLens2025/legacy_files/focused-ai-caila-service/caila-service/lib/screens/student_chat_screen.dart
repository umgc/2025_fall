import 'package:flutter/material.dart';
import 'package:focused_ai_app/models/assignment.dart';
import '../components/app_navbar.dart';
import '../services/caila_service.dart';
import '../models/course.dart';
import '../models/user.dart';

class StudentChatScreen extends StatefulWidget {
  final String? authToken;
  final Course? course;
  final User? user;

  const StudentChatScreen({
    super.key,
    this.authToken,
    this.course,
    this.user,
  });

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController chatController = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    if (widget.authToken == null) return;

    try {
      final history = await CailaService.getChatHistory(
        authToken: widget.authToken!,
      );
      
      setState(() {
        chatHistory = history.map((item) => {
          'role': item['role']?.toString() ?? '',
          'content': item['content']?.toString() ?? '',
          'timestamp': item['timestamp']?.toString() ?? '',
        }).toList();
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _sendMessage() async {
    if (chatController.text.trim().isEmpty) return;

    final message = chatController.text.trim();
    setState(() {
      chatHistory.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      isLoading = true;
    });

    chatController.clear();

    try {
      String response;
      if (widget.authToken != null) {
        response = await CailaService.chatWithCaila(
          authToken: widget.authToken!,
          prompt: message,
          courseId: widget.course?.id,
          studentId: widget.user?.id,
        );
      } else {
        await Future.delayed(const Duration(seconds: 2));
        response = "This is a demo response to your message: '$message'";
      }

      setState(() {
        chatHistory.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      setState(() {
        chatHistory.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error: $e',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavbar(
        title: widget.course != null 
            ? '💬 Chat - ${widget.course!.name}'
            : '💬 Chat with CAILA',
      ),
      body: Column(
        children: [
          // Chat header info
          if (widget.course != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chatting about ${widget.course!.name}',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                  if (widget.authToken != null)
                    Text(
                      'Logged',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatHistory.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatHistory.length && isLoading) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('CAILA is thinking...'),
                      ],
                    ),
                  );
                }
                
                final message = chatHistory[index];
                final isUser = message['role'] == 'user';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text('C', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(message['content'] ?? ''),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text('S', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Chat input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _sendMessage,
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }
}

// Extension for Assignment copyWith method
extension AssignmentCopyWith on Assignment {
  Assignment copyWith({
    String? id,
    String? courseId,
    String? name,
    String? description,
    String? language,
    DateTime? dueDate,
    double? maxScore,
    String? platform,
    String? status,
    int? submissionCount,
    DateTime? createdAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      description: description ?? this.description,
      language: language ?? this.language,
      dueDate: dueDate ?? this.dueDate,
      maxScore: maxScore ?? this.maxScore,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      submissionCount: submissionCount ?? this.submissionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}