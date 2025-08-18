import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../apis/moodle_api.dart';
import '../components/app_navbar.dart';
import '../widgets/caila_history_panel.dart';
import '../widgets/caila_navigation.dart';
import '../widgets/caila_logs_panel.dart';
import '../widgets/assignment_preview.dart';
import '../widgets/material_configuration_bar.dart';
import '../widgets/caila_chat_interface.dart';
import '../services/caila_service.dart';
import '../services/google_classroom_service.dart';
import '../services/moodle_service.dart';
import '../services/auth_service.dart';
import '../constants/app_strings.dart';
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/user.dart';

class TeacherCailaScreen extends StatefulWidget {
  final String? authToken;
  final User? user;
  final List<Course>? courses;

  const TeacherCailaScreen({
    super.key,
    this.authToken,
    this.user,
    this.courses,
  });

  @override
  State<TeacherCailaScreen> createState() => _TeacherCailaScreenState();
}

class _TeacherCailaScreenState extends State<TeacherCailaScreen> {
  String selectedNavItem = 'generate';
  bool isNavCollapsed = false;

  List<Course> courses = [];
  List<Assignment> assignments = [];
  String? selectedCourseId;
  Assignment? selectedAssignment;

  String? selectedMaterialType;
  final TextEditingController chatController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  List<Map<String, String>> currentConversation = [];
  String? generatedMaterial;
  bool isLoading = false;
  bool isLoadingCourses = false;
  String? errorMessage;

  bool showAssignmentPreview = false;
  String? previewContent;
  String? previewMaterialType;
  String? previewTitle;

  bool isExporting = false;
  String? exportStatus;

  final AssignmentContextManager _contextManager = AssignmentContextManager();

  @override
  void initState() {
    super.initState();
    _initializeWithAuth();
  }

