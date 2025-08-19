// lib/features/grading/screens/grading_interface_screen.dart - Fixed layout
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../providers/course_provider.dart';
import '../providers/grading_provider.dart';
import '../../code_execution/providers/execution_provider.dart';
import '../../code_execution/models/execution_request.dart';
import '../../../shared/widgets/code_editor/code_editor.dart';
import '../../../shared/widgets/test_file_upload_widget.dart';
import '../widgets/grading_results_panel.dart';
import '../widgets/submission_list_panel.dart';
import '../widgets/grading_actions_panel.dart';
import '../widgets/course_assignment_selector.dart';

class GradingInterfaceScreen extends StatefulWidget {
  final Function(String)? onAssignmentSelected;
  final VoidCallback? onError;

  const GradingInterfaceScreen({
    super.key,
    this.onAssignmentSelected,
    this.onError,
  });

  @override
  State<GradingInterfaceScreen> createState() => _GradingInterfaceScreenState();
}

class _GradingInterfaceScreenState extends State<GradingInterfaceScreen> {
  bool _sidebarCollapsed = false;
  Map<String, dynamic> _testFiles = {};
  bool _useUploadedTestFiles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    try {
      // Load courses if not already loaded
      if (!courseProvider.hasCourses) {
        await courseProvider.loadCourses();
      }
    } catch (e) {
      _showError('Error loading initial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Sidebar
              AnimatedContainer(
                duration: AppConfig.getAnimationDuration(),
                width: _sidebarCollapsed ? 50 : 350,
                height: constraints.maxHeight,
                child: _buildSidebar(),
              ),
              
              // Main content area
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Row(
                    children: [
                      // Code editor
                      Expanded(
                        flex: 3,
                        child: _buildCodeEditorPanel(),
                      ),
                      
                      // Results panel
                      Expanded(
                        flex: 2,
                        child: _buildResultsPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.code, color: Colors.white),
          SizedBox(width: 8),
          Text('Code Grading Interface'),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        // Test file upload
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Consumer<CourseProvider>(
            builder: (context, courseProvider, child) {
              return TestFileUploadWidget(
                assignmentId: courseProvider.selectedAssignment?.id,
                onFilesChanged: _handleTestFilesChanged,
              );
            },
          ),
        ),
        
        // Run code button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Consumer2<ExecutionProvider, GradingProvider>(
            builder: (context, executionProvider, gradingProvider, child) {
              final hasSubmission = gradingProvider.selectedSubmission != null;
              final isLoading = executionProvider.isExecuting;
              
              return ElevatedButton.icon(
                onPressed: (hasSubmission && !isLoading) ? _runCode : null,
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 16),
                label: Text(
                  isLoading ? 'Running...' : 'Run',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(80, 32),
                ),
              );
            },
          ),
        ),
        
