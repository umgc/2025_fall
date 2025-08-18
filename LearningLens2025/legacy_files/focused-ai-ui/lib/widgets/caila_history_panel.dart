// lib/widgets/caila_history_panel.dart - Enhanced with Assignment Detection
import 'package:flutter/material.dart';
import '../apis/caila_api.dart';
import '../services/caila_service.dart';

class CailaHistoryPanel extends StatefulWidget {
  final String? authToken;
  final Function(List<Map<String, String>>, String?)? onResumeSession;

  const CailaHistoryPanel({
    super.key,
    this.authToken,
    this.onResumeSession,
  });

  @override
  State<CailaHistoryPanel> createState() => _CailaHistoryPanelState();
}

class _CailaHistoryPanelState extends State<CailaHistoryPanel> {
  List<Map<String, dynamic>> chatSessions = [];
  bool isLoading = false;
  String? errorMessage;
  String? selectedSessionId;
  Map<String, dynamic>? selectedSessionDetails;
  bool isLoadingSession = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    if (widget.authToken == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await CailaApi.getTeacherChatHistory(
        authToken: widget.authToken!,
      );

      if (response['success'] == true) {
        setState(() {
          chatSessions = List<Map<String, dynamic>>.from(response['chatSessions'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['error'] ?? 'Failed to load chat history';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadSessionDetails(String sessionId) async {
    if (widget.authToken == null) return;

    setState(() {
      isLoadingSession = true;
      selectedSessionId = sessionId;
    });

    try {
      final response = await CailaApi.getTeacherChatSession(
        authToken: widget.authToken!,
        sessionId: sessionId,
      );

      if (response['success'] == true) {
        setState(() {
          selectedSessionDetails = response;
          isLoadingSession = false;
        });
      } else {
        setState(() {
          selectedSessionDetails = null;
          isLoadingSession = false;
        });
        _showSnackBar('Failed to load session details: ${response['error']}', isError: true);
      }
    } catch (e) {
      setState(() {
        selectedSessionDetails = null;
        isLoadingSession = false;
      });
      _showSnackBar('Error loading session: $e', isError: true);
    }
  }

  void _resumeSession() {
    if (selectedSessionDetails != null && widget.onResumeSession != null) {
      final conversationHistory = selectedSessionDetails!['conversationHistory'] as List<dynamic>?;
      final sessionInfo = selectedSessionDetails!['sessionInfo'] as Map<String, dynamic>?;
      
      List<Map<String, String>> formattedHistory = [];
      if (conversationHistory != null) {
        formattedHistory = conversationHistory.map((msg) {
          return {
            'role': msg['role'] as String? ?? '',
            'content': msg['content'] as String? ?? '',
            'timestamp': msg['timestamp'] as String? ?? '',
          };
        }).toList();
      }

      widget.onResumeSession!(formattedHistory, sessionInfo?['courseId'] as String?);
      
      _showSnackBar('Session resumed! You can continue the conversation.', isError: false);
    }
  }

  void _closeSessionDetails() {
    setState(() {
      selectedSessionId = null;
      selectedSessionDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedSessionId != null) {
      return _buildSessionDetailsView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Chat History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadChatHistory,
                tooltip: 'Refresh History',
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _buildHistoryContent(),
        ),
      ],
    );
  }

  Widget _buildHistoryContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chat history...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading chat history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChatHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chatSessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chat history found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start creating materials with CAILA to see your conversation history here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatSessions.length,
      itemBuilder: (context, index) {
        final session = chatSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final materialType = session['materialType'] as String? ?? 'General';
    final courseName = session['courseName'] as String? ?? 'Unknown Course';
    final displayDate = session['displayDate'] as String? ?? '';
    final messageCount = session['messageCount'] as int? ?? 0;
    final preview = session['preview'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _loadSessionDetails(session['sessionId'] as String),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMaterialTypeColor(materialType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      materialType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    displayDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (preview.isNotEmpty)
                Text(
                  preview,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$messageCount message${messageCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionDetailsView() {
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeSessionDetails,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    if (selectedSessionDetails != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${selectedSessionDetails!['sessionInfo']?['materialType'] ?? 'Material'} • ${selectedSessionDetails!['sessionInfo']?['courseName'] ?? 'Course'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selectedSessionDetails != null && !isLoadingSession)
                ElevatedButton.icon(
                  onPressed: _resumeSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        
        // Session content
        Expanded(
          child: _buildSessionContent(),
        ),
      ],
    );
  }

  Widget _buildSessionContent() {
    if (isLoadingSession) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading session details...'),
          ],
        ),
      );
    }

    if (selectedSessionDetails == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to load session details'),
          ],
        ),
      );
    }

    final messages = selectedSessionDetails!['messages'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index] as Map<String, dynamic>;
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final prompt = message['prompt'] as String? ?? '';
    final response = message['response'] as String? ?? '';
    final timestamp = message['timestamp'] as String? ?? '';

    // Check if this response contains generated material for assignment preview detection
    final bool isGeneratedMaterial = CailaService.isGeneratedMaterial(response);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User message
          if (prompt.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CailaService.cleanMarkdownForDisplay(prompt),
                          style: TextStyle(color: Colors.purple[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CailaService.formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ],
            ),
          
          const SizedBox(height: 8),
          
          // CAILA response
          if (response.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isGeneratedMaterial ? Colors.green : Colors.purple,
                  child: Icon(
                    isGeneratedMaterial ? Icons.auto_awesome : Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isGeneratedMaterial ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: isGeneratedMaterial 
                          ? Border.all(color: Colors.green[300]!, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isGeneratedMaterial)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '✨ GENERATED MATERIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        SelectableText(
                          CailaService.cleanMarkdownForDisplay(response),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CailaService.formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getMaterialTypeColor(String materialType) {
    switch (materialType.toLowerCase()) {
      case 'quiz':
      case 'assessment':
        return Colors.blue;
      case 'assignment':
      case 'homework':
        return Colors.green;
      case 'lesson plan':
      case 'lesson':
        return Colors.orange;
      case 'worksheet':
        return Colors.purple;
      case 'essay':
        return Colors.red;
      case 'project':
        return Colors.teal;
      case 'rubric':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}