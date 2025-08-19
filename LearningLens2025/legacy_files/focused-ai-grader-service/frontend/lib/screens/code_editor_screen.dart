// lib/screens/enhanced_code_editor_screen.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/submission.dart';
import '../services/enhanced_grading_service.dart';
import '../services/google_auth_helper.dart';
import '../services/code_execution_service.dart';
import '../services/batch_execution_service.dart';
import '../widgets/enhanced_code_editor.dart';
import '../widgets/batch_results_dialog.dart';
import '../models/batch_execution_result.dart' as batch_models;
import '../models/enhanced_batch_result.dart';

class EnhancedCodeEditorScreen extends StatefulWidget {
  const EnhancedCodeEditorScreen({super.key});

  @override
  State<EnhancedCodeEditorScreen> createState() => _EnhancedCodeEditorScreenState();
}

class _EnhancedCodeEditorScreenState extends State<EnhancedCodeEditorScreen> {
  final EnhancedGradingService _gradingService = EnhancedGradingService();
  
  // Platform and authentication state
  String _selectedPlatform = 'moodle';
  bool _isAuthenticated = false;
  String? _selectedMoodleUser;
  
  // Data state
  List<Course> _courses = [];
  List<Assignment> _assignments = [];
  List<StudentSubmission> _submissions = [];
  
  // Selection state
  Course? _selectedCourse;
  Assignment? _selectedAssignment;
  StudentSubmission? _selectedSubmission;
  
  // UI state
  bool _isLoading = false;
  bool _isPanelCollapsed = false;
  String _currentCode = '';
  String _gradeInput = '';
  String _feedbackInput = '';
  String? _errorMessage;

  // Batch processing state
  bool _isBatchProcessing = false;
  batch_models.BatchExecutionResult? _lastBatchResult;

  // Individual execution result state
  CodeExecutionResult? _individualExecutionResult;
  bool _isIndividualExecuting = false;

  // ============ HELPER METHODS (MOVED TO TOP) ============
  