        // Health check button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Consumer<ExecutionProvider>(
            builder: (context, executionProvider, child) {
              return IconButton(
                onPressed: () => _checkBackendHealth(executionProvider),
                icon: const Icon(Icons.health_and_safety),
                tooltip: 'Check Backend Health',
              );
            },
          ),
        ),
        
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: _sidebarCollapsed ? _buildCollapsedSidebar() : _buildExpandedSidebar(),
    );
  }

  Widget _buildCollapsedSidebar() {
    return Column(
      children: [
        SizedBox(
          height: 50,
          width: 50,
          child: IconButton(
            onPressed: () {
              setState(() {
                _sidebarCollapsed = false;
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSidebar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grading Panel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sidebarCollapsed = true;
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Course and Assignment Dropdowns - Intrinsic height
          IntrinsicHeight(
            child: CourseAssignmentSelector(
              onCourseSelected: _onCourseSelected,
              onAssignmentSelected: _onAssignmentSelected,
            ),
          ),
          
          const SizedBox(height: 16),

          // Submissions list header
          const Text(
            'Submissions',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          
          // Submissions list - Takes flexible space
          Flexible(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const SubmissionListPanel(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Grading actions - Takes remaining space but with min constraints
          Flexible(
            flex: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                child: GradingActionsPanel(
                  isGradingEnabled: _isGradingEnabled,
                  testFiles: _testFiles,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEditorPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Code Editor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Selected submission info
                Consumer<GradingProvider>(
                  builder: (context, gradingProvider, child) {
                    final submission = gradingProvider.selectedSubmission;
                    if (submission != null) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.blue[600]),
                            const SizedBox(width: 4),
                            Text(
                              submission.studentName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Assignment info
                Consumer<CourseProvider>(
                  builder: (context, courseProvider, child) {
                    final assignment = courseProvider.selectedAssignment;
                    if (assignment != null) {
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment, size: 12, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text(
                              assignment.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          
          // Code editor
          Expanded(
            child: Consumer<GradingProvider>(
              builder: (context, gradingProvider, child) {
                final submission = gradingProvider.selectedSubmission;
                if (submission != null && submission.files.isNotEmpty) {
                  return CodeEditor(
                    files: submission.files,
                    readOnly: true,
                  );
                }
                
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.code_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Select a submission to view code',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose a course and assignment first',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: const GradingResultsPanel(),
    );
  }

  // Event handlers
  void _onCourseSelected(String courseId) {
    // Course selection is handled by the CourseAssignmentSelector
    // This is called for additional parent notification if needed
  }

  void _onAssignmentSelected(String assignmentId) {
    // Assignment selection is handled by the CourseAssignmentSelector
    // This calls the parent callback if provided
    widget.onAssignmentSelected?.call(assignmentId);
  }

  void _handleTestFilesChanged(Map<String, dynamic> files) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _testFiles = files;
          _useUploadedTestFiles = files['filesReady'] == true;
        });
        
        if (files['filesReady'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Test files ready: ${files['inputFilename']} → ${files['outputFilename']}'),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _runCode() async {
    final gradingProvider = Provider.of<GradingProvider>(context, listen: false);
    final executionProvider = Provider.of<ExecutionProvider>(context, listen: false);
    
    final submission = gradingProvider.selectedSubmission;
    if (submission == null || submission.files.isEmpty) {
      _showError('No code file selected to run');
      return;
    }

    try {
      final request = ExecutionRequest(
        language: submission.primaryLanguage,
        files: submission.files,
        testInput: _useUploadedTestFiles ? (_testFiles['inputContent'] ?? '') : '',
        expectedOutput: _useUploadedTestFiles ? (_testFiles['outputContent'] ?? '') : '',
        submissionId: submission.id,
      );

      final result = await executionProvider.executeCode(request);
      
      if (mounted) {
        String message = 'Code executed successfully!';
        Color backgroundColor = Colors.blue;
        
        if (result.testPassed) {
          message = 'Code executed - Test PASSED! ✅';
          backgroundColor = Colors.green;
        } else if (result.success && _useUploadedTestFiles) {
          message = 'Code executed - Test FAILED ❌';
          backgroundColor = Colors.orange;
        } else if (!result.success) {
          message = 'Code execution failed ❌';
          backgroundColor = Colors.red;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Execution failed: $e');
    }
  }

  Future<void> _checkBackendHealth(ExecutionProvider executionProvider) async {
    try {
      final isHealthy = await executionProvider.checkHealth();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(isHealthy ? 'Backend is healthy' : 'Backend issues detected'),
              ],
            ),
            backgroundColor: isHealthy ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Health check failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: AppConfig.getSnackbarDuration(),
      ),
    );
    
    widget.onError?.call();
  }

  bool get _isGradingEnabled {
    return _useUploadedTestFiles && 
           _testFiles['hasFiles'] == true &&
           _testFiles['inputContent'] != null && 
           _testFiles['inputContent'].toString().trim().isNotEmpty &&
           _testFiles['outputContent'] != null && 
           _testFiles['outputContent'].toString().trim().isNotEmpty;
  }
}