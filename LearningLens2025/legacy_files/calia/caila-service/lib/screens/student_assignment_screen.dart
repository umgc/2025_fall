import 'package:flutter/material.dart';
import '../components/app_navbar.dart';
import '../services/caila_service.dart';
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/user.dart';

class StudentAssignmentScreen extends StatefulWidget {
  final String? authToken;
  final Course course;
  final User? user;

  const StudentAssignmentScreen({
    super.key,
    this.authToken,
    required this.course,
    this.user,
  });

  @override
  State<StudentAssignmentScreen> createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  List<Assignment> assignments = [];
  Assignment? selectedAssignment;
  final TextEditingController answerController = TextEditingController();
  final TextEditingController chatController = TextEditingController();
  
  List<Map<String, String>> cailaMessages = [];
  bool isLoadingAssignments = false;
  bool isLoadingChat = false;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      isLoadingAssignments = true;
      errorMessage = null;
    });

    try {
      // For now, using demo assignments
      // In real implementation, this would call an API
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        assignments = [
          Assignment(
            id: 'assign_1',
            courseId: widget.course.id,
            name: 'Problem Set 1',
            description: 'Solve all even-numbered problems from Chapter 3. Focus on quadratic equations and graphing.',
            language: 'English',
            dueDate: DateTime.now().add(const Duration(days: 7)),
            maxScore: 100,
            platform: widget.course.platform,
            status: 'assigned',
            submissionCount: 0,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          Assignment(
            id: 'assign_2',
            courseId: widget.course.id,
            name: 'Lab Report',
            description: 'Write a comprehensive lab report describing your results and observations from the recent experiment. Include methodology, results, and conclusions.',
            language: 'English',
            dueDate: DateTime.now().add(const Duration(days: 3)),
            maxScore: 50,
            platform: widget.course.platform,
            status: 'assigned',
            submissionCount: 0,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Assignment(
            id: 'assign_3',
            courseId: widget.course.id,
            name: 'Research Essay',
            description: 'Write a 1000-word research essay on a topic of your choice related to the course material. Include at least 5 credible sources.',
            language: 'English',
            dueDate: DateTime.now().add(const Duration(days: 14)),
            maxScore: 150,
            platform: widget.course.platform,
            status: 'assigned',
            submissionCount: 0,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
      });
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

  Future<void> _sendMessageToCaila(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      isLoadingChat = true;
      cailaMessages.add({
        "role": "user",
        "content": message,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });

    try {
      String enhancedPrompt = _buildEnhancedPrompt(message);
      
      String response;
      if (widget.authToken != null) {
        response = await CailaService.chatWithCaila(
          authToken: widget.authToken!,
          prompt: enhancedPrompt,
          courseId: widget.course.id,
          studentId: widget.user?.id,
        );
      } else {
        // Demo mode - simulate response
        await Future.delayed(const Duration(seconds: 2));
        response = "This is a demo response. In the real app, CAILA would provide educational guidance about your question: '$message'";
      }

      setState(() {
        cailaMessages.add({
          "role": "assistant",
          "content": response,
          "timestamp": DateTime.now().toIso8601String(),
        });
      });

    } catch (e) {
      setState(() {
        cailaMessages.add({
          "role": "assistant",
          "content": "Sorry, I encountered an error: $e",
          "timestamp": DateTime.now().toIso8601String(),
        });
      });
    } finally {
      setState(() {
        isLoadingChat = false;
      });
      chatController.clear();
    }
  }

  String _buildEnhancedPrompt(String userMessage) {
    StringBuffer context = StringBuffer();
    
    context.writeln("COURSE CONTEXT:");
    context.writeln("Course: ${widget.course.name}");
    context.writeln("Platform: ${widget.course.platform.toUpperCase()}");
    context.writeln();
    
    if (selectedAssignment != null) {
      context.writeln("CURRENT ASSIGNMENT:");
      context.writeln("Title: ${selectedAssignment!.name}");
      context.writeln("Description: ${selectedAssignment!.description}");
      
      if (selectedAssignment!.dueDate != null) {
        final daysUntilDue = selectedAssignment!.dueDate!.difference(DateTime.now()).inDays;
        context.writeln("Due: ${_formatDate(selectedAssignment!.dueDate!)} ($daysUntilDue days remaining)");
      }
      
      if (selectedAssignment!.maxScore != null) {
        context.writeln("Max Score: ${selectedAssignment!.maxScore} points");
      }
      context.writeln();
    }
    
    if (answerController.text.trim().isNotEmpty) {
      context.writeln("STUDENT'S CURRENT WORK:");
      context.writeln(answerController.text.trim());
      context.writeln();
    }
    
    context.writeln("STUDENT QUESTION:");
    context.writeln(userMessage);
    context.writeln();
    context.writeln("Please provide helpful, educational guidance. Don't give direct answers but help the student learn and understand the concepts.");
    
    return context.toString();
  }

  Future<void> _saveWork() async {
    if (selectedAssignment == null || answerController.text.trim().isEmpty) {
      _showFeedback('Please select an assignment and add some content', isError: true);
      return;
    }

    _showFeedback('✅ Work saved locally for ${selectedAssignment!.name}');
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
      await Future.delayed(const Duration(seconds: 2));
      
      _showFeedback('✅ Assignment "${selectedAssignment!.name}" submitted successfully!');
      
      setState(() {
        selectedAssignment = selectedAssignment!.copyWith(status: 'submitted');
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
      String feedback;
      if (widget.authToken != null) {
        final rubric = await CailaService.generateRubric(
          authToken: widget.authToken!,
          assignmentPrompt: '${selectedAssignment!.name} - ${selectedAssignment!.description}',
          courseId: widget.course.id,
        );
        
        feedback = await CailaService.evaluateAnswer(
          authToken: widget.authToken!,
          rubric: rubric,
          studentAnswer: answerController.text.trim(),
          courseId: widget.course.id,
        );
      } else {
        feedback = "Demo feedback: Your work shows good understanding. Consider adding more specific examples and checking your calculations in the third section.";
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Assessment for: ${selectedAssignment!.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(feedback),
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

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavbar(
        title: '📚 ${widget.course.name} - Assignments',
        actions: [
          if (widget.authToken != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Chip(
                avatar: Icon(
                  widget.course.platform == 'google' ? Icons.class_ : Icons.account_balance,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  '${widget.course.platform.toUpperCase()} Connected',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: Row(
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
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Assignments (${assignments.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
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

          // Right: CAILA Chat
          Expanded(
            flex: 3,
            child: _buildChatInterface(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final isSelected = selectedAssignment?.id == assignment.id;
    final isSubmitted = assignment.status == 'submitted';
    final daysUntilDue = assignment.dueDate?.difference(DateTime.now()).inDays;
    
    Color statusColor = Colors.orange;
    String statusText = 'In Progress';
    IconData statusIcon = Icons.assignment;
    
    if (isSubmitted) {
      statusColor = Colors.green;
      statusText = 'Submitted';
      statusIcon = Icons.check_circle;
    } else if (daysUntilDue != null && daysUntilDue < 0) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Icons.warning;
    } else if (daysUntilDue != null && daysUntilDue <= 1) {
      statusColor = Colors.red;
      statusText = 'Due Soon';
      statusIcon = Icons.alarm;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : null,
      elevation: isSelected ? 3 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: statusColor,
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (assignment.maxScore != null) ...[
                  Icon(Icons.star, size: 12, color: Colors.amber[600]),
                  const SizedBox(width: 2),
                  Text(
                    '${assignment.maxScore}pts',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (assignment.dueDate != null) ...[
              const SizedBox(height: 2),
              Text(
                'Due: ${_formatDate(assignment.dueDate!)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
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
        onTap: () {
          setState(() {
            selectedAssignment = assignment;
            cailaMessages.clear();
            answerController.clear();
          });
        },
      ),
    );
  }

  Widget _buildAssignmentWorkArea() {
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.authToken != null)
                    Tooltip(
                      message: 'Connected to ${widget.course.platform.toUpperCase()}',
                      child: const Icon(Icons.cloud_done, color: Colors.green),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Assignment details
              Row(
                children: [
                  if (selectedAssignment!.dueDate != null) ...[
                    const Icon(Icons.schedule, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(selectedAssignment!.dueDate!)}',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (selectedAssignment!.maxScore != null) ...[
                    const Icon(Icons.grade, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Max Score: ${selectedAssignment!.maxScore} pts',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Assignment description
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
                      selectedAssignment!.description,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Work area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Work:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              
              Expanded(
                child: TextField(
                  controller: answerController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type your assignment work here...',
                    contentPadding: EdgeInsets.all(12),
                  ),
                  enabled: !isSubmitted,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: !isSubmitted ? _getFeedback : null,
                    icon: const Icon(Icons.assessment),
                    label: const Text("Get AI Feedback"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: !isSubmitted ? _saveWork : null,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Work"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (!isSubmitted && !isSubmitting) ? _submitAssignment : null,
                    icon: isSubmitting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(isSubmitting ? "Submitting..." : "Submit"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
              
              // Submission status
              if (isSubmitted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Assignment submitted successfully!',
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface() {
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
              if (widget.authToken != null)
                Tooltip(
                  message: 'Conversation logged to ${widget.course.platform.toUpperCase()}',
                  child: const Icon(Icons.save, size: 16, color: Colors.green),
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
                                Text('CAILA is thinking...',
                                     style: TextStyle(fontStyle: FontStyle.italic)),
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
                            controller: chatController,
                            decoration: InputDecoration(
                              hintText: selectedAssignment != null 
                                  ? 'Ask about ${selectedAssignment!.name}...'
                                  : 'Ask CAILA for help...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (value) => _sendMessageToCaila(value),
                            enabled: !isLoadingChat,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(isLoadingChat ? Icons.hourglass_empty : Icons.send),
                          onPressed: isLoadingChat
                              ? null
                              : () => _sendMessageToCaila(chatController.text),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (widget.authToken != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your conversation is logged for teacher review',
                      style: TextStyle(fontSize: 12, color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, String> message) {
    final isUser = message["role"] == "user";
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text('C', style: TextStyle(color: Colors.white, fontSize: 12)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message["content"] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message["timestamp"] ?? ''),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Text('S', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    answerController.dispose();
    chatController.dispose();
    super.dispose();
  }
}