  void _initializeWithAuth() {
    if (widget.courses != null && widget.courses!.isNotEmpty) {
      setState(() {
        courses = widget.courses!;
      });
    } else {
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isLoggedIn || authService.currentUser == null || authService.jwt == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    setState(() {
      isLoadingCourses = true;
      errorMessage = null;
    });

    try {
      List<Course> loadedCourses = [];
      final user = authService.currentUser!;
      final jwt = authService.jwt!;

      if (user.lmsType.toString().contains('google')) {
        final googleService = GoogleClassroomService();
        loadedCourses = await googleService.getCourses();
      } else if (user.lmsType.toString().contains('moodle')) {
        final moodleService = MoodleService();
        loadedCourses = await moodleService.getCourses();
      } else {
        throw Exception('Unsupported LMS type: ${user.lmsType}');
      }
      
      setState(() {
        courses = loadedCourses;
        isLoadingCourses = false;
      });
      
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load courses: $e';
        isLoadingCourses = false;
      });
      
      if (mounted) {
        _showSnackBar(
          message: 'Failed to load courses: $e',
          isError: true,
          action: SnackBarAction(
            label: AppStrings.retryButton,
            textColor: Colors.white,
            onPressed: _loadCourses,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (chatController.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn || authService.jwt == null) {
      _showSnackBar(message: AppStrings.authenticationRequired, isError: true);
      return;
    }

    final userMessage = chatController.text.trim();
    
    final isRevisionRequest = CailaService.isRevisionRequest(userMessage) && _contextManager.hasContext;
    final isMaterialGeneration = CailaService.isMaterialGenerationRequest(userMessage) || selectedMaterialType != null;
    
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

    if (isMaterialGeneration || isRevisionRequest) {
      setState(() {
        currentConversation.add({
          'role': 'assistant',
          'content': isRevisionRequest 
              ? '🔄 ${AppStrings.revisingMaterial.replaceFirst('assignment', selectedMaterialType?.toLowerCase() ?? 'assignment')}\n\n${AppStrings.revisionSubtitle}'
              : '🎯 ${AppStrings.creatingMaterial.replaceFirst('material', selectedMaterialType?.toLowerCase() ?? 'material')}\n\n${AppStrings.progressSubtitle}',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    }

    try {
      String enhancedPrompt = userMessage;
      
      if (isRevisionRequest && _contextManager.hasContext) {
        enhancedPrompt = CailaService.buildRevisionPrompt(
          userMessage, 
          _contextManager.currentAssignmentContext!, 
          selectedMaterialType
        );
      } else if (selectedMaterialType != null) {
        enhancedPrompt = CailaService.enhancePromptForMaterialType(
          materialType: selectedMaterialType!,
          prompt: userMessage,
          courseContext: selectedCourseId != null 
              ? courses.firstWhere((c) => c.id == selectedCourseId).name
              : null,
        );
      }

      final response = await CailaService.chatWithCaila(
        authToken: authService.jwt!,
        prompt: enhancedPrompt,
        courseId: selectedCourseId,
        history: currentConversation.where((msg) => msg['role'] != 'user' || msg['content'] != userMessage).toList(),
      );

      setState(() {
        if ((isMaterialGeneration || isRevisionRequest) && currentConversation.isNotEmpty) {
          final lastMessage = currentConversation.last;
          if (lastMessage['content']?.contains('Creating your') == true || 
              lastMessage['content']?.contains('Revising your') == true) {
            currentConversation.removeLast();
          }
        }
        
        currentConversation.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        if (CailaService.isGeneratedMaterial(response)) {
          generatedMaterial = response;
          
          if (isRevisionRequest) {
            _contextManager.updateCurrentAssignment(response);
          } else {
            _contextManager.setNewAssignment(
              content: response, 
              materialType: selectedMaterialType!
            );
          }
          
          _showAssignmentPreview(response, selectedMaterialType!, titleController.text);
          
          _showSnackBar(
            message: isRevisionRequest 
                ? AppStrings.revisionCompleted
                : '✅ $selectedMaterialType ${AppStrings.materialGeneratedSuccessfully}',
            isError: false,
            action: SnackBarAction(
              label: AppStrings.viewPreview,
              textColor: Colors.white,
              onPressed: () {
                if (!showAssignmentPreview) {
                  setState(() {
                    showAssignmentPreview = true;
                  });
                }
              },
            ),
          );
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        if ((isMaterialGeneration || isRevisionRequest) && currentConversation.isNotEmpty) {
          final lastMessage = currentConversation.last;
          if (lastMessage['content']?.contains('Creating your') == true || 
              lastMessage['content']?.contains('Revising your') == true) {
            currentConversation.removeLast();
          }
        }
        
        currentConversation.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error: $e',
          'timestamp': DateTime.now().toIso8601String(),
        });
        errorMessage = e.toString();
        isLoading = false;
      });
      
      _showSnackBar(
        message: '❌ Error: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: AppStrings.retryButton,
          textColor: Colors.white,
          onPressed: () {
            chatController.text = userMessage;
            _sendMessage();
          },
        ),
      );
    }
  }

  void _showAssignmentPreview(String content, String materialType, String title) {
    setState(() {
      showAssignmentPreview = true;
      previewContent = content;
      previewMaterialType = materialType;
      previewTitle = title.isNotEmpty ? title : 'Generated $materialType';
    });
  }

  void _handleSectionEdit(String suggestion) {
    setState(() {
      chatController.text = suggestion;
    });
    
    FocusScope.of(context).requestFocus();
    
    _showSnackBar(
      message: AppStrings.revisionTip,
      isError: false,
      duration: const Duration(seconds: 3),
    );
  }

  void _showExportDialog() {
    if (previewContent == null || previewMaterialType == null) {
      _showSnackBar(
        message: 'No material available to export',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildExportDialog(),
    );
  }

  Widget _buildExportDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser!;
    final isGoogleUser = user.lmsType.toString().contains('google');
    final isMoodleUser = user.lmsType.toString().contains('moodle');
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.file_upload, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Export ${previewMaterialType ?? 'Material'}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how you\'d like to export "${previewTitle ?? 'your material'}"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            if (isGoogleUser) ...[
              _buildExportOption(
                icon: Icons.class_,
                title: 'Export to Google Classroom',
                subtitle: _getGoogleClassroomExportDescription(previewMaterialType ?? ''),
                onTap: () => _exportToGoogleClassroom(),
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
            ],
            
            if (isMoodleUser) ...[
              _buildExportOption(
                icon: Icons.account_balance,
                title: 'Export to Moodle',
                subtitle: _getMoodleExportDescription(previewMaterialType ?? ''),
                onTap: () => _exportToMoodle(),
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
            ],
            
            _buildExportOption(
              icon: Icons.download,
              title: 'Download to Computer',
              subtitle: 'Save as a text file on your device',
              onTap: () => _exportToComputer(),
              color: Colors.green,
            ),
            
            if (isExporting) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                exportStatus ?? 'Exporting...',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getMoodleExportDescription(String materialType) {
    switch (materialType.toLowerCase()) {
      case 'quiz':
      case 'assessment':
        return 'Create template with conversion guide for Moodle Quiz';
      case 'assignment':
      case 'homework':
      case 'essay':
        return 'Create template with conversion guide for Moodle Assignment';
      case 'rubric':
      case 'study guide':
      case 'lesson plan':
        return 'Create as course note with formatting guide';
      default:
        return 'Export to your Moodle course as formatted note';
    }
  }

  Future<void> _exportToMoodle() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isLoggedIn || authService.jwt == null) {
      _showSnackBar(message: AppStrings.authenticationRequired, isError: true);
      return;
    }

    if (selectedCourseId == null) {
      _showSnackBar(
        message: 'Please select a course first',
        isError: true,
      );
      return;
    }

    setState(() {
      isExporting = true;
      exportStatus = 'Preparing export to Moodle...';
    });

    try {
      final moodleApi = MoodleApi();
      
      setState(() {
        exportStatus = 'Creating ${previewMaterialType?.toLowerCase() ?? 'material'} in Moodle...';
      });

      final result = await moodleApi.exportMaterial(
        authToken: authService.jwt!,
        exportData: {
          'courseId': selectedCourseId!,
          'title': previewTitle!,
          'content': previewContent!,
          'materialType': previewMaterialType!,
          'exportType': 'note',
          'cailaGenerated': true,
          'generatedAt': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        isExporting = false;
        exportStatus = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          final noteId = result['noteId'];
          
          _showSnackBar(
            message: '✅ Successfully exported to Moodle!\n\n'
                    '💡 A template has been created in your course notes. '
                    'Follow the conversion guide to create the actual activity.',
            isError: false,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'View in Moodle',
              textColor: Colors.white,
              onPressed: () {
                _showConversionInstructions(noteId);
              },
            ),
          );
        } else {
          _showSnackBar(
            message: '❌ Export failed: ${result['error'] ?? 'Unknown error'}',
            isError: true,
            duration: const Duration(seconds: 8),
          );
        }
      }
    } catch (e) {
      setState(() {
        isExporting = false;
        exportStatus = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar(
          message: '❌ Export failed: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
          duration: const Duration(seconds: 8),
        );
      }
    }
  }

  void _showConversionInstructions(dynamic noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Next Steps'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your material has been exported as a course note. '
                'To convert it to a proper Moodle activity:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildInstructionStep('1', 'Go to your Moodle course'),
              _buildInstructionStep('2', 'Turn editing on'),
              _buildInstructionStep('3', 'Find your course notes section'),
              _buildInstructionStep('4', 'Follow the conversion guide in the note'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The note contains detailed instructions and formatted content ready to copy.',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getGoogleClassroomExportDescription(String materialType) {
    switch (materialType.toLowerCase()) {
      case 'quiz':
      case 'assessment':
        return 'Create as Google Form and link in assignment';
      case 'assignment':
      case 'homework':
      case 'essay':
        return 'Create as Google Classroom assignment';
      case 'rubric':
      case 'study guide':
      case 'lesson plan':
        return 'Share as classroom material';
      default:
        return 'Export to your Google Classroom';
    }
  }

  Future<void> _exportToGoogleClassroom() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isLoggedIn || authService.jwt == null) {
      _showSnackBar(message: AppStrings.authenticationRequired, isError: true);
      return;
    }

    if (selectedCourseId == null) {
      _showSnackBar(
        message: 'Please select a course first',
        isError: true,
      );
      return;
    }

    setState(() {
      isExporting = true;
      exportStatus = 'Preparing export to Google Classroom...';
    });

    try {
      final googleService = GoogleClassroomService();
      
      setState(() {
        exportStatus = 'Creating ${previewMaterialType?.toLowerCase() ?? 'material'} in Google Classroom...';
      });

      final result = await googleService.exportMaterial(
        authToken: authService.jwt!,
        courseId: selectedCourseId!,
        materialType: previewMaterialType!,
        title: previewTitle!,
        content: previewContent!,
        exportDestination: 'google_classroom',
        metadata: {
          'maxPoints': 100,
          'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
      );

      setState(() {
        isExporting = false;
        exportStatus = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          _showSnackBar(
            message: '✅ Successfully exported to Google Classroom!',
            isError: false,
            duration: const Duration(seconds: 5),
            action: result['alternateLink'] != null
                ? SnackBarAction(
                    label: 'View in Classroom',
                    textColor: Colors.white,
                    onPressed: () {
                      // Could open the link
                    },
                  )
                : null,
          );
        } else {
          _showSnackBar(
            message: '❌ Export failed: ${result['error'] ?? 'Unknown error'}',
            isError: true,
            duration: const Duration(seconds: 8),
          );
        }
      }
    } catch (e) {
      setState(() {
        isExporting = false;
        exportStatus = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar(
          message: '❌ Export failed: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
          duration: const Duration(seconds: 8),
        );
      }
    }
  }

  Future<void> _exportToComputer() async {
    setState(() {
      isExporting = true;
      exportStatus = 'Preparing download...';
    });

    try {
      final googleService = GoogleClassroomService();
      
      final result = await googleService.exportMaterial(
        authToken: '',
        courseId: '',
        materialType: previewMaterialType!,
        title: previewTitle!,
        content: previewContent!,
        exportDestination: 'computer',
      );

      setState(() {
        isExporting = false;
        exportStatus = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          _showSnackBar(
            message: '📁 File downloaded successfully!',
            isError: false,
            duration: const Duration(seconds: 3),
          );
        } else {
          _showSnackBar(
            message: '❌ Download failed: ${result['error'] ?? 'Unknown error'}',
            isError: true,
          );
        }
      }
    } catch (e) {
      setState(() {
        isExporting = false;
        exportStatus = null;
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar(
          message: '❌ Download failed: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleExportMaterial() async {
    _showExportDialog();
  }

  void _handleSaveDraft() {
    if (previewContent != null) {
      _showSnackBar(
        message: '💾 ${AppStrings.draftSaved}',
        isError: false,
      );
    }
  }

  void _performCompleteReset() {
    setState(() {
      _contextManager.clearContext();
      generatedMaterial = null;
      showAssignmentPreview = false;
      previewContent = null;
      previewMaterialType = null;
      previewTitle = null;
      
      selectedCourseId = null;
      selectedMaterialType = null;
      selectedAssignment = null;
      
      currentConversation.clear();
      
      isLoading = false;
      errorMessage = null;
      
      isExporting = false;
      exportStatus = null;
      
      chatController.clear();
      titleController.clear();
      
      selectedNavItem = 'generate';
      
      assignments.clear();
    });
    
    FocusScope.of(context).unfocus();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showSnackBar(
          message: '🔄 Everything has been reset! Ready to start fresh.',
          isError: false,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Got it',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        );
      }
    });
  }

  void _clearAssignmentContext() {
    _performCompleteReset();
  }

  void _handleMaterialTypeChange(String? newType) {
    if (_contextManager.shouldClearOnMaterialTypeChange(newType)) {
      _clearAssignmentContext();
    }
    setState(() {
      selectedMaterialType = newType;
      if (newType != null) {
        _contextManager.updateMaterialType(newType);
      }
    });
  }

  void _handleStartFresh() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('Start Fresh'),
          ],
        ),
        content: const Text(
          'This will clear all your current work including:\n\n'
          '• Generated materials\n'
          '• Chat conversation\n'
          '• Selected course and material type\n'
          '• Title and all form fields\n\n'
          'Are you sure you want to start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performCompleteReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar({
    required String message,
    required bool isError,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration ?? const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isLoggedIn || authService.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authService.currentUser!;
        final platform = user.lmsType.toString().split('.').last.toUpperCase();

        return Scaffold(
          appBar: AppNavbar(
            title: AppStrings.cailaAssistant,
            showUserMenu: true,
            onHomePressed: () => Navigator.of(context).pop(),
            actions: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Chip(
                  avatar: Icon(
                    user.lmsType.toString().contains('google') ? Icons.class_ : Icons.account_balance,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    '$platform ${AppStrings.platformConnected}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              CailaNavigationPanel(
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
              
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    switch (selectedNavItem) {
      case 'generate':
        return _buildMaterialGenerationView();
      case 'history':
        return _buildHistoryView();
      case 'logs':
        return _buildLogsView();
      default:
        return _buildMaterialGenerationView();
    }
  }

  Widget _buildMaterialGenerationView() {
    return Column(
      children: [
        MaterialConfigurationBar(
          courses: courses,
          isLoadingCourses: isLoadingCourses,
          errorMessage: errorMessage,
          selectedCourseId: selectedCourseId,
          selectedMaterialType: selectedMaterialType,
          titleController: titleController,
          generatedMaterial: generatedMaterial,
          showAssignmentPreview: showAssignmentPreview,
          currentAssignmentContext: _contextManager.currentAssignmentContext,
          onLoadCourses: _loadCourses,
          onCourseSelected: (courseId) {
            setState(() {
              selectedCourseId = courseId;
            });
          },
          onMaterialTypeSelected: _handleMaterialTypeChange,
          onStartFresh: _handleStartFresh,
          onExportMaterial: _handleExportMaterial,
          onSaveDraft: _handleSaveDraft,
          onTogglePreview: () {
            setState(() {
              showAssignmentPreview = !showAssignmentPreview;
            });
          },
          isLoading: isLoading,
        ),
        
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: showAssignmentPreview ? 60 : 100,
                child: CailaChatInterface(
                  chatController: chatController,
                  currentConversation: currentConversation,
                  selectedMaterialType: selectedMaterialType,
                  currentAssignmentContext: _contextManager.currentAssignmentContext,
                  isLoading: isLoading,
                  onSendMessage: _sendMessage,
                ),
              ),
              
              if (showAssignmentPreview && previewContent != null)
                Expanded(
                  flex: 40,
                  child: Container(
                    margin: const EdgeInsets.only(left: 16),
                    child: AssignmentPreview(
                      content: previewContent!,
                      materialType: previewMaterialType ?? 'Material',
                      title: previewTitle ?? 'Generated Material',
                      platform: Provider.of<AuthService>(context, listen: false)
                          .currentUser!.lmsType.toString().contains('google') 
                          ? 'google' : 'moodle',
                      onSectionEdit: _handleSectionEdit,
                      onSave: _handleSaveDraft,
                      onExport: _handleExportMaterial,
                      isVisible: showAssignmentPreview,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView() {
    return CailaHistoryPanel(
      authToken: Provider.of<AuthService>(context, listen: false).jwt,
      onResumeSession: _handleResumeSession,
    );
  }

  void _handleResumeSession(List<Map<String, String>> conversationHistory, String? courseId) {
    String? detectedMaterial;
    String? detectedMaterialType;
    String? detectedTitle;

    setState(() {
      selectedNavItem = 'generate';
      
      if (courseId != null) {
        selectedCourseId = courseId;
      }
      
      currentConversation.clear();
      currentConversation.addAll(conversationHistory);
      
      for (int i = conversationHistory.length - 1; i >= 0; i--) {
        final message = conversationHistory[i];
        if (message['role'] == 'assistant') {
          final content = message['content'] ?? '';
          if (CailaService.isGeneratedMaterial(content)) {
            detectedMaterial = content;
            
            detectedMaterialType = _detectMaterialTypeFromContent(content);
            detectedTitle = _extractTitleFromContent(content);
            
            _contextManager.setNewAssignment(
              content: content,
              materialType: detectedMaterialType ?? 'Material',
            );
            
            break;
          }
        }
      }
      
      if (detectedMaterial != null) {
        generatedMaterial = detectedMaterial;
        selectedMaterialType = detectedMaterialType;
        if (detectedTitle != null && detectedTitle!.isNotEmpty) {
          titleController.text = detectedTitle!;
        }
        
        _showAssignmentPreview(
          detectedMaterial!, 
          detectedMaterialType ?? 'Material', 
          detectedTitle ?? 'Resumed Material'
        );
      }
      
      FocusScope.of(context).requestFocus();
    });
    
    _showSnackBar(
      message: detectedMaterial != null 
          ? '✅ Session resumed with latest generated material loaded!'
          : '✅ Session resumed! Continue your conversation.',
      isError: false,
    );
  }
  
  String? _detectMaterialTypeFromContent(String content) {
    final lowerContent = content.toLowerCase();
    
    final materialTypes = {
      'quiz': ['quiz', 'assessment', 'test', 'questions', 'multiple choice', 'true/false', 'short answer'],
      'assignment': ['assignment', 'homework', 'task', 'project instructions', 'complete the following'],
      'lesson plan': ['lesson plan', 'lesson', 'teaching plan', 'learning objectives', 'class activity'],
      'worksheet': ['worksheet', 'practice', 'exercise', 'problems', 'complete each'],
      'essay': ['essay', 'writing prompt', 'composition', 'write about', 'discuss', 'analyze'],
      'project': ['project', 'project instructions', 'create a', 'build', 'design'],
      'rubric': ['rubric', 'grading criteria', 'assessment criteria', 'points', 'excellent', 'good', 'needs improvement'],
      'study guide': ['study guide', 'review', 'summary', 'key concepts', 'important terms'],
    };

    Map<String, int> scores = {};
      
    for (final entry in materialTypes.entries) {
      final type = entry.key;
      final keywords = entry.value;
      int score = 0;
      
      for (final keyword in keywords) {
        if (lowerContent.contains(keyword)) {
          score += keyword.split(' ').length;
        }
      }
      
      if (score > 0) {
        scores[type] = score;
      }
    }
    
    if (scores.isNotEmpty) {
      final bestMatch = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
      return bestMatch.key.split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
    }
    
    return null;
  }
  
  String? _extractTitleFromContent(String content) {
    final titlePatterns = [
      RegExp(r'^(.+?Assignment.*?)(?:\n|$)', multiLine: true),
      RegExp(r'^(.+?Quiz.*?)(?:\n|$)', multiLine: true),
      RegExp(r'^(.+?Worksheet.*?)(?:\n|$)', multiLine: true),
      RegExp(r'^(.+?Lesson.*?)(?:\n|$)', multiLine: true),
      RegExp(r'^#\s+(.+?)(?:\n|$)', multiLine: true),
      RegExp(r'^##\s+(.+?)(?:\n|$)', multiLine: true),
      RegExp(r'^\*\*(.+?)\*\*(?:\n|$)', multiLine: true),
      RegExp(r'^Title:\s*(.+?)(?:\n|$)', multiLine: true, caseSensitive: false),
    ];
    
    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        String title = match.group(1)?.trim() ?? '';
        title = title.replaceFirst(RegExp(r'^#+\s*'), '');
        title = title.replaceAll('**', '');
        title = title.replaceFirst(RegExp(r'^(Title):\s*', caseSensitive: false), '');
        if (title.isNotEmpty && title.length < 100) {
          return title;
        }
      }
    }
    
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.length > 5 && trimmedLine.length < 100 && 
          !trimmedLine.contains('.') && 
          !trimmedLine.startsWith('*') &&
          !trimmedLine.startsWith('-') &&
          !trimmedLine.startsWith('1.') &&
          !trimmedLine.toLowerCase().contains('objective') &&
          !trimmedLine.toLowerCase().contains('instruction')) {
        final lowerLine = trimmedLine.toLowerCase();
        if (lowerLine.contains('grade') || lowerLine.contains('quiz') || 
            lowerLine.contains('assignment') || lowerLine.contains('lesson') ||
            lowerLine.contains('worksheet') || lowerLine.contains('project') ||
            lowerLine.contains('essay') || lowerLine.contains('study')) {
          return trimmedLine;
        }
      }
    }
    
    return null;
  }

  Widget _buildLogsView() {
    return CailaLogsPanel(
      authToken: Provider.of<AuthService>(context, listen: false).jwt,
      courses: courses,
      selectedCourseId: selectedCourseId,
      onCourseSelected: (courseId) {
        setState(() {
          selectedCourseId = courseId;
        });
      },
    );
  }

  @override
  void dispose() {
    chatController.dispose();
    titleController.dispose();
    super.dispose();
  }
}