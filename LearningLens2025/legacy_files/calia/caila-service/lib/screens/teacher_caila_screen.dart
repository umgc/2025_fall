import 'package:flutter/material.dart';
import '../components/app_navbar.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/header.dart';
import '../widgets/logs_panel.dart';
import '../widgets/submission_panel.dart';
import '../services/caila_service.dart';
import '../services/google_classroom_service.dart';
import '../services/moodle_service.dart';
import '../models/course.dart';
import '../models/assignment.dart';
import '../constants/app_strings.dart';

class TeacherCailaScreen extends StatefulWidget {
  const TeacherCailaScreen({super.key});

  @override
  State<TeacherCailaScreen> createState() => _TeacherCailaScreenState();
}

class _TeacherCailaScreenState extends State<TeacherCailaScreen> {
  // Navigation state
  String selectedNavItem = 'generate';
  bool isNavCollapsed = false;

  // Authentication state (would be injected from external auth system)
  String? authToken;
  String? userPlatform;
  String? userId;
  String? userName;

  // Data state
  List<Course> courses = [];
  List<Assignment> assignments = [];
  String? selectedCourseId;
  Assignment? selectedAssignment;

  // Material generation state
  String? selectedMaterialType;
  final TextEditingController chatController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  List<Map<String, String>> currentConversation = [];
  String? generatedMaterial;
  bool isLoading = false;
  String? errorMessage;

  // Available material types
  final List<String> materialTypes = [
    'Assignment',
    'Quiz',
    'Lesson Plan',
    'Rubric',
    'Worksheet',
    'Project Instructions',
    'Study Guide',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWithExternalAuth();
  }