  String _getLanguageFromFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'py': return 'Python';
      case 'js': return 'JavaScript';
      case 'java': return 'Java';
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'c': return 'C++';
      default: return 'Unknown';
    }
  }

  Widget _getLanguageIcon(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return const Icon(Icons.code, color: Colors.blue, size: 16);
      case 'javascript':
        return const Icon(Icons.javascript, color: Colors.yellow, size: 16);
      case 'java':
        return const Icon(Icons.coffee, color: Colors.orange, size: 16);
      case 'c++':
        return const Icon(Icons.memory, color: Colors.purple, size: 16);
      default:
        return const Icon(Icons.code, color: Colors.grey, size: 16);
    }
  }

  void _selectSubmissionById(String submissionId) {
    final submission = _submissions.firstWhere(
      (s) => s.id == submissionId,
      orElse: () => _submissions.first,
    );
    _loadSubmissionContent(submission);
  }

  // ============ DIALOG METHODS (MOVED TO TOP) ============

  Future<bool> _showBatchExecutionDialog() async {
    final languageGroups = <String, int>{};
    
    // Group submissions by language
    for (final submission in _submissions) {
      final language = _getLanguageFromFilename(submission.filename);
      languageGroups[language] = (languageGroups[language] ?? 0) + 1;
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled, color: Colors.green),
            SizedBox(width: 8),
            Text('Execute All Submissions'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will execute all ${_submissions.length} submissions in parallel using AWS Lambda functions.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Submissions by language:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...languageGroups.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    _getLanguageIcon(entry.key),
                    const SizedBox(width: 8),
                    Text('${entry.key}: ${entry.value} submissions'),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Execution Details:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Cold start: 2-30 seconds per language'),
                    Text('• Warm execution: <1 second per submission'),
                    Text('• Parallel processing for faster results'),
                    Text('• Results will be displayed when complete'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context, false);
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Execute All', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showBatchResultsDialog(batch_models.BatchExecutionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatchResultsDialog(
        result: result,
        submissions: _submissions,
        assignment: _selectedAssignment, // ✅ Pass the assignment
        courseId: _selectedCourse?.id,   // ✅ Pass the course ID
        gradingService: _gradingService, // ✅ Pass the grading service
        onViewSubmission: (submissionId) {
          Navigator.pop(context);
          _selectSubmissionById(submissionId);
        },
        onClose: () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showGradingErrorDialog(String error, String grade, String feedback, CodeExecutionResult executionResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Cannot Submit Grade to Classroom'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error.contains('ProjectPermissionDenied')) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Why can\'t I grade this assignment?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('This assignment was created manually in Google Classroom, not through this app.'),
                      SizedBox(height: 8),
                      Text('🔒 Google Classroom Rule: You can only grade assignments created by the same app.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '💡 Solutions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Create new assignments using the "Create Assignment" button'),
                const Text('2. Save the grade locally in this app'),
                const Text('3. Manually enter grades in Google Classroom'),
              ] else ...[
                Text('Error: $error'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (mounted) Navigator.pop(context);
              _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: true);
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Grade Locally'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          if (error.contains('ProjectPermissionDenied'))
            ElevatedButton.icon(
              onPressed: () {
                if (mounted) Navigator.pop(context);
                if (mounted) Navigator.pop(context);
                _showCreateAssignmentInfo();
              },
              icon: const Icon(Icons.add),
              label: const Text('Learn About Creating Assignments'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
        ],
      ),
    );
  }

  Future<void> _handleGradeSubmissionError(String error, String grade, String feedback, CodeExecutionResult executionResult) async {
    print('❌ Grade submission error: $error');
    
    // Determine error type and show appropriate dialog
    if (error.contains('Authentication expired') || error.contains('401')) {
      _showAuthenticationErrorDialog(error, grade, feedback, executionResult);
    } else if (error.contains('Insufficient Permissions') || error.contains('Permission')) {
      _showPermissionErrorDialog(error, grade, feedback, executionResult);
    } else if (error.contains('Resource Not Found') || error.contains('404')) {
      _showResourceNotFoundDialog(error, grade, feedback, executionResult);
    } else if (error.contains('Conflict') || error.contains('409')) {
      _showConflictErrorDialog(error, grade, feedback, executionResult);
    } else {
      _showGenericGradingErrorDialog(error, grade, feedback, executionResult);
    }
  }

  /// Show authentication error dialog
  void _showAuthenticationErrorDialog(String error, String grade, String feedback, CodeExecutionResult executionResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Authentication Required'),
          ],
        ),
        content: const SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Google Classroom session has expired.'),
              SizedBox(height: 16),
              Text('To submit grades, you need to:'),
              Text('• Sign out and sign in again'),
              Text('• Grant all required permissions'),
              Text('• Ensure stable internet connection'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: true);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Locally'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _forceReAuthentication();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Re-authenticate'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  /// Show permission error dialog
  void _showPermissionErrorDialog(String error, String grade, String feedback, CodeExecutionResult executionResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 8),
            Text('Permission Error'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('There was a permission issue submitting the grade.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Possible causes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Missing required OAuth scopes'),
                    const Text('• Assignment grading is restricted'),
                    const Text('• Course permissions limit access'),
                    const Text('• Temporary Google Classroom issue'),
                    const SizedBox(height: 12),
                    Text(
                      'Technical details: $error',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: true);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Locally'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _testAssignmentGradingCapability();
            },
            icon: const Icon(Icons.bug_report),
            label: const Text('Debug Issue'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _requestFullPermissions();
            },
            icon: const Icon(Icons.security),
            label: const Text('Fix Permissions'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  /// Show resource not found dialog
  void _showResourceNotFoundDialog(String error, String grade, String feedback, CodeExecutionResult executionResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Resource Not Found'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The assignment or submission could not be found.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This could mean:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• The assignment was deleted or archived'),
                    const Text('• The submission was removed'),
                    const Text('• You lost access to the course'),
                    const Text('• There was a synchronization issue'),
                    const SizedBox(height: 12),
                    Text(
                      'Error details: $error',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: true);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Locally'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _refreshAssignmentData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  /// Show conflict error dialog
  void _showConflictErrorDialog(String error, String grade, String feedback, CodeExecutionResult executionResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Submission Conflict'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('There was a conflict with the submission state.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This might happen when:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• The submission was already graded'),
                    const Text('• Another teacher is grading simultaneously'),
                    const Text('• The assignment state changed'),
                    const Text('• There was a timing issue'),
                    const SizedBox(height: 12),
                    Text(
                      'Details: $error',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: true);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Locally'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _retryGradeSubmission(grade, feedback, executionResult);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  /// Show generic grading error dialog
  void _showGenericGradingErrorDialog(String error, String grade, String feedback, CodeExecutionResult executionResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Grade Submission Failed'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('An unexpected error occurred while submitting the grade.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error details:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: true);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Locally'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _debugGradingIssue();
            },
            icon: const Icon(Icons.bug_report),
            label: const Text('Debug'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGradeToClassroom(
    String gradeText,
    String feedback,
    CodeExecutionResult executionResult,
    {required bool saveOnly}
  ) async {
    // Add comprehensive null checks
    if (_selectedSubmission == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No submission selected'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_selectedAssignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assignment selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No course selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for required IDs
    final submissionId = _selectedSubmission!.id;
    if (submissionId == null || submissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final grade = double.tryParse(gradeText);
      if (grade == null) {
        throw Exception('Invalid grade value');
      }

      if (grade < 0 || grade > (_selectedAssignment!.maxScore)) {
        throw Exception('Grade must be between 0 and ${_selectedAssignment!.maxScore}');
      }

      if (saveOnly) {
        // Just save locally
        setState(() {
          _selectedSubmission = StudentSubmission(
            id: _selectedSubmission!.id,
            studentId: _selectedSubmission!.studentId,
            studentName: _selectedSubmission!.studentName,
            filename: _selectedSubmission!.filename,
            code: _selectedSubmission!.code,
            assignmentId: _selectedSubmission!.assignmentId,
            submittedAt: _selectedSubmission!.submittedAt,
            status: 'graded',
            fileSize: _selectedSubmission!.fileSize,
            fileExtension: _selectedSubmission!.fileExtension,
            gradeId: 'local_grade_${DateTime.now().millisecondsSinceEpoch}',
            uploadedAt: _selectedSubmission!.uploadedAt,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grade saved locally: ${grade}/${_selectedAssignment!.maxScore}'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // Submit to Google Classroom - ENHANCED VERSION
        if (_selectedPlatform != 'classroom') {
          throw Exception('Google Classroom integration only available when using Classroom platform');
        }

        // Show loading indicator
        setState(() {
          _isLoading = true;
        });

        try {
          // ✅ ENHANCED: Try submitting the grade regardless of assignment origin
          print('🎓 Attempting to submit grade to Google Classroom...');
          print('   Course: ${_selectedCourse!.id}');
          print('   Assignment: ${_selectedAssignment!.id}');
          print('   Submission: $submissionId');
          print('   Grade: $grade/${_selectedAssignment!.maxScore}');

          await _gradingService.submitGradeToClassroom(
            courseId: _selectedCourse!.id,
            assignmentId: _selectedAssignment!.id,
            submissionId: submissionId,
            studentId: _selectedSubmission!.studentId,
            grade: grade,
            feedback: feedback,
          );

          setState(() {
            _isLoading = false;
            // Update submission status
            _selectedSubmission = StudentSubmission(
              id: _selectedSubmission!.id,
              studentId: _selectedSubmission!.studentId,
              studentName: _selectedSubmission!.studentName,
              filename: _selectedSubmission!.filename,
              code: _selectedSubmission!.code,
              assignmentId: _selectedSubmission!.assignmentId,
              submittedAt: _selectedSubmission!.submittedAt,
              status: 'graded',
              fileSize: _selectedSubmission!.fileSize,
              fileExtension: _selectedSubmission!.fileExtension,
              gradeId: 'classroom_grade_${DateTime.now().millisecondsSinceEpoch}',
              uploadedAt: _selectedSubmission!.uploadedAt,
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Grade submitted to Google Classroom: ${grade}/${_selectedAssignment!.maxScore}'),
              backgroundColor: Colors.green,
            ),
          );

        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          
          // ✅ ENHANCED ERROR HANDLING
          await _handleGradeSubmissionError(e.toString(), gradeText, feedback, executionResult);
        }
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit grade: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  void initState() {
    super.initState();
    _initializePlatform();
  }

  void _initializePlatform() {
    _gradingService.setPlatform(_selectedPlatform);
  }

  void _safeSetState(VoidCallback fn) {
  if (mounted) {
    setState(fn);
  }
}

  void _safeShowSnackBar(String message, {Color? backgroundColor}) {
  if (mounted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

  void _safeNavigatorPop() {
    if (mounted && context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ============ AUTHENTICATION ============

  Future<void> _authenticateMoodle() async {
    if (_selectedMoodleUser == null) {
      setState(() {
        _errorMessage = 'Please select a Moodle user';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _gradingService.authenticateMoodle(_selectedMoodleUser!);
      setState(() {
        _isAuthenticated = success;
        _isLoading = false;
      });

      if (success) {
        await _loadCourses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully authenticated with Moodle')),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to authenticate with Moodle';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication error: $e';
      });
    }
  }

  Future<void> _authenticateGoogleClassroom() async {
  print('🔐 Starting Google Classroom authentication...');
  
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final accessToken = await SimpleGoogleAuth.signIn();
    
    if (accessToken != null) {
      print('🔐 Received token from Google Auth: ${accessToken.substring(0, 20)}...');
      
      // ✅ CRITICAL: Set the token in the grading service IMMEDIATELY
      _gradingService.setGoogleAccessToken(accessToken);
      
      // ✅ NEW: Verify the token was set correctly
      final serviceStatus = await _gradingService.getAuthenticationStatus();
      print('🔍 Service token status after setting: ${serviceStatus['googleAuthenticated']}');
      print('🔍 Service token length: ${serviceStatus['googleTokenLength']}');
      
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
      
      // ✅ CRITICAL: Load courses immediately after authentication
      print('📚 Loading courses after authentication...');
      await _loadCourses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully authenticated with Google Classroom')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to authenticate with Google Classroom';
      });
    }
  } catch (e) {
    print('❌ Authentication error: $e');
    setState(() {
      _isLoading = false;
      _errorMessage = 'Authentication error: $e';
    });
  }
}

  // Add this method to debug your current token permissions
  Future<void> _checkTokenScopes() async {
    if (SimpleGoogleAuth.accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=${SimpleGoogleAuth.accessToken}'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('=== CURRENT TOKEN SCOPES ===');
          print('Scopes: ${data['scope']}');
          print('Audience: ${data['audience']}');
          print('Expires in: ${data['expires_in']} seconds');
          
          // Check if we have the right scopes
          final scopes = data['scope'].toString();
          print('Has classroom access: ${scopes.contains('classroom')}');
          print('Has drive access: ${scopes.contains('drive')}');
        }
      } catch (e) {
        print('Error checking token: $e');
      }
    }
  }

  Future<void> _debugAuthStatus() async {
    try {
      print('=== AUTHENTICATION DEBUG ===');
      
      // Check Google Auth Helper status
      final googleAuthStatus = await SimpleGoogleAuth.getAuthStatus();
      final googleToken = SimpleGoogleAuth.accessToken;
      
      // Check Grading Service status
      final serviceStatus = await _gradingService.getAuthenticationStatus();
      
      print('Google Auth Helper Status:');
      print('  Has Token: ${googleAuthStatus['hasToken']}');
      print('  Token Length: ${googleAuthStatus['tokenLength']}');
      print('  Token Preview: ${googleToken?.substring(0, 20) ?? 'null'}...');
      print('  Is Valid: ${googleAuthStatus['isValid']}');
      print('  Is Expired: ${googleAuthStatus['isExpired']}');
      
      print('Grading Service Status:');
      print('  Platform: ${serviceStatus['platform']}');
      print('  Google Authenticated: ${serviceStatus['googleAuthenticated']}');
      print('  Google Token Length: ${serviceStatus['googleTokenLength']}');
      print('  Google Token Valid: ${serviceStatus['googleTokenValid']}');
      
      // 🆕 NEW: Check if tokens match
      final tokensMatch = googleToken != null && 
                         serviceStatus['googleAuthenticated'] == true &&
                         serviceStatus['googleTokenLength'] == googleToken.length;
      
      print('Tokens Synchronized: $tokensMatch');
      
      // Show in UI with enhanced info
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Authentication Debug'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Auth Helper:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('• Has Token: ${googleAuthStatus['hasToken']}'),
                  Text('• Token Length: ${googleAuthStatus['tokenLength']}'),
                  Text('• Token Preview: ${googleToken?.substring(0, 20) ?? 'null'}...'),
                  Text('• Is Valid: ${googleAuthStatus['isValid']}'),
                  Text('• Is Expired: ${googleAuthStatus['isExpired']}'),
                  const SizedBox(height: 16),
                  Text('Grading Service:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('• Platform: ${serviceStatus['platform']}'),
                  Text('• Google Auth: ${serviceStatus['googleAuthenticated']}'),
                  Text('• Token Length: ${serviceStatus['googleTokenLength']}'),
                  Text('• Token Valid: ${serviceStatus['googleTokenValid']}'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokensMatch ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: tokensMatch ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tokensMatch ? Icons.check_circle : Icons.error,
                          color: tokensMatch ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tokensMatch ? 'Tokens synchronized ✅' : 'Tokens NOT synchronized ❌',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tokensMatch ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (serviceStatus['googleTokenError'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Error: ${serviceStatus['googleTokenError']}', 
                         style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
              if (!tokensMatch || googleAuthStatus['isValid'] != true)
                ElevatedButton(
                  onPressed: () {
                    if (mounted) Navigator.pop(context);
                    _fixTokenSynchronization();
                  },
                  child: const Text('Fix Synchronization'),
                ),
            ],
          ),
        );
      }
      
    } catch (e) {
      print('Error in auth debug: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug error: $e')),
        );
      }
    }
  }

  Future<void> _fixTokenSynchronization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleToken = SimpleGoogleAuth.accessToken;
      
      if (googleToken != null) {
        print('🔧 Fixing token synchronization...');
        
        // Force set the token in the grading service
        _gradingService.setGoogleAccessToken(googleToken);
        
        // Verify it worked
        await _verifyTokenSynchronization();
        
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Token synchronization fixed!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // No token available, need to re-authenticate
        _forceReAuthentication();
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fixing synchronization: $e';
      });
    }
  }

  /// 🆕 Force re-authentication
  Future<void> _forceReAuthentication() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clear current authentication
      await SimpleGoogleAuth.signOut();
      _gradingService.clearAuthentication();
      
      // Wait a moment
      await Future.delayed(const Duration(seconds: 1));
      
      // Start fresh authentication
      final newToken = await SimpleGoogleAuth.signIn();
      
      if (newToken != null) {
        print('🔄 Re-authentication token received: ${newToken.substring(0, 20)}...');
        
        // 🎯 CRITICAL: Set the new token immediately
        _gradingService.setGoogleAccessToken(newToken);
        
        // 🆕 NEW: Verify synchronization
        await _verifyTokenSynchronization();
        
        setState(() {
          _isLoading = false;
          _isAuthenticated = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Re-authentication successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
          _errorMessage = 'Re-authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Re-authentication error: $e';
      });
    }
  }

  Future<void> _verifyTokenSynchronization() async {
    try {
      print('🔍 Verifying token synchronization...');
      
      // Check both sources
      final googleAuthToken = SimpleGoogleAuth.accessToken;
      final serviceStatus = await _gradingService.getAuthenticationStatus();
      
      print('Google Auth Token: ${googleAuthToken?.substring(0, 20) ?? 'null'}...');
      print('Service Has Token: ${serviceStatus['googleAuthenticated']}');
      print('Service Token Length: ${serviceStatus['googleTokenLength']}');
      
      // If they don't match, sync them
      if (googleAuthToken != null && !serviceStatus['googleAuthenticated']) {
        print('🔧 Tokens out of sync, re-syncing...');
        _gradingService.setGoogleAccessToken(googleAuthToken);
        
        // Verify again
        final newStatus = await _gradingService.getAuthenticationStatus();
        print('✅ After sync - Service Has Token: ${newStatus['googleAuthenticated']}');
      }
      
    } catch (e) {
      print('❌ Error verifying token sync: $e');
    }
  }

  // ============ DATA LOADING ============

  /// Enhanced course loading with comprehensive debugging
Future<void> _loadCourses() async {
  if (!_isAuthenticated) {
    print('❌ Not authenticated, cannot load courses');
    return;
  }

  print('📚 Loading courses for platform: $_selectedPlatform');

  if (mounted) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  try {
    print('🔄 Calling gradingService.getCourses()...');
    final courses = await _gradingService.getCourses();
    
    print('✅ Received ${courses.length} courses');
    for (int i = 0; i < courses.length; i++) {
      print('   Course $i: ${courses[i].name} (ID: ${courses[i].id})');
    }

    if (mounted) {
      setState(() {
        _courses = courses;
        _isLoading = false;
        // ✅ CRITICAL: Clear these when loading new courses
        _selectedCourse = null;
        _assignments = [];
        _submissions = [];
        _selectedAssignment = null;
        _selectedSubmission = null;
      });
    }

    print('✅ Course loading completed successfully');

  } catch (e) {
    print('❌ Error loading courses: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load courses: $e';
      });
    }
  }
}

  /// Enhanced assignment loading with debugging
Future<void> _loadAssignments(Course course) async {
  print('📝 Loading assignments for course: ${course.name} (${course.id})');

  _safeSetState(() {
    _isLoading = true;
    _errorMessage = null;
    _selectedCourse = course;
    // ✅ CRITICAL: Clear these BEFORE loading new assignments
    _selectedAssignment = null;
    _assignments = [];
    _submissions = [];
    _selectedSubmission = null;
  });

  try {
    print('🔄 Calling gradingService.getAssignments(${course.id})...');
    final assignments = await _gradingService.getAssignments(course.id);
    
    print('✅ Received ${assignments.length} assignments');
    for (int i = 0; i < assignments.length; i++) {
      print('   Assignment $i: ${assignments[i].name} (ID: ${assignments[i].id})');
    }

    _safeSetState(() {
      _assignments = assignments;
      _isLoading = false;
      // Keep _selectedAssignment as null until user selects one
    });

    print('✅ Assignment loading completed successfully');

  } catch (e) {
    print('❌ Error loading assignments: $e');
    _safeSetState(() {
      _isLoading = false;
      _errorMessage = 'Failed to load assignments: $e';
    });
  }
}

  Future<void> _loadSubmissions(Assignment assignment) async {
    // Check if we have a selected course
    if (_selectedCourse == null) {
      _safeSetState(() {
        _errorMessage = 'No course selected';
      });
      return;
    }

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAssignment = assignment;
      _submissions = [];
      _selectedSubmission = null;
    });

    try {
      // 🆕 NEW: Verify token synchronization before making API calls
      await _verifyTokenSynchronization();
      
      final allSubmissions = await _gradingService.getSubmissions(
        _selectedCourse!.id,
        assignment.id,
      );
      
      // ✅ CRITICAL FIX: Filter out empty/invalid submissions
      final validSubmissions = allSubmissions.where((submission) {
        // Only include submissions that have:
        // 1. A valid student name (not just numbers)
        // 2. Actual code content (not empty or just "submission")
        // 3. A real filename (not just "submission")
        
        final hasValidStudentName = submission.studentName.isNotEmpty && 
                                   !RegExp(r'^\d+$').hasMatch(submission.studentName) && // Not just numbers
                                   submission.studentName.toLowerCase() != 'student';
                                   
        final hasValidCode = submission.code.isNotEmpty && 
                            submission.code.toLowerCase() != 'submission' &&
                            submission.code.length > 10; // Some meaningful content
                            
        final hasValidFilename = submission.filename.isNotEmpty && 
                                submission.filename.toLowerCase() != 'submission' &&
                                submission.filename.contains('.');
        
        final isRealSubmission = hasValidStudentName && hasValidCode && hasValidFilename;
        
        // Debug logging
        if (!isRealSubmission) {
          print('🚫 Filtering out invalid submission:');
          print('  Student: ${submission.studentName}');
          print('  Filename: ${submission.filename}');
          print('  Code length: ${submission.code.length}');
          print('  Code preview: ${submission.code.substring(0, math.min(50, submission.code.length))}');
        }
        
        return isRealSubmission;
      }).toList();
      
      print('📊 Submissions loaded: ${allSubmissions.length} total, ${validSubmissions.length} valid');
      
      _safeSetState(() {
        _submissions = validSubmissions;
        _isLoading = false;
      });
      
      // Show info about filtered submissions
      if (allSubmissions.length > validSubmissions.length) {
        final filteredCount = allSubmissions.length - validSubmissions.length;
        _safeShowSnackBar(
          'Showing ${validSubmissions.length} valid submissions',
          backgroundColor: Colors.blue,
        );
      }
      
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load submissions: $e';
      });
      
      print('❌ Error loading submissions: $e');
      
      // If it's an authentication error, suggest fixing synchronization
      if (e.toString().contains('401') || e.toString().contains('Authentication Error') || e.toString().contains('UNAUTHENTICATED')) {
        _safeShowSnackBar(
          'Authentication issue detected. Try fixing token synchronization.',
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  Future<void> _loadSubmissionContent(StudentSubmission submission) async {
    if (mounted) {
      setState(() {
        _selectedSubmission = submission;
        _currentCode = 'Loading file content...';
      });
    }

    try {
      String content;
      
      if (_selectedPlatform == 'moodle') {
        // For Moodle, you'd construct the actual file URL and download
        // This is simplified - you'd need to get the actual file URL from Moodle API
        content = submission.code;
      } else if (_selectedPlatform == 'classroom') {
        // For Google Classroom, check if we have a Drive file ID
        if (submission.code.startsWith('DRIVE_FILE:')) {
          final fileId = submission.code.substring('DRIVE_FILE:'.length);
          print('Downloading file with ID: $fileId');
          content = await _gradingService.downloadGoogleDriveFile(fileId);
        } else {
          content = submission.code; // Fallback to stored content
        }
      } else {
        content = submission.code;
      }
      
      if (mounted) {
        setState(() {
          _currentCode = content;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentCode = 'Error loading file: $e\n\nPlease check:\n1. File permissions in Google Drive\n2. File is accessible to your account\n3. Network connection';
        });
      }
      print('Error loading submission content: $e');
    }
  }

  // ============ BATCH PROCESSING METHODS ============

  Future<void> _executeAllSubmissions() async {
    if (_selectedAssignment == null || _submissions.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No assignment selected or no submissions available';
        });
      }
      return;
    }

    // Show confirmation dialog
    final shouldProceed = await _showBatchExecutionDialog();
    if (!shouldProceed) return;

    if (mounted) {
      setState(() {
        _isBatchProcessing = true;
        _errorMessage = null;
        _lastBatchResult = null;
      });
    }

    try {
      print('🚀 Starting batch execution for ${_submissions.length} submissions');
      
      // 🆕 NEW: Download Google Drive files first
      List<StudentSubmission> processedSubmissions = [];
      
      for (final submission in _submissions) {
        if (submission.code.startsWith('DRIVE_FILE:')) {
          print('📥 Downloading Google Drive file for ${submission.studentName}...');
          
          try {
            final fileId = submission.code.substring('DRIVE_FILE:'.length);
            final actualCode = await _gradingService.downloadGoogleDriveFile(fileId);
            
            // Create a new submission with the actual code
            final updatedSubmission = StudentSubmission(
              id: submission.id,
              studentId: submission.studentId,
              studentName: submission.studentName,
              filename: submission.filename,
              code: actualCode,
              assignmentId: submission.assignmentId,
              submittedAt: submission.submittedAt,
              status: submission.status,
              fileSize: actualCode.length,
              fileExtension: submission.fileExtension,
              gradeId: submission.gradeId,
              uploadedAt: submission.uploadedAt,
            );
            
            processedSubmissions.add(updatedSubmission);
            print('✅ Downloaded file for ${submission.studentName} (${actualCode.length} chars)');
            
          } catch (e) {
            print('❌ Failed to download file for ${submission.studentName}: $e');
            
            // Add submission with error message
            final errorSubmission = StudentSubmission(
              id: submission.id,
              studentId: submission.studentId,
              studentName: submission.studentName,
              filename: submission.filename,
              code: 'print("Error: Could not download file")',
              assignmentId: submission.assignmentId,
              submittedAt: submission.submittedAt,
              status: 'error',
              fileSize: 0,
              fileExtension: submission.fileExtension,
              gradeId: submission.gradeId,
              uploadedAt: submission.uploadedAt,
            );
            
            processedSubmissions.add(errorSubmission);
          }
        } else {
          // File already contains actual code
          processedSubmissions.add(submission);
        }
      }
      
      // Debug: Show actual code content
      print('=== FINAL PROCESSED SUBMISSIONS ===');
      for (final submission in processedSubmissions) {
        print('Student: ${submission.studentName}');
        print('Filename: ${submission.filename}');
        print('Code length: ${submission.code.length}');
        print('First 50 chars: ${submission.code.substring(0, math.min(50, submission.code.length))}');
        print('---');
      }
      
      try {
        // Execute batch with processed submissions
        final result = await BatchExecutionService.executeAllSubmissions(
          assignmentId: _selectedAssignment!.id,
          submissions: processedSubmissions,
          platform: _selectedPlatform,
        );

        if (mounted) {
          setState(() {
            _isBatchProcessing = false;
            _lastBatchResult = result as batch_models.BatchExecutionResult?;
          });
        }

        // Show results dialog
        if (mounted) {
          _showBatchResultsDialog(result as batch_models.BatchExecutionResult);
        }

      } catch (e) {
        if (mounted) {
          setState(() {
            _isBatchProcessing = false;
            _errorMessage = 'Batch execution failed: $e';
          });
        }

        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Batch execution failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBatchProcessing = false;
          _errorMessage = 'Batch execution setup failed: $e';
        });
      }
    }
  }

  // Enhanced grading dialog with execution results
  void _showAutoGradingDialog(CodeExecutionResult executionResult) {
    final TextEditingController gradeController = TextEditingController();
    final TextEditingController feedbackController = TextEditingController();
    
    // Auto-populate feedback based on execution result
    if (executionResult.success) {
      feedbackController.text = 'Code executed successfully!\n\nOutput:\n${executionResult.output}';
      if (_selectedAssignment != null) {
        gradeController.text = _selectedAssignment!.maxScore.toString();
      }
    } else {
      feedbackController.text = 'Code execution failed.\n\nError:\n${executionResult.error}\n\nPlease review and fix the issues.';
      gradeController.text = '0';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    executionResult.success ? Icons.check_circle : Icons.error,
                    color: executionResult.success ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Grade: ${_selectedSubmission!.studentName}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedSubmission!.filename,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Execution Results Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: executionResult.success ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: executionResult.success ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: executionResult.success ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Execution Result',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: executionResult.success ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (executionResult.hasOutput) ...[
                      const Text('Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          executionResult.output,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (executionResult.hasError) ...[
                      const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          executionResult.error,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Grade Input
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: gradeController,
                      decoration: InputDecoration(
                        labelText: 'Grade (0-${_selectedAssignment?.maxScore ?? 100})',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.grade),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.school, color: Colors.blue.shade700),
                        const SizedBox(height: 4),
                        Text(
                          'Max: ${_selectedAssignment?.maxScore ?? 100}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Feedback Input
              const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter detailed feedback for the student...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  // Cancel button
                  TextButton.icon(
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                  
                  const Spacer(), // This replaces MainAxisAlignment.spaceBetween
                  
                  // Wrap action buttons in Flexible to prevent overflow
                  Flexible(
                    child: Wrap(
                      spacing: 4,
                      children: [
                        // Smaller debug button
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_selectedCourse != null && _selectedAssignment != null && _selectedSubmission?.id != null) {
                                await _gradingService.debugTokenAndRequest(
                                  courseId: _selectedCourse!.id,
                                  assignmentId: _selectedAssignment!.id,
                                  submissionId: _selectedSubmission!.id!,
                                );
                              }
                            },
                            icon: const Icon(Icons.bug_report, size: 14),
                            label: const Text('Debug', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                          ),
                        ),
                        
                        // Save button
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _submitGradeToClassroom(
                                gradeController.text,
                                feedbackController.text,
                                executionResult,
                                saveOnly: true,
                              );
                              if (mounted) Navigator.pop(context); // 🔧 SAFE
                            },
                            icon: const Icon(Icons.save, size: 14),
                            label: const Text('Save', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                          ),
                        ),
                        
                        // Submit button with improved error handling
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _submitGradeToClassroom(
                                  gradeController.text,
                                  feedbackController.text,
                                  executionResult,
                                  saveOnly: false,
                                );
                                if (mounted) Navigator.pop(context); // 🔧 SAFE
                              } catch (e) {
                                // Show improved error dialog
                                if (mounted) {
                                  _showGradingErrorDialog(e.toString(), gradeController.text, feedbackController.text, executionResult);
                                }
                              }
                            },
                            icon: const Icon(Icons.upload, size: 14),
                            label: const Text('Submit', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestFullPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Show info dialog first
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.orange),
              SizedBox(width: 8),
              Text('Grant Full Permissions'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To submit grades to Google Classroom, additional permissions are required:'),
              SizedBox(height: 12),
              Text('• Manage coursework and grades'),
              Text('• Submit student assignments'),
              Text('• Access Google Drive files'),
              SizedBox(height: 12),
              Text(
                'You will be redirected to Google to grant these permissions.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      );

      if (shouldProceed == true) {
        // Force re-authentication with full permissions
        final newToken = await SimpleGoogleAuth.forceReAuth();
        
        if (newToken != null) {
          _gradingService.setGoogleAccessToken(newToken);
          
          setState(() {
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Full permissions granted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to grant full permissions. Please try again.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error requesting permissions: $e';
      });
    }
  }

  // ALSO UPDATE the _autoGradeIndividualSubmission method to handle null safety

  Future<void> _autoGradeIndividualSubmission() async {
    if (_selectedSubmission == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No submission selected';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isIndividualExecuting = true;
        _individualExecutionResult = null;
        _errorMessage = null;
      });
    }

    try {
      print('🚀 Auto-grading submission for ${_selectedSubmission!.studentName}');
      
      String codeToExecute = _selectedSubmission!.code;
      
      // Download Google Drive file if needed
      if (codeToExecute.startsWith('DRIVE_FILE:')) {
        print('📥 Downloading Google Drive file...');
        final fileId = codeToExecute.substring('DRIVE_FILE:'.length);
        codeToExecute = await _gradingService.downloadGoogleDriveFile(fileId);
        print('✅ Downloaded file (${codeToExecute.length} chars)');
        
        // Update the current code display
        if (mounted) {
          setState(() {
            _currentCode = codeToExecute;
          });
        }
      }

      // Execute the code
      final language = CodeExecutionService.detectLanguageFromFilename(_selectedSubmission!.filename);
      
      final result = await CodeExecutionService.executeCode(
        language: language,
        code: codeToExecute,
        filename: _selectedSubmission!.filename,
        assignmentId: _selectedAssignment?.id,
        studentId: _selectedSubmission!.studentId,
        platform: _selectedPlatform,
      );

      if (mounted) {
        setState(() {
          _isIndividualExecuting = false;
          _individualExecutionResult = result;
        });
      }

      print('✅ Individual execution completed: ${result.success ? "Success" : "Failed"}');
      
      // Show grading dialog with execution results
      _showAutoGradingDialog(result);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isIndividualExecuting = false;
          _errorMessage = 'Individual execution failed: $e';
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-grade failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ UI BUILDERS ============

  Widget _buildPlatformSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Platform',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              items: const [
                DropdownMenuItem(value: 'moodle', child: Text('Moodle')),
                DropdownMenuItem(value: 'classroom', child: Text('Google Classroom')),
                DropdownMenuItem(value: 'test', child: Text('🧪 Test Mode')), // Added test option
              ],
              onChanged: _isAuthenticated ? null : (value) {
                if (value != null) {
                  setState(() {
                    _selectedPlatform = value;
                    _gradingService.setPlatform(value);
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    if (_isAuthenticated) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Authenticated with ${_selectedPlatform.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_selectedPlatform == 'classroom') ...[
                const SizedBox(height: 12),
                
                // Permission status and actions
                FutureBuilder<bool>(
                  future: SimpleGoogleAuth.hasGradingPermission(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Checking permissions...'),
                        ],
                      );
                    }
                    
                    final hasGradingPermission = snapshot.data ?? false;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasGradingPermission ? Icons.check_circle : Icons.warning,
                              color: hasGradingPermission ? Colors.green : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasGradingPermission 
                                  ? 'Grading permissions: ✅ Granted' 
                                  : 'Grading permissions: ⚠️ Limited',
                              style: TextStyle(
                                color: hasGradingPermission ? Colors.green.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        if (!hasGradingPermission) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Limited permissions detected',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'You can view submissions but cannot submit grades to Google Classroom.',
                                  style: TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _requestFullPermissions,
                                  icon: const Icon(Icons.security, size: 16),
                                  label: const Text('Grant Full Permissions'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _debugAuthStatus, // 🆕 NEW DEBUG BUTTON
                              icon: const Icon(Icons.bug_report, size: 16),
                              label: const Text('Debug Auth'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _checkTokenScopes,
                              icon: const Icon(Icons.info, size: 16),
                              label: const Text('Check Permissions'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Sign Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    // When not authenticated, show both authentication options AND test button
    return Column(
      children: [
        // Existing authentication UI
        if (_selectedPlatform == 'moodle') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moodle Authentication',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMoodleUser,
                    hint: const Text('Select Moodle User'),
                    items: const [
                      DropdownMenuItem(value: 'teacher0', child: Text('Teacher 0')),
                      DropdownMenuItem(value: 'teacher1', child: Text('Teacher 1')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMoodleUser = value;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticateMoodle,
                      child: _isLoading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Authenticate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Classroom Authentication',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your Google account to access Google Classroom',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _authenticateGoogleClassroom,
                      icon: _isLoading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // 🆕 NEW: Test button for Grade All functionality
        const SizedBox(height: 16),
        Card(
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Development Testing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Load mock data to test the Grade All functionality',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadMockData,
                    icon: const Icon(Icons.science, color: Colors.white),
                    label: const Text('Load Test Data', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDropdown() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Course',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // ✅ DEBUG INFO
          if (_courses.isEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No courses found. Check authentication and try refreshing.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ✅ ENHANCED DROPDOWN WITH BETTER ERROR HANDLING
          DropdownButtonFormField<Course>(
            value: _courses.contains(_selectedCourse) ? _selectedCourse : null,
            hint: Text(_isLoading ? 'Loading courses...' : 'Choose a course'),
            items: _courses.map((course) {
              return DropdownMenuItem(
                value: course,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.description.isNotEmpty)
                      Text(
                        course.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: _isAuthenticated && !_isLoading ? (course) {
              print('📚 Course selected: ${course?.name} (${course?.id})');
              if (course != null) {
                _loadAssignments(course);
              }
            } : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true, // ✅ CRITICAL: Prevent overflow
          ),

          // ✅ DEBUG BUTTONS
          if (_courses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_courses.length} courses loaded',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _debugCourseSelection(),
                  icon: const Icon(Icons.bug_report, size: 14),
                  label: const Text('Debug', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _refreshCourses(),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

/// Refresh courses manually
Future<void> _refreshCourses() async {
  print('🔄 Manual course refresh requested');
  await _loadCourses();
}

  Widget _buildAssignmentDropdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Assignment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Assignment>(
              // ✅ FIX: Ensure value is null if it's not in the items list
              value: _assignments.contains(_selectedAssignment) ? _selectedAssignment : null,
              hint: const Text('Choose an assignment'),
              items: _assignments.map((assignment) => DropdownMenuItem(
                value: assignment,
                child: Text(assignment.name),
              )).toList(),
              onChanged: _selectedCourse != null ? (assignment) {
                if (assignment != null) {
                  _loadSubmissions(assignment);
                }
              } : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAssignmentSection() {
    if (_selectedCourse == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FIXED: Use Column layout to prevent overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Gradable Assignment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // ✅ FIXED: Full-width button to prevent text overflow
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateAssignmentDialog(),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'Create Assignment', // ✅ SHORTENED: Removed "..."
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded( // ✅ FIXED: Wrap text in Expanded to prevent overflow
                        child: Text(
                          'Why create assignments through this app?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Only assignments created through this app can be automatically graded due to Google Classroom security policies.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxPointsController = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Create New Assignment'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                  hintText: 'e.g., Python Basics Quiz',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Enter assignment instructions...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxPointsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Points',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grade),
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Assignment will be created in Google Classroom',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Students can submit files directly to this assignment and you can grade them using this app.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _safeNavigatorPop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                _safeSetState(() {
                  _isLoading = true;
                });
                
                try {
                  final newAssignment = await _gradingService.createGoogleClassroomAssignment(
                    courseId: _selectedCourse!.id,
                    title: titleController.text,
                    description: descriptionController.text,
                    maxPoints: double.tryParse(maxPointsController.text) ?? 100,
                  );
                  
                  _safeNavigatorPop(); // Close the dialog first
                  
                  // ✅ CRITICAL FIX: Clear selected assignment BEFORE reloading
                  _safeSetState(() {
                    _selectedAssignment = null;
                    _submissions = [];
                    _selectedSubmission = null;
                  });
                  
                  // Refresh assignments list
                  if (mounted && _selectedCourse != null) {
                    await _loadAssignments(_selectedCourse!);
                  }
                  
                  // ✅ SAFE: Find and select the new assignment from the refreshed list
                  if (mounted) {
                    final foundAssignment = _assignments.firstWhere(
                      (assignment) => assignment.id == newAssignment.id,
                      orElse: () => newAssignment, // Fallback to the new assignment
                    );
                    
                    _safeSetState(() {
                      _selectedAssignment = foundAssignment;
                      _isLoading = false;
                    });
                  }
                  
                  _safeShowSnackBar(
                    '✅ Assignment "${newAssignment.name}" created successfully!',
                    backgroundColor: Colors.green,
                  );
                  
                } catch (e) {
                  _safeSetState(() {
                    _isLoading = false;
                  });
                  
                  _safeNavigatorPop();
                  
                  _safeShowSnackBar(
                    '❌ Failed to create assignment: $e',
                    backgroundColor: Colors.red,
                  );
                }
              } else {
                _safeShowSnackBar(
                  'Please enter an assignment title',
                  backgroundColor: Colors.orange,
                );
              }
            },
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add, color: Colors.white),
            label: Text(_isLoading ? 'Creating...' : 'Create Assignment', 
                       style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('How to Create Gradable Assignments'),
          ],
        ),
        content: const SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎯 The Problem:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Google Classroom security only allows the same app that created an assignment to grade it.'),
              SizedBox(height: 16),
              Text(
                '💡 The Solution:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Use the "Create Assignment" button in this app'),
              Text('2. Students submit their work to the new assignment'),
              Text('3. You can then auto-grade all submissions'),
              SizedBox(height: 16),
              Text(
                '📋 Workflow:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Select a course'),
              Text('2. Click "Create Assignment" (green button)'),
              Text('3. Fill in assignment details'),
              Text('4. Share the assignment with students'),
              Text('5. Students submit their code files'),
              Text('6. Use "Grade All" to automatically grade submissions'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList() {
    if (_submissions.isEmpty && !_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No submissions found'),
              const SizedBox(height: 12),
              // 🆕 Add debug button when no submissions
              if (_selectedAssignment != null)
                ElevatedButton.icon(
                  onPressed: _debugSubmissions,
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Debug Submissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Student Submissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // Debug button in header
                IconButton(
                  onPressed: _debugSubmissions,
                  icon: const Icon(Icons.bug_report, size: 20),
                  tooltip: 'Debug Submissions',
                  color: Colors.purple,
                ),
                // Grade All Button
                ElevatedButton.icon(
                  onPressed: (_isBatchProcessing || _submissions.isEmpty) 
                      ? null 
                      : _executeAllSubmissions,
                  icon: _isBatchProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_filled, size: 18),
                  label: Text(_isBatchProcessing ? 'Processing...' : 'Grade All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBatchProcessing ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Show submission count and platform info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing ${_submissions.length} valid submissions from ${_selectedPlatform.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Batch processing progress indicator
            if (_isBatchProcessing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Executing ${_submissions.length} submissions...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This may take 30 seconds to 2 minutes depending on languages used.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Last batch result summary
            if (_lastBatchResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastBatchResult!.isSuccess 
                      ? Colors.green.shade50 
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lastBatchResult!.isSuccess 
                        ? Colors.green.shade200 
                        : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _lastBatchResult!.isSuccess 
                              ? Icons.check_circle 
                              : Icons.warning,
                          color: _lastBatchResult!.isSuccess 
                              ? Colors.green 
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Last Batch Result:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_lastBatchResult!.summary),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showBatchResultsDialog(_lastBatchResult!),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Submissions list
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _submissions.length,
                itemBuilder: (context, index) {
                  final submission = _submissions[index];
                  final isSelected = _selectedSubmission?.id == submission.id;
                  
                  // Check if we have batch results for this submission
                  final hasResult = _lastBatchResult?.results.containsKey(submission.id) ?? false;
                  final result = hasResult ? _lastBatchResult!.results[submission.id] : null;
                  
                  return ListTile(
                    title: Text(
                      submission.studentName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File: ${submission.filename}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Show code preview for verification - FIXED OVERFLOW
                        Text(
                          'Code: ${submission.code.substring(0, math.min(30, submission.code.length))}${submission.code.length > 30 ? "..." : ""}',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (hasResult && result != null) ...[
                          const SizedBox(height: 4),
                          // ✅ FIXED: Wrap Row in Flexible/Expanded to prevent overflow
                          Row(
                            children: [
                              Icon(
                                result.success ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: result.success ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  result.success ? 'Executed successfully' : 'Execution failed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: result.success ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (result.executionTimeMs != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  result.executionTimeFormatted,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.purple.shade50,
                    onTap: () => _loadSubmissionContent(submission),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasResult && result != null)
                          Icon(
                            result.success ? Icons.check_circle : Icons.error,
                            color: result.success ? Colors.green : Colors.red,
                            size: 20,
                          )
                        else
                          Icon(
                            submission.gradeId != null ? Icons.check_circle : Icons.circle_outlined,
                            color: submission.gradeId != null ? Colors.green : Colors.grey,
                          ),
                        const SizedBox(width: 8),
                        _getLanguageIcon(_getLanguageFromFilename(submission.filename)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel() {
    if (_isPanelCollapsed) {
      return Container(
        width: 50,
        color: Colors.grey.shade100,
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => setState(() => _isPanelCollapsed = false),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 350,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.purple.shade700,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'FocusEd AI - Grading Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => setState(() => _isPanelCollapsed = true),
                ),
              ],
            ),
          ),
          // Panel content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildPlatformSelector(),
                  const SizedBox(height: 16),
                  _buildAuthenticationSection(),
                  if (_isAuthenticated) ...[
                    const SizedBox(height: 16),
                    _buildCourseDropdown(),
                    const SizedBox(height: 16),
                    _buildAssignmentDropdown(),
                    const SizedBox(height: 16),
                    _buildCreateAssignmentSection(),
                    const SizedBox(height: 16),
                    _buildSubmissionsList(),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Column(
        children: [
          // Top bar with enhanced action buttons
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Home button
                if (_isAuthenticated)
                  IconButton(
                    onPressed: _resetToPlatformSelection,
                    icon: const Icon(Icons.home),
                    tooltip: 'Back to Platform Selection',
                  ),
                // Assignment and student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedAssignment?.name ?? 'No assignment selected',
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedSubmission != null)
                        Text(
                          'Student: ${_selectedSubmission!.studentName} • Submitted: ${_formatDateTimeNullable(_selectedSubmission!.submittedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else if (_isBatchProcessing)
                        Text(
                          'Batch processing ${_submissions.length} submissions...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (_submissions.isNotEmpty)
                        Text(
                          '${_submissions.length} submissions available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Enhanced action buttons
                if (_selectedSubmission != null) ...[
                  // Execution status indicator
                  if (_individualExecutionResult != null) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _individualExecutionResult!.success ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _individualExecutionResult!.success ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _individualExecutionResult!.success ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: _individualExecutionResult!.success ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _individualExecutionResult!.success ? 'Executed' : 'Failed',
                            style: TextStyle(
                              fontSize: 12,
                              color: _individualExecutionResult!.success ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Submission status chip
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        _selectedSubmission!.status.toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(_selectedSubmission!.status),
                    ),
                  ),
                  
                  // 🆕 AUTO-GRADE BUTTON
                  ElevatedButton.icon(
                    onPressed: _isIndividualExecuting ? null : _autoGradeIndividualSubmission,
                    icon: _isIndividualExecuting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isIndividualExecuting ? 'Running...' : 'Auto-Grade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isIndividualExecuting ? Colors.grey : Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Manual grade button
                  ElevatedButton.icon(
                    onPressed: () => _showGradingDialog(),
                    icon: const Icon(Icons.grade, size: 18),
                    label: const Text('Manual Grade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Feedback button
                  ElevatedButton.icon(
                    onPressed: () => _showFeedbackDialog(),
                    icon: const Icon(Icons.comment, size: 18),
                    label: const Text('Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Enhanced code editor area with execution results
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _selectedSubmission != null
                  ? Column(
                      children: [
                        // Code editor
                        Expanded(
                          child: EnhancedCodeEditor(
                            code: _currentCode,
                            fileName: _selectedSubmission!.filename,
                            language: _detectLanguageFromFilename(_selectedSubmission!.filename),
                            isLoading: _currentCode == 'Loading file content...',
                            assignmentId: _selectedAssignment?.id,
                            studentId: _selectedSubmission?.studentId,
                          ),
                        ),
                        
                        // Individual execution results (if available)
                        if (_individualExecutionResult != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _individualExecutionResult!.success ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _individualExecutionResult!.success ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _individualExecutionResult!.success ? Icons.check_circle : Icons.error,
                                      color: _individualExecutionResult!.success ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Individual Execution Result',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _individualExecutionResult!.success ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _individualExecutionResult = null;
                                        });
                                      },
                                      icon: const Icon(Icons.close, size: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                if (_individualExecutionResult!.hasOutput) ...[
                                  const Text('Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _individualExecutionResult!.output,
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                    ),
                                  ),
                                ],
                                
                                if (_individualExecutionResult!.hasError) ...[
                                  const SizedBox(height: 8),
                                  const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _individualExecutionResult!.error,
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    )
                  : _buildEmptyState(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTimeNullable(DateTime? dateTime) {
    if (dateTime == null) return 'Not submitted';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.green.shade100;
      case 'graded':
        return Colors.blue.shade100;
      case 'late':
        return Colors.orange.shade100;
      case 'missing':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _detectLanguageFromFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'java':
        return 'Java';
      case 'py':
        return 'Python';
      case 'js':
        return 'JavaScript';
      case 'cpp':
      case 'cc':
      case 'cxx':
        return 'C++';
      case 'c':
        return 'C';
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'php':
        return 'PHP';
      case 'rb':
        return 'Ruby';
      case 'go':
        return 'Go';
      case 'rs':
        return 'Rust';
      case 'swift':
        return 'Swift';
      case 'kt':
        return 'Kotlin';
      default:
        return 'Text';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a submission to view code',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a student submission from the panel to start grading',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods for grading and feedback

  void _showGradingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${_selectedSubmission!.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: _gradeInput),
              decoration: InputDecoration(
                labelText: 'Grade (0-${_selectedAssignment!.maxScore})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _gradeInput = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _feedbackInput),
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _feedbackInput = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _safeNavigatorPop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitGrade();
              _safeNavigatorPop();
            },
            child: const Text('Submit Grade'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feedback for ${_selectedSubmission!.studentName}'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: TextEditingController(text: _feedbackInput),
            decoration: const InputDecoration(
              labelText: 'Enter your feedback',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            onChanged: (value) => _feedbackInput = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _safeNavigatorPop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitFeedback();
              _safeNavigatorPop();
            },
            child: const Text('Save Feedback'),
          ),
        ],
      ),
    );
  }

  void _submitGrade() {
    // Implement your grading logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grade submitted for ${_selectedSubmission!.studentName}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _submitFeedback() {
    // Implement your feedback logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback saved for ${_selectedSubmission!.studentName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Sign out functionality
  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: Text('Are you sure you want to sign out from ${_selectedPlatform.toUpperCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Platform-specific sign out
        if (_selectedPlatform == 'classroom') {
          await SimpleGoogleAuth.signOut();
        }
        
        // Reset all state
        setState(() {
          _isAuthenticated = false;
          _selectedMoodleUser = null;
          _courses = [];
          _assignments = [];
          _submissions = [];
          _selectedCourse = null;
          _selectedAssignment = null;
          _selectedSubmission = null;
          _currentCode = '';
          _gradeInput = '';
          _feedbackInput = '';
          _errorMessage = null;
          _isLoading = false;
        });

        // Clear any stored tokens or data in the grading service
        _gradingService.clearAuthentication();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully signed out from ${_selectedPlatform.toUpperCase()}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error signing out: $e';
        });
      }
    }
  }

  // Reset to platform selection
  void _resetToPlatformSelection() {
    setState(() {
      _selectedPlatform = 'moodle';
      _isAuthenticated = false;
      _selectedMoodleUser = null;
      _courses = [];
      _assignments = [];
      _submissions = []; // Clear all submissions
      _selectedCourse = null;
      _selectedAssignment = null;
      _selectedSubmission = null;
      _currentCode = '';
      _gradeInput = '';
      _feedbackInput = '';
      _errorMessage = null;
      _isLoading = false;
      // Clear batch results too
      _lastBatchResult = null;
      _individualExecutionResult = null;
    });
    _initializePlatform();
  }

  // **Test data**

  List<StudentSubmission> _createMockSubmissions() {
    return [
      // Simple test that definitely works
      StudentSubmission(
        id: 'sub1',
        studentId: 'student1',
        studentName: 'John Doe',
        filename: 'simple.py',
        code: 'print("Hello from John!")',
        assignmentId: 'test-assignment',
        submittedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'uploaded',
        fileSize: 25,
        fileExtension: 'py',
      ),
      
      // Math test
      StudentSubmission(
        id: 'sub2',
        studentId: 'student2',
        studentName: 'Jane Smith',
        filename: 'math.py',
        code: 'x = 10\ny = 5\nprint(f"Sum: {x + y}")',
        assignmentId: 'test-assignment',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'uploaded',
        fileSize: 35,
        fileExtension: 'py',
      ),
      
      // Loop test
      StudentSubmission(
        id: 'sub3',
        studentId: 'student3',
        studentName: 'Bob Johnson',
        filename: 'loop.py',
        code: 'for i in range(3):\n    print(f"Count: {i}")',
        assignmentId: 'test-assignment',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'uploaded',
        fileSize: 40,
        fileExtension: 'py',
      ),
      
      // Clean calculator test
      StudentSubmission(
        id: 'sub4',
        studentId: 'student4',
        studentName: 'Alice Williams',
        filename: 'calculator.py',
        code: 'class Calculator:\n    def add(self, a, b):\n        return a + b\n\ncalc = Calculator()\nresult = calc.add(10, 5)\nprint(f"Result: {result}")',
        assignmentId: 'test-assignment',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'uploaded',
        fileSize: 120,
        fileExtension: 'py',
      ),
    ];
  }

  // ADD THIS METHOD to load the mock data
  void _loadMockData() {
    setState(() {
      _selectedPlatform = 'test';
      _isAuthenticated = true;
      _courses = [
        Course(
          id: 'CS101',
          name: 'Introduction to Programming',
          description: 'Basic Python programming',
          instructor: 'Dr. Test',
          createdAt: DateTime.now(),
          assignmentIds: ['test-assignment'],
        ),
      ];
      _selectedCourse = _courses.first;
      _assignments = [
        Assignment(
          id: 'test-assignment',
          name: 'Python Basics Assignment',
          description: 'Test assignment for Grade All functionality',
          language: 'python',
          courseId: 'CS101',
          maxScore: 100,
          testCases: [],
          createdAt: DateTime.now(),
        ),
      ];
      _selectedAssignment = _assignments.first;
      _submissions = _createMockSubmissions();
    });
  }

  Future<void> _debugSubmissions() async {
    if (_selectedCourse == null || _selectedAssignment == null) {
      print('❌ No course or assignment selected for debugging');
      return;
    }
    
    try {
      print('🔍 DEBUG: Loading submissions for debugging...');
      final submissions = await _gradingService.getSubmissions(
        _selectedCourse!.id,
        _selectedAssignment!.id,
      );
      
      print('📊 Total submissions returned: ${submissions.length}');
      
      for (int i = 0; i < submissions.length; i++) {
        final sub = submissions[i];
        print('--- Submission $i ---');
        print('ID: ${sub.id}');
        print('Student ID: ${sub.studentId}');
        print('Student Name: "${sub.studentName}"');
        print('Filename: "${sub.filename}"');
        print('Code length: ${sub.code.length}');
        print('Code preview: "${sub.code.substring(0, math.min(100, sub.code.length))}"');
        print('Status: ${sub.status}');
        print('Submitted at: ${sub.submittedAt}');
        print('');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// Test if we can grade the current assignment
  Future<void> _testAssignmentGradingCapability() async {
    if (_selectedCourse == null || _selectedAssignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assignment selected for testing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _gradingService.testAssignmentGradingCapability(
        courseId: _selectedCourse!.id,
        assignmentId: _selectedAssignment!.id,
      );

      setState(() {
        _isLoading = false;
      });

      _showGradingCapabilityResults(result);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show grading capability test results
  void _showGradingCapabilityResults(Map<String, dynamic> result) {
    final canGrade = result['canGrade'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              canGrade ? Icons.check_circle : Icons.error,
              color: canGrade ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('Grading Capability Test'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canGrade ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: canGrade ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canGrade ? '✅ Assignment can be graded' : '❌ Assignment cannot be graded',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: canGrade ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (result['assignmentTitle'] != null)
                      Text('Title: ${result['assignmentTitle']}'),
                    if (result['maxPoints'] != null)
                      Text('Max Points: ${result['maxPoints']}'),
                    if (result['submissionCount'] != null)
                      Text('Submissions: ${result['submissionCount']}'),
                    const SizedBox(height: 8),
                    Text(
                      result['details'] ?? 'No additional details',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (result['error'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${result['error']}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!canGrade)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _debugGradingIssue();
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Further'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
        ],
      ),
    );
  }

  /// Debug grading issues in detail
  Future<void> _debugGradingIssue() async {
    if (_selectedCourse == null || _selectedAssignment == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _gradingService.debugAssignmentGradingIssues(
        courseId: _selectedCourse!.id,
        assignmentId: _selectedAssignment!.id,
        submissionId: _selectedSubmission?.id,
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug information printed to console'),
          backgroundColor: Colors.blue,
        ),
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Retry grade submission after a delay
  Future<void> _retryGradeSubmission(String grade, String feedback, CodeExecutionResult executionResult) async {
    // Wait a moment before retrying
    await Future.delayed(const Duration(seconds: 2));
    
    _submitGradeToClassroom(grade, feedback, executionResult, saveOnly: false);
  }

  /// Refresh assignment data
  Future<void> _refreshAssignmentData() async {
    if (_selectedCourse == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadAssignments(_selectedCourse!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment data refreshed'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============ DEBUG METHODS ============

/// Debug course selection issues
void _debugCourseSelection() {
  print('=== COURSE SELECTION DEBUG ===');
  print('Platform: $_selectedPlatform');
  print('Authenticated: $_isAuthenticated');
  print('Loading: $_isLoading');
  print('Courses count: ${_courses.length}');
  print('Selected course: ${_selectedCourse?.name ?? 'None'}');
  print('Error message: $_errorMessage');

  for (int i = 0; i < _courses.length; i++) {
    final course = _courses[i];
    print('Course $i:');
    print('  Name: ${course.name}');
    print('  ID: ${course.id}');
    print('  Description: ${course.description}');
    print('  Instructor: ${course.instructor}');
  }

  // Show debug dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Course Selection Debug'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebugRow('Platform', _selectedPlatform),
              _buildDebugRow('Authenticated', _isAuthenticated.toString()),
              _buildDebugRow('Loading', _isLoading.toString()),
              _buildDebugRow('Courses Count', _courses.length.toString()),
              _buildDebugRow('Selected Course', _selectedCourse?.name ?? 'None'),
              _buildDebugRow('Error Message', _errorMessage ?? 'None'),
              const SizedBox(height: 16),
              const Text('Courses:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._courses.map((course) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${course.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('ID: ${course.id}'),
                    if (course.description.isNotEmpty) Text('Description: ${course.description}'),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _refreshCourses();
          },
          child: const Text('Refresh Courses'),
        ),
      ],
    ),
  );
}

Widget _buildDebugRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidePanel(),
          _buildMainContent(),
        ],
      ),
    );
  }
}