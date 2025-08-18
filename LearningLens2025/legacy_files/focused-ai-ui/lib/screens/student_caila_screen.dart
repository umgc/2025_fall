import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focused_ai_ui/models/lms.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../components/app_navbar.dart';
import '../constants/server_constants.dart';
import '../services/caila_service.dart';
import '../services/auth_service.dart';
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/user.dart';
import '../services/google_classroom_service.dart';
import '../services/moodle_service.dart';

class StudentCailaScreen extends StatefulWidget {
  final String? authToken;
  final User? user;
  final List<Course>? courses;
  final int initialTab;

  const StudentCailaScreen({
    super.key,
    this.authToken,
    this.user,
    this.courses,
    this.initialTab = 0,
  });

  @override
  State<StudentCailaScreen> createState() => _StudentCailaScreenState();
}

class _StudentCailaScreenState extends State<StudentCailaScreen>
    with TickerProviderStateMixin {
  // Tab controller for different views
  late TabController _tabController;

  // Course and assignment management
  List<Course> availableCourses = [];
  Course? selectedCourse;
  List<Assignment> assignments = [];
  Assignment? selectedAssignment;

  // Chat functionality
  final TextEditingController chatController = TextEditingController();
  // final TextEditingController answerController = TextEditingController(); // COMMENTED OUT
  final ScrollController scrollController = ScrollController();
  List<Map<String, String>> chatHistory = [];
  List<Map<String, String>> cailaMessages = [];
  String? currentSessionId;

  // Services
  final MoodleService _moodleService = MoodleService();
  final GoogleClassroomService googleClassroomService =
      GoogleClassroomService();

  // Loading states
  bool isLoadingCourses = false;
  bool isLoadingAssignments = false;
  bool isLoadingChat = false;
  bool isLoadingHistory = false;
  // bool isSubmitting = false; // COMMENTED OUT

  // Error handling
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _initializeCourses();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    chatController.dispose();
    // answerController.dispose(); // COMMENTED OUT
    scrollController.dispose();
    super.dispose();
  }

  // ===== INITIALIZATION METHODS =====

  void _initializeCourses() {
    if (widget.courses != null && widget.courses!.isNotEmpty) {
      setState(() {
        availableCourses = widget.courses!;
        if (availableCourses.isNotEmpty) {
          selectedCourse = availableCourses.first;
        }
      });
      _loadAssignments();
    } else {
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isLoggedIn || authService.currentUser == null) {
      setState(() {
        if (availableCourses.isNotEmpty) {
          selectedCourse = availableCourses.first;
        }
      });
      _loadAssignments();
      return;
    }

    setState(() {
      isLoadingCourses = true;
      errorMessage = null;
    });

    try {
      final user = authService.currentUser!;
      List<Course> loadedCourses = [];

      if (user.lmsType == LMS.googleClassroom) {
        final googleService = GoogleClassroomService();
        loadedCourses = await googleService.getCourses();
      } else if (user.lmsType == LMS.moodle) {
        final moodleService = MoodleService();
        loadedCourses = await moodleService.getCourses();
      }

      setState(() {
        availableCourses = loadedCourses;
        if (availableCourses.isNotEmpty) {
          selectedCourse = availableCourses.first;
        }
        isLoadingCourses = false;
      });

      _loadAssignments();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load courses: $e';
        isLoadingCourses = false;
        if (availableCourses.isNotEmpty) {
          selectedCourse = availableCourses.first;
        }
      });
      _loadAssignments();
    }
  }

  Future<void> _loadAssignments() async {
    if (selectedCourse == null) return;

    setState(() {
      isLoadingAssignments = true;
      errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final authToken = widget.authToken ?? authService.jwt;

      if (authToken != null && authService.isLoggedIn) {
        List<Assignment> assignmentsList = [];

        if (selectedCourse!.platform.toLowerCase() == 'google') {
          final googleService = GoogleClassroomService();
          assignmentsList = await googleService.getAssignments(
            selectedCourse!.id,
          );
        } else {
          assignmentsList = await _moodleService.getAssignments(
            selectedCourse!.id,
          );
        }

        setState(() {
          assignments = assignmentsList;
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load assignments: $e';
      });
    } finally {
      setState(() {
        isLoadingAssignments = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final authToken = widget.authToken ?? authService.jwt;

    if (authToken == null || !authService.isLoggedIn) {
      setState(() {
        chatHistory = [
          {
            'role': 'assistant',
            'content': _getWelcomeMessage(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        ];
      });
      return;
    }

    setState(() {
      isLoadingHistory = true;
      errorMessage = null;
    });

    try {
      final history = await CailaService.getChatHistory(authToken: authToken);

      setState(() {
        chatHistory = history
            .map(
              (item) => {
                'role': item['role']?.toString() ?? '',
                'content': item['content']?.toString() ?? '',
                'timestamp': item['timestamp']?.toString() ?? '',
              },
            )
            .toList();

        if (chatHistory.isEmpty) {
          chatHistory.add({
            'role': 'assistant',
            'content': _getWelcomeMessage(),
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load chat history: $e';
        chatHistory = [
          {
            'role': 'assistant',
            'content': _getWelcomeMessage(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        ];
      });
    } finally {
      setState(() {
        isLoadingHistory = false;
      });
    }
  }

  // ===== ASSIGNMENT HANDLING =====

  Future<void> _onAssignmentSelected(Assignment assignment) async {
    setState(() {
      selectedAssignment = assignment;
      cailaMessages.clear();
      // answerController.clear(); // COMMENTED OUT
      currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      isLoadingChat = true;
    });

    await _loadAssignmentChatHistory();

    if (cailaMessages.isEmpty) {
      final welcomeMessage = _generateWelcomeMessage(assignment);
      setState(() {
        cailaMessages.add({
          "role": "assistant",
          "content": welcomeMessage,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });
    }

    setState(() {
      isLoadingChat = false;
    });
  }

  Future<void> _loadAssignmentChatHistory() async {
    if (selectedAssignment == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final authToken = widget.authToken ?? authService.jwt;

    if (authToken == null || !authService.isLoggedIn) return;

    try {
      List<Map<String, String>> history = [];

      if (selectedCourse!.platform.toLowerCase() == 'google') {
        history = await _loadGoogleAssignmentChatHistory(
          authToken,
          selectedAssignment!.id,
        );
      } else {
        history = await _moodleService.getAssignmentChatHistory(
          authToken: authToken,
          assignmentId: selectedAssignment!.id,
        );
      }

      if (history.isNotEmpty) {
        setState(() {
          cailaMessages = history;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      // Don't show error to user, just proceed without history
    }
  }

  Future<List<Map<String, String>>> _loadGoogleAssignmentChatHistory(
    String authToken,
    String assignmentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ServerConstants.cailaServerUrl}/caila/chat/assignment/$assignmentId/history',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> chatHistory = responseData['chatHistory'] ?? [];

          List<Map<String, String>> formattedHistory = [];

          for (var message in chatHistory) {
            if (message is Map<String, dynamic>) {
              formattedHistory.add({
                'role': message['role']?.toString() ?? '',
                'content': message['content']?.toString() ?? '',
                'timestamp':
                    message['timestamp']?.toString() ??
                    DateTime.now().toIso8601String(),
              });
            }
          }

          return formattedHistory;
        }
      } else if (response.statusCode == 401) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      }
    } catch (e) {
      // Error handled by caller
    }

    return [];
  }

  String _generateWelcomeMessage(Assignment assignment) {
    final urgency = _moodleService.getAssignmentUrgency(assignment);
    final dueText = _moodleService.formatDueDate(assignment.dueDate);

    String message =
        "Hello! I'm CAILA, and I'm here to help you with **${assignment.name}**.";

    if (urgency == 'overdue') {
      message +=
          "\n\n⚠️ **Note:** This assignment is overdue ($dueText). Let's focus on getting it completed as soon as possible.";
    } else if (urgency == 'due_soon') {
      message +=
          "\n\n⏰ **Note:** This assignment is due soon ($dueText). Let's work efficiently to meet the deadline.";
    } else if (assignment.dueDate != null) {
      message += "\n\n📅 **Due Date:** $dueText";
    }

    message += "\n\n⭐ **Points:** ${assignment.maxPoints} points available";

    message += "\n\nI can help you with:";
    message += "\n• Understanding the assignment requirements";
    message += "\n• Breaking down complex tasks";
    message += "\n• Time management and planning";
    message += "\n• Clarifying concepts and answering questions";
    message += "\n• Providing study strategies";

    if (assignment.status == 'submitted') {
      message +=
          "\n\n✅ **Status:** You've already submitted this assignment. I can still help you understand the concepts or prepare for related work.";
    }

    message += "\n\nWhat would you like to work on first?";

    return message;
  }

  // ===== CHAT FUNCTIONALITY =====

  String _getWelcomeMessage() {
    if (selectedCourse != null) {
      return """Hello! I'm CAILA, your AI teaching assistant for ${selectedCourse!.name}. 

I'm here to help you with:
• Understanding course concepts
• Working through assignments
• Explaining difficult topics
• Study strategies and tips
• General academic guidance
• Programming help and debugging (Coding assignments)
• Code review and best practices (Coding assignments)

Feel free to ask me anything about the course material or your assignments. How can I help you today?""";
    } else {
      return """Hello! I'm CAILA, your AI teaching assistant.

I can help you with:
• Understanding academic concepts
• Assignment guidance
• Study strategies
• Research techniques
• Writing and analysis
• Programming and coding help

What would you like to learn or work on today?""";
    }
  }

  Future<void> _sendMessage() async {
    if (chatController.text.trim().isEmpty) return;

    final message = chatController.text.trim();
    final authService = Provider.of<AuthService>(context, listen: false);
    final authToken = widget.authToken ?? authService.jwt;

    setState(() {
      chatHistory.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      isLoadingChat = true;
      errorMessage = null;
    });

    chatController.clear();
    _scrollToBottom();

    try {
      String response;
      if (authToken != null && authService.isLoggedIn) {
        final enhancedPrompt = _buildEnhancedPrompt(message);
        response = await CailaService.chatWithCaila(
          authToken: authToken,
          prompt: enhancedPrompt,
          courseId: selectedCourse?.id,
          studentId: widget.user?.id,
        );
      } else {
        await Future.delayed(const Duration(seconds: 2));
        response = _generateDemoResponse(message);
      }

      setState(() {
        chatHistory.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        chatHistory.add({
          'role': 'assistant',
          'content':
              'Sorry, I encountered an error: $e\n\nPlease try again or rephrase your question.',
          'timestamp': DateTime.now().toIso8601String(),
        });
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoadingChat = false;
      });
    }
  }

  Future<void> _sendMessageToCaila(String message) async {
    if (message.trim().isEmpty || selectedAssignment == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final authToken = widget.authToken ?? authService.jwt;

    setState(() {
      isLoadingChat = true;
      cailaMessages.add({
        "role": "user",
        "content": message,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });

    try {
      String response;
      if (authToken != null && authService.isLoggedIn) {
        if (selectedCourse!.platform.toLowerCase() == 'google') {
          response = await _sendGoogleAssignmentChatMessage(
            authToken: authToken,
            prompt: message,
            courseId: selectedCourse!.id,
            assignmentId: selectedAssignment!.id,
            sessionId: currentSessionId,
          );
        } else {
          response = await _moodleService.chatWithAssignment(
            authToken: authToken,
            prompt: message,
            courseId: selectedCourse!.id,
            assignmentId: selectedAssignment!.id,
            sessionId: currentSessionId,
          );
        }
      } else {
        await Future.delayed(const Duration(seconds: 2));
        response = _generateDemoResponse(message);
      }

      setState(() {
        cailaMessages.add({
          "role": "assistant",
          "content": response,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        cailaMessages.add({
          "role": "assistant",
          "content":
              "Sorry, I encountered an error: $e\n\nPlease try again or rephrase your question.",
          "timestamp": DateTime.now().toIso8601String(),
        });
      });
    } finally {
      setState(() {
        isLoadingChat = false;
      });
    }
  }

  Future<String> _sendGoogleAssignmentChatMessage({
    required String authToken,
    required String prompt,
    required String courseId,
    required String assignmentId,
    String? sessionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/chat/assignment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'prompt': prompt,
          'courseId': courseId,
          'assignmentId': assignmentId,
          'sessionId':
              sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          return responseData['response'] ?? 'No response received';
        } else {
          throw Exception(responseData['error'] ?? 'Assignment chat failed');
        }
      } else if (response.statusCode == 401) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception(
          'Assignment chat failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to chat about assignment: $e');
    }
  }

  String _buildEnhancedPrompt(String userMessage) {
    StringBuffer context = StringBuffer();

    if (selectedCourse != null) {
      context.writeln("COURSE CONTEXT:");
      context.writeln("Course: ${selectedCourse!.name}");
      context.writeln("Platform: ${selectedCourse!.platform.toUpperCase()}");
      context.writeln("Description: ${selectedCourse!.description}");
      context.writeln("Instructor: ${selectedCourse!.instructor}");
      context.writeln();
    }

    final lowerMessage = userMessage.toLowerCase();
    bool isAssignmentRelated =
        lowerMessage.contains('assignment') ||
        lowerMessage.contains('homework') ||
        lowerMessage.contains('quiz') ||
        lowerMessage.contains('essay') ||
        lowerMessage.contains('due') ||
        lowerMessage.contains('submit');

    if (isAssignmentRelated) {
      context.writeln("ASSIGNMENT CONTEXT NOTE:");
      context.writeln(
        "This question appears to be about assignments. CAILA will automatically",
      );
      context.writeln(
        "include relevant assignment information in the response based on your course.",
      );
      context.writeln();
    }

    if (widget.user != null) {
      context.writeln("STUDENT CONTEXT:");
      context.writeln("Student: ${widget.user!.name}");
      context.writeln("Role: ${widget.user!.role}");
      context.writeln();
    }

    if (chatHistory.length > 1) {
      context.writeln("RECENT CONVERSATION:");
      final startIndex = chatHistory.length > 6 ? chatHistory.length - 6 : 0;
      final recentMessages = chatHistory
          .sublist(startIndex)
          .where((msg) => msg['role'] != null);
      for (final msg in recentMessages) {
        if (msg['role'] == 'user') {
          context.writeln("Student: ${msg['content']}");
        } else if (msg['role'] == 'assistant') {
          final content = msg['content'] ?? '';
          final preview = content.length > 100
              ? '${content.substring(0, 100)}...'
              : content;
          context.writeln("CAILA: $preview");
        }
      }
      context.writeln();
    }

    context.writeln("CURRENT STUDENT QUESTION:");
    context.writeln(userMessage);
    context.writeln();

    context.writeln(
      "Please provide helpful, educational guidance. Your response should:",
    );
    context.writeln("• Be encouraging and supportive");
    context.writeln("• Guide learning without giving direct answers");
    context.writeln("• Ask clarifying questions when appropriate");
    context.writeln("• Provide examples and analogies");
    context.writeln("• Encourage critical thinking");
    context.writeln("• Be conversational and friendly");

    return context.toString();
  }

  String _generateDemoResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('code') ||
        message.contains('program') ||
        message.contains('algorithm') ||
        message.contains('debug') ||
        message.contains('error') ||
        message.contains('syntax')) {
      return _generateCodingResponse(message);
    }

    if (message.contains('math') ||
        message.contains('equation') ||
        message.contains('calculate') ||
        message.contains('formula') ||
        message.contains('solve')) {
      return _generateMathResponse(message);
    }

    if (message.contains('essay') ||
        message.contains('write') ||
        message.contains('paper') ||
        message.contains('thesis') ||
        message.contains('research')) {
      return _generateWritingResponse(message);
    }

    if (message.contains('study') ||
        message.contains('exam') ||
        message.contains('test') ||
        message.contains('review') ||
        message.contains('prepare')) {
      return _generateStudyResponse(message);
    }

    if (message.contains('help') ||
        message.contains('confused') ||
        message.contains('understand') ||
        message.contains('explain')) {
      return "I'm here to help! Learning can be challenging, but that's how we grow. What specific topic or concept would you like to explore together?";
    }

    if (message.contains('hello') ||
        message.contains('hi') ||
        message.contains('hey') ||
        message.contains('good morning') ||
        message.contains('good afternoon')) {
      return "Hello! I'm glad you're here. I'm CAILA, and I'm excited to help you learn. What would you like to work on today? I can help with ${selectedCourse?.name ?? 'your studies'}, assignments, or any questions you might have.";
    }

    return "That's an interesting question! I'd love to help you explore this topic further. Could you tell me a bit more about what specific aspect you're working on or what's challenging you? This will help me provide more targeted guidance.";
  }

  String _generateCodingResponse(String message) {
    final responses = [
      "Great question about programming! When working with code, I find it helpful to start by understanding the problem clearly. What specific part of the code are you working on, and what behavior are you expecting versus what you're seeing?",
      "Debugging can be tricky, but it's a great learning opportunity! Let's think through this step by step. Can you describe what you're trying to accomplish and where you think the issue might be occurring?",
      "Programming is all about breaking down complex problems into smaller, manageable pieces. What's the main goal of your program, and have you tried writing out the logic in plain English first?",
      "Code errors are normal and actually help us learn! When you encounter an error, the first step is to read the error message carefully. What does the error message tell you, and have you tried looking up any unfamiliar terms?",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _generateMathResponse(String message) {
    final responses = [
      "Math problems often become clearer when we break them down step by step. What's the specific concept or type of problem you're working with? I can help you think through the approach.",
      "Great question! Math is all about patterns and logical thinking. Can you share what you've tried so far, or what part of the problem seems most challenging?",
      "I love helping with math! Let's start by identifying what we know and what we need to find. Have you drawn a diagram or written down the given information?",
      "Mathematical problem-solving often benefits from multiple approaches. What method are you considering, and have you thought about whether there might be alternative ways to solve this?",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _generateWritingResponse(String message) {
    final responses = [
      "Writing is a process, and every good piece starts with clear thinking! What's your main topic or thesis, and what points do you want to make to support it?",
      "Excellent! Writing is one of the best ways to organize and express your thoughts. Have you started with an outline, or would you like to brainstorm your main ideas first?",
      "Research and writing go hand in hand. What's your topic, and what kind of sources are you looking for? I can help you think about where to find credible information.",
      "The key to good writing is clarity and organization. What's the purpose of your paper, and who is your intended audience? This will help guide your approach.",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _generateStudyResponse(String message) {
    final responses = [
      "Study strategies can make a huge difference in learning! What subject are you studying, and what methods have you tried so far? Different subjects often benefit from different approaches.",
      "Preparation is key to success! What material are you reviewing, and how much time do you have? I can help you create an effective study plan.",
      "Active studying is much more effective than passive reading. Are you testing yourself on the material, and have you tried explaining concepts in your own words?",
      "Great that you're being proactive about studying! What specific topics or concepts are you finding most challenging? We can work on strategies to tackle those areas.",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===== ASSIGNMENT ACTIONS - COMMENTED OUT =====

  /*
  Future<void> _saveWork() async {
    if (selectedAssignment == null || answerController.text.trim().isEmpty) {
      _showFeedback('Please select an assignment and add some content', isError: true);
      return;
    }

    _showFeedback('✅ Work saved for ${selectedAssignment!.name}');
  }

  Future<void> _submitAssignment() async {
    if (selectedAssignment == null || answerController.text.trim().isEmpty) {
      _showFeedback('Please complete your work before submitting', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: Text('Are you sure you want to submit "${selectedAssignment!.name}"? You may not be able to edit it after submission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final authToken = widget.authToken ?? authService.jwt;
      
      if (authToken != null && authService.isLoggedIn) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(seconds: 2));
      }
      
      _showFeedback('✅ Assignment "${selectedAssignment!.name}" submitted successfully!');
      
      setState(() {
        selectedAssignment = selectedAssignment!.copyWith(status: 'submitted');
        final index = assignments.indexWhere((a) => a.id == selectedAssignment!.id);
        if (index != -1) {
          assignments[index] = selectedAssignment!;
        }
      });
      
    } catch (e) {
      _showFeedback('❌ Submission failed: $e', isError: true);
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> _getFeedback() async {
    if (selectedAssignment == null || answerController.text.trim().isEmpty) {
      _showFeedback('Please select an assignment and write an answer first', isError: true);
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final authToken = widget.authToken ?? authService.jwt;
      
      String feedback;
      if (authToken != null && authService.isLoggedIn) {
        final rubric = await CailaService.generateRubric(
          authToken: authToken,
          assignmentPrompt: '${selectedAssignment!.name} - ${selectedAssignment!.description}',
          courseId: selectedCourse!.id,
        );
        
        feedback = await CailaService.evaluateAnswer(
          authToken: authToken,
          rubric: rubric,
          studentAnswer: answerController.text.trim(),
          courseId: selectedCourse!.id,
        );
      } else {
        feedback = _generateDemoFeedback();
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue),
              SizedBox(width: 8),
              Text("CAILA Feedback"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Assessment for: ${selectedAssignment!.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    feedback,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      _showFeedback('Error getting feedback: $e', isError: true);
    }
  }

  String _generateDemoFeedback() {
    if (selectedAssignment?.isCoding == true) {
      return """**Code Review Feedback**

**Strengths:**
• Good overall structure and approach
• Clean, readable code formatting
• Proper variable naming conventions

**Areas for Improvement:**
• Consider adding more comprehensive error handling
• Add more detailed comments explaining complex logic
• Think about edge cases and how to handle them

**Suggestions:**
• Test your code with various input scenarios
• Consider the time complexity of your solution
• Review the assignment requirements to ensure all criteria are met

**Grade Estimate:** B+ (87/100)

Keep up the good work! Your programming skills are developing well.""";
    } else {
      return """**Assignment Feedback**

**Strengths:**
• Clear thesis statement and good organization
• Demonstrates understanding of key concepts
• Good use of supporting evidence

**Areas for Improvement:**
• Expand on your analysis in the third paragraph
• Consider adding more specific examples
• Check your calculations in section 2

**Suggestions:**
• Review the assignment rubric to ensure all requirements are met
• Consider peer review before final submission
• Double-check your sources and citations

**Grade Estimate:** B+ (85/100)

Your work shows good understanding of the material. Focus on providing more detailed analysis to strengthen your arguments.""";
    }
  }
  */

  void _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all chat messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        chatHistory.clear();
        chatHistory.add({
          'role': 'assistant',
          'content': _getWelcomeMessage(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    }
  }

  void _refreshCourses() {
    _loadCourses();
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===== UI BUILDERS =====

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser ?? widget.user;
        final isAuthenticated = authService.isLoggedIn;
        final platform = selectedCourse?.platform.toUpperCase() ?? 'DEMO';

        return Scaffold(
          appBar: AppNavbar(
            title: '🎓 Student CAILA',
            showUserMenu: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _clearChat,
                tooltip: 'Clear Chat',
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Chip(
                  avatar: Icon(
                    user?.lmsType == LMS.googleClassroom ?? false
                        ? Icons.class_
                        : Icons.account_balance,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    '$platform Connected',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: isAuthenticated
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Course selection header
              if (!isAuthenticated) _buildDemoNotice(),
              _buildCourseSelectionHeader(user),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue[700],
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                    Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
                    Tab(icon: Icon(Icons.chat), text: 'General Chat'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboardTab(),
                    _buildAssignmentsTab(),
                    _buildChatTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border(bottom: BorderSide(color: Colors.orange[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            'Demo mode - Connect your account to access real courses and save progress',
            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelectionHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user != null ? 'Welcome, ${user.name}!' : 'Welcome to CAILA!',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isLoadingCourses)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _refreshCourses,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Courses',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Course>(
                  value: selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: availableCourses.map((course) {
                    return DropdownMenuItem<Course>(
                      value: course,
                      child: Text(
                        course.name.length > 40
                            ? '${course.name.substring(0, 37)}...'
                            : course.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (course) {
                    setState(() {
                      selectedCourse = course;
                      selectedAssignment = null;
                      cailaMessages.clear();
                    });
                    if (course != null) {
                      _loadAssignments();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${availableCourses.length} courses',
                style: TextStyle(fontSize: 12, color: Colors.blue[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedCourse != null) ...[
            _buildCourseInfoCard(),
            const SizedBox(height: 16),
            _buildQuickStatsCard(),
            const SizedBox(height: 16),
          ],
          _buildQuickActionsCard(),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard() {
    if (selectedCourse == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCourse!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.user?.lmsType == LMS.googleClassroom
                        ? Colors.blue[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedCourse!.platform.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.user?.lmsType == LMS.googleClassroom
                          ? Colors.blue[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            if (selectedCourse!.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(selectedCourse!.description),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Instructor: ${selectedCourse!.instructor}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${selectedCourse!.enrollmentCount} students',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Assignments',
                    '${assignments.length}',
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Due Soon',
                    '${assignments.where((a) => _moodleService.getAssignmentUrgency(a) == 'due_soon').length}',
                    Icons.alarm,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    '${assignments.where((a) => a.status == 'submitted').length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedCourse != null
                        ? () => _tabController.animateTo(1)
                        : null,
                    icon: const Icon(Icons.assignment),
                    label: const Text('View Assignments'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(2),
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with CAILA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Row(
      children: [
        // Left: Assignments List
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Assignments (${assignments.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (isLoadingAssignments)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: assignments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('No assignments found'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: assignments.length,
                          itemBuilder: (context, index) {
                            return _buildAssignmentCard(assignments[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Center: Assignment Work Area
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: selectedAssignment == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select an assignment to begin working',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildAssignmentWorkArea(),
          ),
        ),

        // Right: CAILA Chat for Assignment
        Expanded(flex: 3, child: _buildAssignmentChatInterface()),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final isSelected = selectedAssignment?.id == assignment.id;
    final urgency = _moodleService.getAssignmentUrgency(assignment);
    final urgencyColor = _moodleService.getUrgencyColor(urgency);
    final statusIcon = _moodleService.getStatusIcon(assignment.status);
    final dueText = _moodleService.formatDueDate(assignment.dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : null,
      elevation: isSelected ? 3 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: urgencyColor,
          child: Icon(statusIcon, color: Colors.white, size: 18),
        ),
        title: Text(
          assignment.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 60),
                child: Text(
                  assignment.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: urgencyColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dueText,
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(Icons.star, size: 12, color: Colors.amber[600]),
                const SizedBox(width: 2),
                Text(
                  '${assignment.maxPoints?.toInt()}pts',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSelected
                ? const Icon(Icons.arrow_drop_down, color: Colors.blue)
                : const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
        onTap: () => _onAssignmentSelected(assignment),
      ),
    );
  }

  Widget _buildAssignmentWorkArea() {
    final urgency = _moodleService.getAssignmentUrgency(selectedAssignment!);
    final urgencyColor = _moodleService.getUrgencyColor(urgency);
    final dueText = _moodleService.formatDueDate(selectedAssignment!.dueDate);
    final isSubmitted = selectedAssignment!.status == 'submitted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assignment header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedAssignment!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedAssignment!.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: urgencyColor),
                  const SizedBox(width: 4),
                  Text(
                    'Due: $dueText',
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.grade, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Max Score: ${selectedAssignment!.maxPoints?.toInt()} pts',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Text(
                'Assignment Description:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Text(
                      selectedAssignment!.description.isNotEmpty
                          ? selectedAssignment!.description
                          : 'No description provided for this assignment.',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status messages and action buttons
        if (urgency == 'overdue')
          _buildStatusMessage(
            'Assignment Overdue',
            'This assignment was $dueText. Contact your instructor if you need assistance.',
            Colors.red,
            Icons.warning,
          )
        else if (urgency == 'due_soon')
          _buildStatusMessage(
            'Due Soon',
            'This assignment is $dueText. Make sure to submit on time!',
            Colors.orange,
            Icons.alarm,
          )
        else if (isSubmitted)
          _buildStatusMessage(
            'Assignment Submitted',
            'Assignment submitted successfully! You can still chat with CAILA about the concepts.',
            Colors.green,
            Icons.check_circle,
          ),

        const SizedBox(height: 16),

        // Action buttons - COMMENTED OUT FOR NOW
        /*
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveWork,
                icon: const Icon(Icons.save),
                label: const Text('Save Work'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isSubmitted ? null : _getFeedback,
                icon: const Icon(Icons.assessment),
                label: const Text('Get Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isSubmitted || isSubmitting ? null : _submitAssignment,
                icon: isSubmitting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitted ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        */
      ],
    );
  }

  Widget _buildStatusMessage(
    String title,
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(message, style: TextStyle(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentChatInterface() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'CAILA Assistant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  if (authService.isLoggedIn) {
                    final platform =
                        selectedCourse?.platform.toUpperCase() ?? 'LMS';
                    return Tooltip(
                      message: 'Conversation logged to $platform',
                      child: const Icon(
                        Icons.save,
                        size: 16,
                        color: Colors.green,
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DEMO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (selectedAssignment != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Context: ${selectedAssignment!.name}',
                style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: cailaMessages.length + (isLoadingChat ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == cailaMessages.length && isLoadingChat) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            child: const Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue,
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'CAILA is thinking...',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          );
                        }
                        return _buildChatMessage(cailaMessages[index]);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(),
                            decoration: InputDecoration(
                              hintText: selectedAssignment != null
                                  ? 'Ask about ${selectedAssignment!.name}...'
                                  : 'Ask CAILA for help...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (value) => _sendMessageToCaila(value),
                            enabled: !isLoadingChat,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            isLoadingChat ? Icons.hourglass_empty : Icons.send,
                          ),
                          onPressed: isLoadingChat
                              ? null
                              : () {
                                  final controller = TextField().controller;
                                  if (controller != null) {
                                    _sendMessageToCaila(controller.text);
                                    controller.clear();
                                  }
                                },
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        if (selectedCourse != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course: ${selectedCourse!.name}',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedCourse!.instructor != null)
                        Text(
                          'Instructor: ${selectedCourse!.instructor}',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    final isAuthenticated = authService.isLoggedIn;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAuthenticated
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAuthenticated ? 'Logged' : 'Demo',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuthenticated
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        if (isLoadingHistory)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading chat history...'),
              ],
            ),
          ),

        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => errorMessage = null),
                  icon: Icon(Icons.close, color: Colors.red[700]),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: chatHistory.length + (isLoadingChat ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == chatHistory.length && isLoadingChat) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 16,
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CAILA is thinking...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final message = chatHistory[index];
              return _buildChatMessage(message);
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  decoration: InputDecoration(
                    hintText: selectedCourse != null
                        ? 'Ask about ${selectedCourse!.name}...'
                        : 'Type your message...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !isLoadingChat,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isLoadingChat ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: isLoadingChat
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),

        Consumer<AuthService>(
          builder: (context, authService, child) {
            final isAuthenticated = authService.isLoggedIn;
            if (!isAuthenticated) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border(top: BorderSide(color: Colors.orange[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Demo mode - Connect your account to save chat history',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ],
                ),
              );
            } else if (selectedCourse != null) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border(top: BorderSide(color: Colors.green[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Your conversation is being saved for teacher review',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildChatMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';
    final timestamp = message['timestamp'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser ? Colors.blue[200]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isUser ? Colors.blue[800] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.blue[600] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.green,
              radius: 16,
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(errorMessage!)),
          IconButton(
            onPressed: () => setState(() => errorMessage = null),
            icon: const Icon(Icons.close),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