  // This method would be called by the external authentication system
  void _initializeWithExternalAuth() {
    // For now, using placeholder data
    // In real implementation, this would receive auth data from external system
    setState(() {
      authToken = 'placeholder_token';
      userPlatform = 'google'; // or 'moodle'
      userId = 'teacher_123';
      userName = 'Dr. Smith';
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (authToken == null) return;

    try {
      // Load courses - this would come from the external auth system
      // For now, using placeholder data
      setState(() {
        courses = [
          Course(
            id: 'course_1',
            name: 'Computer Science 101',
            description: 'Introduction to Programming',
            platform: userPlatform!,
            instructor: userName!,
            enrollmentCount: 25,
            createdAt: DateTime.now(),
          ),
          Course(
            id: 'course_2',
            name: 'Data Structures',
            description: 'Advanced Data Structures and Algorithms',
            platform: userPlatform!,
            instructor: userName!,
            enrollmentCount: 18,
            createdAt: DateTime.now(),
          ),
        ];
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load initial data: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    if (chatController.text.trim().isEmpty || authToken == null) return;

    final userMessage = chatController.text.trim();
    setState(() {
      currentConversation.add({
        'role': 'user',
        'content': userMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
      isLoading = true;
      errorMessage = null;
    });

    chatController.clear();

    try {
      String enhancedPrompt = userMessage;
      
      // Enhance prompt if material type is selected
      if (selectedMaterialType != null) {
        enhancedPrompt = CailaService.enhancePromptForMaterialType(
          materialType: selectedMaterialType!,
          prompt: userMessage,
          courseContext: selectedCourseId != null 
              ? courses.firstWhere((c) => c.id == selectedCourseId).name
              : null,
        );
      }

      final response = await CailaService.chatWithCaila(
        authToken: authToken!,
        prompt: enhancedPrompt,
        courseId: selectedCourseId,
        history: currentConversation.where((msg) => msg['role'] != 'user' || msg['content'] != userMessage).toList(),
      );

      setState(() {
        currentConversation.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Check if this looks like generated material
        if (_isGeneratedMaterial(response)) {
          generatedMaterial = response;
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        currentConversation.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error: $e',
          'timestamp': DateTime.now().toIso8601String(),
        });
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  bool _isGeneratedMaterial(String content) {
    // Simple heuristic to detect if content looks like educational material
    return content.length > 200 && 
           (content.contains('**') || 
            content.contains('##') || 
            content.toLowerCase().contains('objective') ||
            content.toLowerCase().contains('instruction') ||
            content.toLowerCase().contains('question'));
  }

  Future<void> _exportMaterial() async {
    if (generatedMaterial == null || authToken == null) return;

    try {
      setState(() => isLoading = true);

      if (userPlatform == 'google') {
        await _exportToGoogle();
      } else if (userPlatform == 'moodle') {
        await _exportToMoodle();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _exportToGoogle() async {
    if (selectedMaterialType?.toLowerCase() == 'quiz') {
      final questions = GoogleClassroomService.parseQuizContent(generatedMaterial!);
      await GoogleClassroomService.createGoogleForm(
        authToken: authToken!,
        title: titleController.text.isNotEmpty 
            ? titleController.text 
            : '$selectedMaterialType - ${selectedCourseId != null ? courses.firstWhere((c) => c.id == selectedCourseId).name : "Course"}',
        description: 'Generated by CAILA AI Assistant',
        questions: questions,
      );
    } else {
      await GoogleClassroomService.createClassroomAssignment(
        authToken: authToken!,
        courseId: selectedCourseId ?? courses.first.id,
        title: titleController.text.isNotEmpty 
            ? titleController.text 
            : '$selectedMaterialType - ${courses.first.name}',
        description: generatedMaterial!,
      );
    }
  }

  Future<void> _exportToMoodle() async {
    await MoodleService.exportMaterial(
      authToken: authToken!,
      courseId: selectedCourseId ?? courses.first.id,
      title: titleController.text.isNotEmpty 
          ? titleController.text 
          : '$selectedMaterialType - ${courses.first.name}',
      content: generatedMaterial!,
      materialType: selectedMaterialType ?? 'Material',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavbar(
        title: AppStrings.teacherDashboard,
        actions: [
          if (userName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    userPlatform == 'google' ? Icons.class_ : Icons.account_balance,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userName!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Navigation Panel
          NavigationPanel(
            selectedItem: selectedNavItem,
            onItemSelected: (item) {
              setState(() {
                selectedNavItem = item;
                errorMessage = null;
              });
            },
            isCollapsed: isNavCollapsed,
            onToggleCollapse: () {
              setState(() {
                isNavCollapsed = !isNavCollapsed;
              });
            },
          ),
          
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (selectedNavItem) {
      case 'generate':
        return _buildMaterialGenerationView();
      case 'chat':
        return _buildChatView();
      case 'history':
        return _buildHistoryView();
      case 'logs':
        return _buildLogsView();
      case 'materials':
        return _buildMaterialsView();
      default:
        return _buildMaterialGenerationView();
    }
  }

  Widget _buildMaterialGenerationView() {
    return Column(
      children: [
        Header(
          title: AppStrings.materialGenerator,
          subtitle: 'Create educational materials with CAILA AI',
          actions: [
            if (generatedMaterial != null)
              ElevatedButton.icon(
                onPressed: isLoading ? null : _exportMaterial,
                icon: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(isLoading ? 'Exporting...' : 'Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Left Panel - Configuration
                Expanded(
                  flex: 2,
                  child: _buildConfigurationPanel(),
                ),
                
                const SizedBox(width: 24),
                
                // Right Panel - Chat Interface
                Expanded(
                  flex: 3,
                  child: _buildChatInterface(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationPanel() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Material Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Course Selection
            DropdownButtonFormField<String>(
              value: selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Select Course',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: courses.map((course) {
                return DropdownMenuItem<String>(
                  value: course.id,
                  child: Text(course.name),
                );
              }).toList(),
              onChanged: (courseId) {
                setState(() {
                  selectedCourseId = courseId;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Material Type Selection
            DropdownButtonFormField<String>(
              value: selectedMaterialType,
              decoration: const InputDecoration(
                labelText: 'Material Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: materialTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (type) {
                setState(() {
                  selectedMaterialType = type;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Title Input
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Material Title (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (selectedCourseId != null && selectedMaterialType != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ready to create ${selectedMaterialType!.toLowerCase()} for ${courses.firstWhere((c) => c.id == selectedCourseId).name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const Spacer(),
            
            if (generatedMaterial != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Generated Material Ready',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  '✅ Your ${selectedMaterialType?.toLowerCase() ?? 'material'} has been generated and is ready for export!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Chat with CAILA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                const Spacer(),
                if (selectedMaterialType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Creating: ${selectedMaterialType!}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: currentConversation.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Start chatting with CAILA!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedMaterialType != null
                                ? 'Ask me to create a ${selectedMaterialType!.toLowerCase()} or ask questions about it'
                                : 'Select a material type and ask me to create educational content',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentConversation.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == currentConversation.length && isLoading) {
                          return _buildLoadingMessage();
                        }
                        return _buildChatMessage(currentConversation[index]);
                      },
                    ),
            ),
          ),
          
          // Chat Input
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
                    decoration: InputDecoration(
                      hintText: selectedMaterialType != null
                          ? 'Ask me to create a ${selectedMaterialType!.toLowerCase()}...'
                          : 'Ask CAILA to help create educational materials...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !isLoading,
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
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
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final isGeneratedMaterial = !isUser && _isGeneratedMaterial(message['content'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
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
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.purple[100] 
                    : isGeneratedMaterial 
                        ? Colors.green[50]
                        : Colors.grey[200],
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
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.purple[700] : Colors.black87,
                      fontFamily: isGeneratedMaterial ? 'monospace' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message['timestamp'] ?? ''),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.purple[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'CAILA is thinking...',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        const Header(
          title: 'Chat with CAILA',
          subtitle: 'General conversation with the AI assistant',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildChatInterface(),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        const Header(
          title: AppStrings.chatHistory,
          subtitle: 'Your previous conversations with CAILA',
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chat History',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your conversation history will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogsView() {
    return LogsPanel(
      authToken: authToken,
      courses: courses,
      selectedCourseId: selectedCourseId,
      onCourseSelected: (courseId) {
        setState(() {
          selectedCourseId = courseId;
        });
      },
    );
  }

  Widget _buildMaterialsView() {
    return Column(
      children: [
        const Header(
          title: 'My Materials',
          subtitle: 'Generated educational materials',
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'My Materials',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your generated materials will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  @override
  void dispose() {
    chatController.dispose();
    titleController.dispose();
    super.dispose();
  }
}