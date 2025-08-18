import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focused_ai_ui/constants/server_constants.dart';
import 'package:focused_ai_ui/models/code_file.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:typed_data';

import '../components/app_navbar.dart';
import '../services/auth_service.dart';
import '../services/google_classroom_service.dart';
import '../services/moodle_service.dart';
import '../services/zip_submission_service.dart';
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/submission.dart';
import '../models/lms.dart';
import '../screens/teacher_home_screen.dart';

import '../widgets/code_editor.dart';
import '../widgets/test_file_upload_widget.dart';

class TeacherCodeCompilerScreen extends StatefulWidget {
  const TeacherCodeCompilerScreen({super.key});

  @override
  State<TeacherCodeCompilerScreen> createState() =>
      _TeacherCodeCompilerScreenState();
}

class _TeacherCodeCompilerScreenState extends State<TeacherCodeCompilerScreen> {
  bool _sidebarCollapsed = false;
  Course? _selectedCourse;
  Assignment? _selectedAssignment;
  Submission? _selectedSubmission;
  bool _isLoading = false;
  bool _isLoadingAssignments = false;
  bool _isLoadingSubmissions = false;
  bool _isGrading = false;
  bool _isGradingAll = false;
  String? _error;

  List<Course> _courses = [];
  List<Assignment> _assignments = [];
  List<Submission> _submissions = [];
  Map<String, dynamic>? _executionResult;
  final Map<String, Map<String, dynamic>> _gradingResults = {};

  Map<String, dynamic> _testFiles = {};
  bool _useUploadedTestFiles = false;

  // Color constants
  static const Color _primaryTextColor = Color(0xFF1A1A1A);
  static const Color _secondaryTextColor = Color(0xFF424242);
  static const Color _mutedTextColor = Color(0xFF616161);
  static const Color _lightBackgroundColor = Color(0xFFFAFAFA);
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _successColor = Color(0xFF2E7D32);
  static const Color _warningColor = Color(0xFFFF8F00);
  static const Color _errorColor = Color(0xFFD32F2F);

  bool get _isGradingEnabled {
    return _useUploadedTestFiles &&
        _testFiles['hasFiles'] == true &&
        _testFiles['inputContent'] != null &&
        _testFiles['inputContent'].toString().trim().isNotEmpty &&
        _testFiles['outputContent'] != null &&
        _testFiles['outputContent'].toString().trim().isNotEmpty &&
        _testFiles['inputFilename'] != null &&
        _testFiles['outputFilename'] != null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadCourses();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading courses: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCourses() async {
    final user = authService.currentUser;
    if (user == null) return;

    try {
      List<Course> courses = [];

      if (user.lmsType == LMS.googleClassroom) {
        final googleService = GoogleClassroomService();
        courses = await googleService.getCourses();
      } else if (user.lmsType == LMS.moodle) {
        final moodleService = MoodleService();
        courses = await moodleService.getCourses();
      }

      setState(() {
        _courses = courses;
      });

      print('Loaded ${courses.length} courses');
    } catch (e) {
      print('Error loading courses: $e');
      rethrow;
    }
  }

  Future<void> _onCourseSelected(String? courseId) async {
    if (courseId == null) return;

    setState(() {
      _selectedCourse = null;
      _selectedAssignment = null;
      _selectedSubmission = null;
      _assignments = [];
      _submissions = [];
      _isLoadingAssignments = true;
      _executionResult = null;
    });

    try {
      final course = _courses.firstWhere((c) => c.id == courseId);
      setState(() {
        _selectedCourse = course;
      });

      await _loadAssignments(courseId);
    } catch (e) {
      _showErrorMessage('Failed to load course: $e');
    } finally {
      setState(() {
        _isLoadingAssignments = false;
      });
    }
  }

  Future<void> _loadAssignments(String courseId) async {
    final user = authService.currentUser;
    if (user == null) return;

    try {
      List<Assignment> assignments = [];

      if (user.lmsType == LMS.googleClassroom) {
        final googleService = GoogleClassroomService();
        assignments = await googleService.getAssignments(courseId);
      } else if (user.lmsType == LMS.moodle) {
        final moodleService = MoodleService();
        assignments = await moodleService.getAssignments(courseId);
      }

      setState(() {
        _assignments = assignments;
      });

      print('Loaded ${assignments.length} assignments for course $courseId');
    } catch (e) {
      print('Error loading assignments: $e');
      _showErrorMessage('Failed to load assignments: $e');
    }
  }

  Future<void> _onAssignmentSelected(String? assignmentId) async {
    if (assignmentId == null || _selectedCourse == null) return;

    setState(() {
      _selectedAssignment = null;
      _selectedSubmission = null;
      _submissions = [];
      _isLoadingSubmissions = true;
      _executionResult = null;
    });

    try {
      final assignment = _assignments.firstWhere((a) => a.id == assignmentId);

      setState(() {
        _selectedAssignment = assignment;
      });

      await _loadSubmissions(_selectedCourse!.id, assignmentId);
    } catch (e) {
      _showErrorMessage('Assignment not found');
    } finally {
      setState(() {
        _isLoadingSubmissions = false;
      });
    }
  }

  Future<void> _loadSubmissions(String courseId, String assignmentId) async {
    final user = authService.currentUser;
    if (user == null) return;

    try {
      List<Submission> submissions = [];

      if (user.lmsType == LMS.googleClassroom) {
        final googleService = GoogleClassroomService();
        submissions = await googleService.getSubmissions(
          courseId,
          assignmentId,
        );
      } else if (user.lmsType == LMS.moodle) {
        final moodleService = MoodleService();
        submissions = await moodleService.getSubmissions(
          courseId,
          assignmentId,
        );
      }

      // Process submissions for zip file extraction
      submissions = await _processSubmissionsForZip(submissions);

      setState(() {
        _submissions = submissions;
      });

      print(
        'Loaded ${submissions.length} submissions for assignment $assignmentId',
      );
    } catch (e) {
      print('Error loading submissions: $e');
      _showErrorMessage('Failed to load submissions: $e');
    }
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
                  Text(
                    'Test files ready: ${files['inputFilename']} → ${files['outputFilename']}',
                  ),
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
    if (_selectedSubmission == null || _selectedSubmission!.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No code file selected to run')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use enhanced execution with potential grading
      Map<String, dynamic> result = await _executeCodeEnhanced();

      setState(() {
        _executionResult = result;
      });

      if (mounted) {
        String message = 'Code executed successfully!';
        Color backgroundColor = Colors.blue;

        // Only show grading feedback if test files were actually used
        bool hasTestFiles =
            _useUploadedTestFiles &&
            _testFiles['hasFiles'] == true &&
            _testFiles['inputContent'] != null &&
            _testFiles['inputContent'].toString().trim().isNotEmpty;

        if (hasTestFiles) {
          // Enhanced message based on result type (only when test files are present)
          if (result['testPassed'] == true) {
            message = 'Code executed - Test PASSED! ✅';
            backgroundColor = Colors.green;
          } else if (result['testPassed'] == false) {
            message = 'Code executed - Test FAILED ❌';
            backgroundColor = Colors.orange;
          } else {
            message = 'Code executed with test files!';
            backgroundColor = Colors.blue;
          }
        } else {
          // Basic execution message (no test files)
          message = 'Code executed successfully!';
          backgroundColor = Colors.blue;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _executionResult = {
          'success': false,
          'error': e.toString(),
          'output': 'Execution failed: $e',
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Execution failed: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _executeCodeEnhanced() async {
    final mainClassName = _detectMainClassName(_selectedSubmission!.files);
    final hasMultipleFiles = _selectedSubmission!.files.length > 1;

    final payload = {
      'files': _selectedSubmission!.files
          .map(
            (file) => {
              'filename': file.filename,
              'content': file.content,
              'language': file.language,
            },
          )
          .toList(),
      'assignmentId': _selectedAssignment?.id ?? '',
      'submissionId': _selectedSubmission!.id,
      'studentId': _selectedSubmission!.studentId,
    };

    // For multi-file submissions, use mainFileName instead of mainClassName
    if (hasMultipleFiles) {
      payload['mainFileName'] = mainClassName;
      payload['packageExecution'] = true;
      print('📦 Multi-file execution: mainFileName = $mainClassName');
    } else {
      payload['mainClassName'] = mainClassName;
      print('📄 Single-file execution: mainClassName = $mainClassName');
    }

    // Add grading data if test files are uploaded
    if (_useUploadedTestFiles && _testFiles['hasFiles'] == true) {
      payload['input'] = _testFiles['inputContent'].toString().trim();
      payload['expectedOutput'] = _testFiles['outputContent'].toString().trim();
      payload['useUploadedTestFiles'] = true;
      payload['inputFilename'] = _testFiles['inputFilename'];
      payload['outputFilename'] = _testFiles['outputFilename'];
    }

    print(
      '🎯 Detected main class: $mainClassName for ${_selectedSubmission!.files.length} files',
    );
    return await _executeCode(_selectedSubmission!.primaryLanguage, payload);
  }

  Future<Map<String, dynamic>> _executeCode(
    String language,
    Map<String, dynamic> codeData,
  ) async {
    final response = await http.post(
      Uri.parse('${ServerConstants.ogServerUrl}/compiler/execute/$language'),
      headers: authService.authHeaders,
      body: json.encode(codeData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Code execution failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _executeBatch(
    Map<String, dynamic> batchPayload,
  ) async {
    final response = await http
        .post(
          Uri.parse('${ServerConstants.ogServerUrl}/compiler/batch'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...authService.authHeaders,
          },
          body: json.encode(batchPayload),
        )
        .timeout(
          const Duration(minutes: 5), // 5 minute timeout for batch operations
          onTimeout: () {
            throw Exception('Batch grading timeout after 5 minutes');
          },
        );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      await authService.handleUnauthorized();
      throw Exception('Authentication required');
    } else {
      throw Exception(
        'Batch grading server error (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> _gradeSelectedSubmission() async {
    if (_selectedSubmission == null) {
      _showGradingError(
        'Please select a submission first',
        Icons.person_outline,
      );
      return;
    }

    if (!_isGradingEnabled) {
      _showGradingError(_getGradingStatusMessage(), _getGradingStatusIcon());
      return;
    }

    if (_selectedSubmission!.files.isEmpty) {
      _showGradingError('Selected submission has no files', Icons.description);
      return;
    }

    setState(() {
      _isGrading = true;
    });

    try {
      // Build grading payload
      Map<String, dynamic> gradingPayload = {
        'files': _selectedSubmission!.files
            .map(
              (file) => {
                'filename': file.filename,
                'content': file.content,
                'language': file.language,
              },
            )
            .toList(),
        'mainClassName': _detectMainClassName(_selectedSubmission!.files),
        'mainFileName': _detectMainClassName(_selectedSubmission!.files),
        'packageExecution': _selectedSubmission!.files.length > 1,
        'assignmentId': _selectedAssignment?.id ?? '',
        'submissionId': _selectedSubmission!.id,
        'studentId': _selectedSubmission!.studentId,
        'input': _testFiles['inputContent'].toString().trim(),
        'expectedOutput': _testFiles['outputContent'].toString().trim(),
        'useUploadedTestFiles': true,
        'inputFilename': _testFiles['inputFilename'],
        'outputFilename': _testFiles['outputFilename'],
      };

      // Execute with grading
      Map<String, dynamic> result = await _executeCode(
        _selectedSubmission!.primaryLanguage,
        gradingPayload,
      );

      setState(() {
        _executionResult = result;
      });

      if (mounted) {
        // Show grading results dialog
        await _showGradeSubmissionDialog(result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _executionResult = {
          'success': false,
          'error': e.toString(),
          'output': 'Grading failed: $e',
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grading failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGrading = false;
      });
    }
  }

  String _detectMainClassName(List<CodeFile> files) {
    // For single file, use filename
    if (files.length == 1) {
      final filename = files.first.filename;
      return filename.contains('.')
          ? filename.substring(0, filename.lastIndexOf('.'))
          : filename;
    }

    // For multiple files, find the one with main method
    for (final file in files) {
      if (file.language.toLowerCase() == 'java' &&
          _hasMainMethod(file.content)) {
        // Extract class name from filename
        final filename = file.filename;
        return filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
      }
    }

    // Fallback strategies
    // 1. Look for files with "main" in the name
    for (final file in files) {
      if (file.filename.toLowerCase().contains('main')) {
        final filename = file.filename;
        return filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
      }
    }

    // 2. Use first Java file
    for (final file in files) {
      if (file.filename.toLowerCase().endsWith('.java')) {
        final filename = file.filename;
        return filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
      }
    }

    // Final fallback - use first file
    final filename = files.first.filename;
    return filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
  }

  /// Checks if a Java file contains a main method
  bool _hasMainMethod(String content) {
    if (content.isEmpty) return false;

    // Look for main method signatures
    final mainMethodPatterns = [
      RegExp(
        r'public\s+static\s+void\s+main\s*\(\s*String\s*\[\s*\]\s*\w*\s*\)',
      ),
      RegExp(
        r'public\s+static\s+void\s+main\s*\(\s*String\s*\.\.\.\s*\w*\s*\)',
      ),
      RegExp(r'static\s+void\s+main\s*\(\s*String\s*\[\s*\]\s*\w*\s*\)'),
    ];

    for (final pattern in mainMethodPatterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }

    return false;
  }

  // Add this new method for grading all submissions
  Future<void> _gradeAllSubmissions() async {
    if (!_isGradingEnabled) {
      _showGradingError(
        'Test files must be uploaded before grading all submissions',
        Icons.upload_file,
      );
      return;
    }

    if (_submissions.isEmpty) {
      _showGradingError('No submissions available to grade', Icons.inbox);
      return;
    }

    // Show confirmation dialog
    bool? confirmed = await _showGradeAllConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      _isGradingAll = true;
    });

    try {
      // Build batch grading payload
      Map<String, dynamic> batchPayload = {
        'assignmentId': _selectedAssignment?.id ?? '',
        'testInput': _testFiles['inputContent'].toString().trim(),
        'expectedOutput': _testFiles['outputContent'].toString().trim(),
        'useTestFiles': true,
        'inputFilename': _testFiles['inputFilename'],
        'outputFilename': _testFiles['outputFilename'],
        'submissions': _submissions
            .map(
              (submission) => {
                'submissionId': submission.id,
                'studentId': submission.studentId,
                'studentName': submission.studentName,
                'filename': submission.files.first.filename,
                'code': submission.files.first.content,
              },
            )
            .toList(),
      };

      print('🚀 Starting batch grading for ${_submissions.length} submissions');

      // Execute batch grading
      Map<String, dynamic> batchResult = await _executeBatch(batchPayload);

      if (mounted) {
        // Show batch grading results dialog
        await _showBatchGradingResultsDialog(batchResult);
      }
    } catch (e) {
      print('❌ Batch grading failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch grading failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGradingAll = false;
      });
    }
  }

  // Clean individual grade submission dialog
  Future<void> _showGradeSubmissionDialog(Map<String, dynamic> result) async {
    bool testPassed = result['testPassed'] ?? false;
    double similarity = (result['outputSimilarity'] ?? 0.0).toDouble();
    String grade = result['grade'] ?? 'N/A';
    String feedback = result['feedback'] ?? 'No feedback available';
    String actualOutput = result['output'] ?? '';
    String expectedOutput = result['expectedOutput'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600, // Fixed width for better control
          constraints: const BoxConstraints(
            maxHeight: 700,
          ), // Max height with scrolling
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: testPassed ? Colors.green[50] : Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: testPassed ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      testPassed ? Icons.check_circle : Icons.cancel,
                      color: testPassed ? Colors.green[600] : Colors.red[600],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testPassed ? 'Test Passed!' : 'Test Failed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: testPassed
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                          Text(
                            _selectedSubmission?.studentName ??
                                'Unknown Student',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: testPassed ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: testPassed
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grade Summary Card
                      Card(
                        elevation: 0,
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Grading Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Equivalence',
                                      '${similarity.toStringAsFixed(1)}%',
                                      similarity >= 85
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Grade',
                                      grade,
                                      testPassed ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Status',
                                      testPassed ? 'Passed' : 'Failed',
                                      testPassed ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // AI Feedback Card
                      if (feedback.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          color: Colors.purple[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.purple[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: Colors.purple[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Feedback',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.purple[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Output Comparison
                      Text(
                        'Output Comparison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutputCard(
                              'Actual Output',
                              actualOutput.isEmpty
                                  ? '(No output)'
                                  : actualOutput,
                              Colors.grey[100]!,
                              Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOutputCard(
                              'Expected Output',
                              expectedOutput.isEmpty
                                  ? '(No expected output)'
                                  : expectedOutput,
                              Colors.blue[50]!,
                              Colors.blue[600]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    if (testPassed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Grade upload to LMS - Coming soon!',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          icon: const Icon(Icons.cloud_upload, size: 18),
                          label: const Text('Upload Grade'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for statistics items
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Helper widget for output cards
  Widget _buildOutputCard(
    String title,
    String content,
    Color backgroundColor,
    Color titleColor,
  ) {
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: titleColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clean batch grading results dialog
  Future<void> _showBatchGradingResultsDialog(
    Map<String, dynamic> batchResult,
  ) async {
    // Extract batch results
    Map<String, dynamic> results = batchResult['results'] ?? {};
    int totalSubmissions = batchResult['totalSubmissions'] ?? 0;
    int successfulExecutions = batchResult['successfulExecutions'] ?? 0;
    int failedExecutions = batchResult['failedExecutions'] ?? 0;
    int passedTests = batchResult['passedTests'] ?? 0;
    int failedTests = batchResult['failedTests'] ?? 0;
    double averageSimilarity = (batchResult['averageSimilarity'] ?? 0.0)
        .toDouble();
    Map<String, dynamic> gradeDistribution =
        batchResult['gradeDistribution'] ?? {};

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700, // Fixed width
          constraints: const BoxConstraints(
            maxHeight: 800,
          ), // Max height with scrolling
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.purple[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.batch_prediction,
                      color: Colors.purple[600],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Batch Grading Results',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalSubmissions submissions processed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$passedTests/$totalSubmissions Passed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildBatchStatCard(
                              'Success Rate',
                              '${((successfulExecutions / totalSubmissions) * 100).toStringAsFixed(1)}%',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBatchStatCard(
                              'Avg Equivalence',
                              '${averageSimilarity.toStringAsFixed(1)}%',
                              Icons.analytics,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBatchStatCard(
                              'Test Pass Rate',
                              '${((passedTests / totalSubmissions) * 100).toStringAsFixed(1)}%',
                              Icons.assignment_turned_in,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Grade Distribution
                      if (gradeDistribution.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          color: Colors.orange[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.orange[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      color: Colors.orange[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Grade Distribution',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: gradeDistribution.entries.map((
                                    entry,
                                  ) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${entry.key}: ${entry.value}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Individual Results
                      Text(
                        'Individual Results (${results.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final entry = results.entries.elementAt(index);
                            String submissionId = entry.key;
                            Map<String, dynamic> result = entry.value;

                            var submission = _submissions
                                .where((s) => s.id == submissionId)
                                .firstOrNull;

                            bool testPassed = result['testPassed'] ?? false;
                            double similarity =
                                (result['outputSimilarity'] ?? 0.0).toDouble();
                            String grade = result['grade'] ?? 'N/A';

                            return InkWell(
                              onTap: () => _showIndividualResultDialog(
                                submission,
                                result,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: testPassed
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: testPassed
                                        ? Colors.green[200]!
                                        : Colors.red[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      testPassed
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: testPassed
                                          ? Colors.green[600]
                                          : Colors.red[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            submission?.studentName ??
                                                'Unknown Student',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Equivalence: ${similarity.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: testPassed
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        grade,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: testPassed
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exportBatchResults(batchResult);
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Export Results'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for batch statistics cards
  Widget _buildBatchStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Export batch results to CSV
  Future<void> _exportBatchResults(Map<String, dynamic> batchResult) async {
    try {
      Map<String, dynamic> results = batchResult['results'] ?? {};

      // Create CSV content
      List<List<String>> csvData = [
        [
          'Student Name',
          'Submission ID',
          'Test Passed',
          'Grade',
          'Equivalence %',
          'Feedback',
        ],
      ];

      for (var entry in results.entries) {
        String submissionId = entry.key;
        Map<String, dynamic> result = entry.value;

        var submission = _submissions
            .where((s) => s.id == submissionId)
            .firstOrNull;

        csvData.add([
          submission?.studentName ?? 'Unknown',
          submissionId,
          (result['testPassed'] ?? false).toString(),
          result['grade'] ?? 'N/A',
          ((result['outputSimilarity'] ?? 0.0).toDouble()).toStringAsFixed(1),
          (result['feedback'] ?? '').replaceAll('\n', ' '),
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Download file (web)
      if (kIsWeb) {
        final bytes = utf8.encode(csvString);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download =
              'batch_grading_results_${DateTime.now().millisecondsSinceEpoch}.csv';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch grading results exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show individual result from batch grading
  Future<void> _showIndividualResultDialog(
    dynamic submission,
    Map<String, dynamic> result,
  ) async {
    bool testPassed = result['testPassed'] ?? false;
    double similarity = (result['outputSimilarity'] ?? 0.0).toDouble();
    String grade = result['grade'] ?? 'N/A';
    String feedback = result['feedback'] ?? 'No feedback available';
    String actualOutput = result['output'] ?? '';
    String expectedOutput = result['expectedOutput'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600, // Fixed width for better control
          constraints: const BoxConstraints(
            maxHeight: 700,
          ), // Max height with scrolling
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: testPassed ? Colors.green[50] : Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: testPassed ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      testPassed ? Icons.check_circle : Icons.cancel,
                      color: testPassed ? Colors.green[600] : Colors.red[600],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testPassed ? 'Test Passed!' : 'Test Failed',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: testPassed
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                          Text(
                            _selectedSubmission?.studentName ??
                                'Unknown Student',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: testPassed ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: testPassed
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grade Summary Card
                      Card(
                        elevation: 0,
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Grading Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Equivalence',
                                      '${similarity.toStringAsFixed(1)}%',
                                      similarity >= 85
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Grade',
                                      grade,
                                      testPassed ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Status',
                                      testPassed ? 'Passed' : 'Failed',
                                      testPassed ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // AI Feedback Card
                      if (feedback.isNotEmpty) ...[
                        Card(
                          elevation: 0,
                          color: Colors.purple[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.purple[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: Colors.purple[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Feedback',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.purple[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Output Comparison
                      Text(
                        'Output Comparison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutputCard(
                              'Actual Output',
                              actualOutput.isEmpty
                                  ? '(No output)'
                                  : actualOutput,
                              Colors.grey[100]!,
                              Colors.grey[600]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOutputCard(
                              'Expected Output',
                              expectedOutput.isEmpty
                                  ? '(No expected output)'
                                  : expectedOutput,
                              Colors.blue[50]!,
                              Colors.blue[600]!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mock grading provider for compatibility with dialog
  dynamic _createMockGradingProvider() {
    final user = authService.currentUser;
    return MockGradingProvider(
      currentPlatform: user?.lmsType.toString().split('.').last ?? 'unknown',
    );
  }

  Future<void> _uploadSelectedGradesToPlatform(
    List<Map<String, dynamic>> selectedResults,
  ) async {
    try {
      final user = authService.currentUser;
      final platform = user?.lmsType;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Uploading Grades...'),
            ],
          ),
          content: Text(
            'Uploading ${selectedResults.length} selected grades...',
          ),
        ),
      );

      // Simulate grade upload (replace with actual API calls)
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Successfully uploaded ${selectedResults.length} grades to ${platform.toString().split('.').last}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      try {
        Navigator.of(context).pop(); // Close loading dialog
      } catch (e) {
        // Dialog might already be closed
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to upload grades: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Add missing utility methods
  void _showGradingError(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _getGradingStatusMessage() {
    if (!_useUploadedTestFiles) {
      return 'Enable "Use Uploaded Test Files" first';
    }
    if (_testFiles['hasFiles'] != true) {
      return 'Upload test files using the toolbar button';
    }
    if (_testFiles['inputContent'] == null ||
        _testFiles['inputContent'].toString().trim().isEmpty) {
      return 'Input file is empty or missing';
    }
    if (_testFiles['outputContent'] == null ||
        _testFiles['outputContent'].toString().trim().isEmpty) {
      return 'Output file is empty or missing';
    }
    return 'Test files are not properly configured';
  }

  IconData _getGradingStatusIcon() {
    if (!_useUploadedTestFiles) return Icons.toggle_off;
    if (_testFiles['hasFiles'] != true) return Icons.upload_file;
    return Icons.error_outline;
  }

  // Add the confirmation dialog
  Future<bool?> _showGradeAllConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grade All Submissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to grade all ${_submissions.length} submissions?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Execute ${_submissions.length} submissions with test files',
                  ),
                  const Text('• Generate automatic grades and feedback'),
                  const Text('• May take several minutes to complete'),
                  const Text('• Process submissions in parallel for speed'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
            child: const Text('Grade All'),
          ),
        ],
      ),
    );
  }

  Future<List<Submission>> _processSubmissionsForZip(
    List<Submission> rawSubmissions,
  ) async {
    List<Submission> processedSubmissions = [];

    for (final submission in rawSubmissions) {
      try {
        // Check if this submission contains a zip file
        bool hasZipFile = false;
        CodeFile? zipFile;

        for (final file in submission.files) {
          // Check for .zip extension or zip-like content
          if (file.filename.toLowerCase().endsWith('.zip') ||
              _isZipContent(file.content)) {
            hasZipFile = true;
            zipFile = file;
            break;
          }
        }

        if (hasZipFile && zipFile != null) {
          print(
            'Processing zip submission for student: ${submission.studentName}',
          );

          // Try to extract the zip file
          try {
            // Convert content to Uint8List (handle different formats)
            Uint8List zipData = _convertContentToBytes(zipFile.content);

            // Validate zip file first
            final validation = ZipSubmissionHandler.validateZipFile(zipData);
            if (!validation.isValid) {
              throw Exception(validation.error ?? 'Invalid zip file');
            }

            // Extract files from zip
            List<CodeFile> extractedFiles =
                ZipSubmissionHandler.extractFilesFromZip(zipData);

            if (extractedFiles.isEmpty) {
              throw Exception('No supported code files found in zip archive');
            }

            // Create new submission with extracted files
            final extractedSubmission = Submission(
              id: submission.id,
              assignmentId: submission.assignmentId,
              studentId: submission.studentId,
              studentName: submission.studentName,
              files: extractedFiles, // Replace zip with extracted files
              submittedAt: submission.submittedAt,
              status: submission.status,
              platform: submission.platform,
            );

            processedSubmissions.add(extractedSubmission);
            print(
              'Successfully extracted ${extractedFiles.length} files from zip for ${submission.studentName}',
            );
          } catch (e) {
            print('Failed to extract zip for ${submission.studentName}: $e');

            // Create error submission to show teacher that extraction failed
            final errorSubmission = _createZipErrorSubmission(
              submission,
              e.toString(),
            );
            processedSubmissions.add(errorSubmission);
          }
        } else {
          // Normal submission (not a zip), add as-is
          processedSubmissions.add(submission);
        }
      } catch (e) {
        print('Error processing submission for ${submission.studentName}: $e');
        // Add original submission if general processing fails
        processedSubmissions.add(submission);
      }
    }

    return processedSubmissions;
  }

  /// Detects if content appears to be zip file data
  bool _isZipContent(String content) {
    // Check for common zip file signatures
    if (content.isEmpty) return false;

    // Data URL format
    if (content.startsWith('data:application/zip;base64,')) {
      return true;
    }

    // Base64 encoded zip typically starts with "UEs" (PK signature)
    if (content.startsWith('UEs') || content.startsWith('UEsDB')) {
      return true;
    }

    // Raw binary content detection (zip magic bytes)
    // From your example: content starts with "PK\u0003\u0004"
    if (content.length >= 4) {
      List<int> codeUnits = content.codeUnits;
      // Check for PK signature (0x50, 0x4B) followed by zip version
      return codeUnits[0] == 0x50 && codeUnits[1] == 0x4B;
    }

    return false;
  }

  /// Converts string content to Uint8List for zip processing
  Uint8List _convertContentToBytes(String content) {
    try {
      // Remove data URL prefix if present
      String cleanContent = content;
      if (content.startsWith('data:application/zip;base64,')) {
        cleanContent = content.substring('data:application/zip;base64,'.length);
        // If it's a data URL, decode as base64
        return base64Decode(cleanContent);
      }

      // For raw binary data (like from your example), convert string code units to bytes
      // This handles the case where zip binary data is directly embedded in the JSON string
      return Uint8List.fromList(content.codeUnits);
    } catch (e) {
      throw Exception('Unable to convert content to bytes: $e');
    }
  }

  /// Creates a special error submission when zip extraction fails
  Submission _createZipErrorSubmission(
    Submission originalSubmission,
    String errorMessage,
  ) {
    final errorFile = CodeFile(
      filename: 'ZIP_EXTRACTION_ERROR.txt',
      content:
          '''
Zip Extraction Failed
====================

Student: ${originalSubmission.studentName}
Original filename: ${originalSubmission.files.isNotEmpty ? originalSubmission.files.first.filename : 'Unknown'}
Error: $errorMessage

This student submitted a zip file but the Code Compiler failed to extract the code files.

Please contact the student to resubmit their files individually or check the original submission manually.
      '''
              .trim(),
      language: 'text',
    );

    return Submission(
      id: originalSubmission.id,
      assignmentId: originalSubmission.assignmentId,
      studentId: originalSubmission.studentId,
      studentName:
          '⚠️ ${originalSubmission.studentName}', // Add warning indicator
      files: [errorFile],
      submittedAt: originalSubmission.submittedAt,
      status: 'zip_error', // Special status for error submissions
      platform: originalSubmission.platform,
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Check auth status and redirect if not logged in
        if (!authService.isLoggedIn || authService.currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppNavbar(
            title: 'Code Compiler',
            onHomePressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherHomeScreen(),
                ),
              );
            },
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 120, minHeight: 32),
                child: TestFileUploadWidget(
                  assignmentId: _selectedAssignment?.id,
                  onFilesChanged: _handleTestFilesChanged,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                constraints: const BoxConstraints(minWidth: 80, minHeight: 32),
                child: ElevatedButton.icon(
                  onPressed: (_selectedSubmission != null && !_isLoading)
                      ? _runCode
                      : null,
                  icon: _isLoading
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
                    _isLoading ? 'Running...' : 'Run',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _sidebarCollapsed ? 50 : 350,
                    height: constraints.maxHeight,
                    child: _buildSidebar(),
                  ),

                  Expanded(
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _buildCodeEditorPanel()),

                          Expanded(flex: 2, child: _buildOutputPanel()),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: _lightBackgroundColor,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: _sidebarCollapsed
          ? _buildCollapsedSidebar()
          : _buildExpandedSidebar(),
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
    return Container(
      color: _lightBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Code Compiler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryTextColor,
                    letterSpacing: 0.15,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sidebarCollapsed = true;
                    });
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Course Dropdown
            _buildCourseDropdown(),
            const SizedBox(height: 12),

            // Assignment Dropdown
            _buildAssignmentDropdown(),
            const SizedBox(height: 16),

            // Submissions List
            const Text(
              'Submissions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: _primaryTextColor,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 8),

            Flexible(flex: 1, child: _buildSubmissionsList()),

            const SizedBox(height: 16),

            // Grading Actions
            _buildGradingActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 6),
            const Text(
              'Select Course',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _primaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _cardBackgroundColor,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoading && _courses.isEmpty
              ? const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading courses...'),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCourse?.id,
                    hint: Row(
                      children: [
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        const Text(
                          'Choose a course',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.expand_more, color: Colors.blue[600]),
                    items: _courses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                course.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onCourseSelected,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAssignmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment, size: 16, color: Colors.green[600]),
            const SizedBox(width: 6),
            const Text(
              'Select Assignment',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _primaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _selectedCourse != null
                ? _cardBackgroundColor
                : Colors.grey[100],
            border: Border.all(
              color: _selectedCourse != null ? _borderColor : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _selectedCourse != null
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: _isLoadingAssignments
              ? const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading assignments...'),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAssignment?.id,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.arrow_drop_down,
                          color: _selectedCourse != null
                              ? Colors.grey[600]
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedCourse != null
                                ? 'Choose an assignment'
                                : 'Select a course first',
                            style: TextStyle(
                              color: _selectedCourse != null
                                  ? Colors.grey
                                  : Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.expand_more,
                      color: _selectedCourse != null
                          ? Colors.green[600]
                          : Colors.grey[400],
                    ),
                    items: _assignments.map((assignment) {
                      return DropdownMenuItem<String>(
                        value: assignment.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                assignment.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const SizedBox(width: 8),
                                  if (assignment.maxPoints != null) ...[
                                    Icon(
                                      Icons.grade,
                                      size: 10,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${assignment.maxPoints!.toInt()} pts',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedCourse != null
                        ? _onAssignmentSelected
                        : null,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsList() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackgroundColor,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isLoadingSubmissions
            ? SizedBox(height: 200, child: _buildSubmissionsLoadingWidget())
            : _submissions.isEmpty
            ? _buildEmptySubmissionsWidget()
            : ListView.builder(
                padding: const EdgeInsets.all(6),
                itemCount: _submissions.length,
                itemBuilder: (context, index) {
                  final submission = _submissions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildSubmissionListItem(submission),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSubmissionsLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Loading submissions...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubmissionsWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No submissions found',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedAssignment != null
              ? 'No students have submitted work for this assignment yet'
              : 'Select an assignment to view submissions',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSubmissionListItem(Submission submission) {
    final bool hasMultipleFiles = submission.hasMultipleFiles;
    final bool isZip = submission.isZipSubmission;
    final bool hasAutoGrade = _gradingResults.containsKey(submission.id);
    final bool isZipError = submission.status == 'zip_error';
    final Map<String, dynamic>? gradingResult = _gradingResults[submission.id];
    final bool isCurrentlySelected = _selectedSubmission?.id == submission.id;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentlySelected ? Colors.blue[50] : _cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentlySelected ? Colors.blue[300]! : _borderColor,
          width: isCurrentlySelected ? 2 : 1,
        ),
        boxShadow: isCurrentlySelected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: hasAutoGrade
              ? (gradingResult!['success'] == false
                    ? _errorColor
                    : _getGradeColor(gradingResult['grade'] ?? 'F'))
              : isZipError
              ? Colors.orange[600] // Orange for zip extraction errors
              : Colors.blue[600],
          child: hasAutoGrade
              ? Text(
                  gradingResult!['success'] == false
                      ? '✗'
                      : (gradingResult['grade'] ?? 'F'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : Icon(
                  isZipError
                      ? Icons
                            .warning // Warning icon for zip errors
                      : isZip
                      ? Icons.folder_zip
                      : hasMultipleFiles
                      ? Icons.folder
                      : Icons.description,
                  color: Colors.white,
                  size: 20,
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                submission.studentName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isCurrentlySelected
                      ? Colors.blue[800]
                      : _primaryTextColor,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (isCurrentlySelected) ...[
              Icon(
                Icons.radio_button_checked,
                size: 16,
                color: Colors.blue[600],
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (hasMultipleFiles) ...[
                Text(
                  '${submission.files.length} files${isZip ? ' (ZIP)' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  submission.files.isNotEmpty
                      ? submission.files.first.filename
                      : 'No files',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _mutedTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLanguageColor(
                    submission.primaryLanguage,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  submission.primaryLanguage.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getLanguageColor(submission.primaryLanguage),
                  ),
                ),
              ),
              if (isZipError) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange[300]!, width: 1),
                  ),
                  child: Text(
                    'ZIP EXTRACTION FAILED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        onTap: () => _selectSubmissionWithFeedback(submission),
      ),
    );
  }

  void _selectSubmissionWithFeedback(Submission submission) {
    final bool differentSubmission = _selectedSubmission?.id != submission.id;

    if (differentSubmission) {
      setState(() {
        _selectedSubmission = submission;
      });

      if (_gradingResults.containsKey(submission.id)) {
        setState(() {
          _executionResult = _gradingResults[submission.id]!;
        });

        final result = _gradingResults[submission.id]!;
        final grade = result['grade'] ?? 'Unknown';
        final similarity = result['outputSimilarity'] ?? 0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${submission.studentName} - Saved Results'),
                        Text(
                          'Grade: $grade | Equivalence: $similarity%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Selected: ${submission.studentName}'),
                ],
              ),
              backgroundColor: Colors.blue[600],
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  Widget _buildGradingActions() {
    bool hasSubmissions = _submissions.isNotEmpty;
    bool isGradingEnabled =
        _useUploadedTestFiles &&
        _testFiles['hasFiles'] == true &&
        _testFiles['inputContent'] != null &&
        _testFiles['inputContent'].toString().trim().isNotEmpty &&
        _testFiles['outputContent'] != null &&
        _testFiles['outputContent'].toString().trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grade, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Grading Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Grade Selected Submission Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (isGradingEnabled &&
                      _selectedSubmission != null &&
                      !_isGrading &&
                      !_isGradingAll)
                  ? _gradeSelectedSubmission
                  : null,
              icon: _isGrading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.grade, size: 16),
              label: Text(
                _isGrading
                    ? 'Grading...'
                    : _selectedSubmission != null
                    ? 'Grade "${_selectedSubmission!.studentName}"'
                    : 'Grade Selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGradingEnabled
                    ? Colors.green[600]
                    : Colors.grey[200],
                disabledBackgroundColor: Colors.grey[200],
                foregroundColor: isGradingEnabled
                    ? Colors.white
                    : Colors.grey[600],
                disabledForegroundColor: Colors.grey[600],
                elevation: isGradingEnabled ? 2 : 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isGradingEnabled
                        ? Colors.transparent
                        : Colors.grey[400]!,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Grade All Submissions Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (isGradingEnabled &&
                      hasSubmissions &&
                      !_isGrading &&
                      !_isGradingAll)
                  ? _gradeAllSubmissions
                  : null,
              icon: _isGradingAll
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.batch_prediction, size: 16),
              label: Text(
                _isGradingAll
                    ? 'Grading All...'
                    : 'Grade All (${_submissions.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGradingEnabled
                    ? Colors.purple[600]
                    : Colors.grey[200],
                disabledBackgroundColor: Colors.grey[200],
                foregroundColor: isGradingEnabled
                    ? Colors.white
                    : Colors.grey[600],
                disabledForegroundColor: Colors.grey[600],
                elevation: isGradingEnabled ? 2 : 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isGradingEnabled
                        ? Colors.transparent
                        : Colors.grey[400]!,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          if (!isGradingEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasSubmissions
                        ? 'Upload test files using toolbar button to enable grading'
                        : 'Load submissions first, then upload test files to enable grading',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeEditorPanel() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Code Editor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (_selectedSubmission != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                          _selectedSubmission!.studentName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _selectedSubmission != null
                ? CodeEditor(files: _selectedSubmission!.files, readOnly: true)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a submission to view code',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Code Output',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (_executionResult != null &&
                    _selectedSubmission != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                          _selectedSubmission!.studentName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _executionResult != null
                      ? () {
                          setState(() {
                            _executionResult = null;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.clear,
                    size: 14,
                    color: _executionResult != null
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  label: Text(
                    'Clear',
                    style: TextStyle(
                      color: _executionResult != null
                          ? Colors.grey[600]
                          : Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minimumSize: const Size(0, 0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Running code...'),
                        ],
                      ),
                    )
                  : _executionResult != null
                  ? _buildEnhancedExecutionResult(_executionResult!)
                  : _buildOutputPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedExecutionResult(Map<String, dynamic> result) {
    final output = result['output'] ?? '';
    final expectedOutput = result['expectedOutput'] ?? '';
    final hasError =
        result['error'] != null && result['error'].toString().isNotEmpty;
    final success = result['success'] ?? !hasError;

    // Check if this was actually a grading execution (has test files)
    bool wasGradingExecution =
        _useUploadedTestFiles &&
        _testFiles['hasFiles'] == true &&
        _testFiles['inputContent'] != null &&
        _testFiles['inputContent'].toString().trim().isNotEmpty;

    // Only show grading data if it was actually a grading execution
    final testPassed = wasGradingExecution
        ? (result['testPassed'] ?? false)
        : null;
    final similarity = wasGradingExecution
        ? (result['outputSimilarity'] ?? 0)
        : null;
    final feedback = wasGradingExecution ? (result['feedback'] ?? '') : null;
    final grade = wasGradingExecution ? (result['grade'] ?? '') : null;
    final executionTime =
        result['executionTimeMs'] ?? result['executionTime'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Execution Status Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: success ? Colors.green[50] : Colors.red[50],
            border: Border.all(
              color: success ? Colors.green[200]! : Colors.red[200]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'Code Executed' : 'Execution Failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const Spacer(),
              if (executionTime > 0) ...[
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${executionTime}ms',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Grading Information (only if test files were used)
        if (wasGradingExecution && testPassed != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: testPassed! ? Colors.green[50] : Colors.orange[50],
              border: Border.all(
                color: testPassed! ? Colors.green[200]! : Colors.orange[200]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      testPassed! ? Icons.check_circle : Icons.cancel,
                      color: testPassed!
                          ? Colors.green[600]
                          : Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      testPassed! ? 'Test Passed!' : 'Test Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: testPassed!
                            ? Colors.green[800]
                            : Colors.orange[800],
                      ),
                    ),
                    const Spacer(),
                    if (grade != null && grade.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: testPassed!
                              ? Colors.green[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Grade: $grade',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: testPassed!
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (similarity != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Output Equivalence: ${similarity.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
                if (feedback != null && feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'AI Feedback:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feedback,
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Program Output
        Text(
          'Program Output:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            output.isEmpty ? '(No output)' : output,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),

        // Error Display
        if (hasError) ...[
          const SizedBox(height: 12),
          Text(
            'Error Details:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result['error'].toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.red[800],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOutputComparison(
    String actualOutput,
    String expectedOutput,
    double similarity,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: similarity >= 90
            ? Colors.green[50]
            : (similarity >= 70 ? Colors.orange[50] : Colors.red[50]),
        border: Border.all(
          color: similarity >= 90
              ? Colors.green[200]!
              : (similarity >= 70 ? Colors.orange[200]! : Colors.red[200]!),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                similarity >= 90
                    ? Icons.check_circle
                    : (similarity >= 70 ? Icons.warning : Icons.error),
                size: 16,
                color: similarity >= 90
                    ? Colors.green[600]
                    : (similarity >= 70 ? Colors.orange[600] : Colors.red[600]),
              ),
              const SizedBox(width: 8),
              const Text(
                'Output Comparison:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSimilarityColor(similarity),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${similarity.toStringAsFixed(2)}% Match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Output:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expectedOutput,
                        style: const TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Output:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: similarity >= 90
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: similarity >= 90
                            ? Colors.green[50]
                            : Colors.red[50],
                        border: Border.all(
                          color: similarity >= 90
                              ? Colors.green[200]!
                              : Colors.red[200]!,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        actualOutput,
                        style: const TextStyle(
                          fontFamily: 'Courier New',
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black87,
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
    );
  }

  Widget _buildProgramOutputSection(String output) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Program Output:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${output.length} characters',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: Text(
                output,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, size: 16, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text(
                'Execution Error:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              error,
              style: const TextStyle(
                fontFamily: 'Courier New',
                color: Colors.red,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Click "Run" to execute code or use "Grade" buttons for automatic assessment.',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Grading Options:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '• Grade Submission: Grade the selected submission\n'
          '• Run: Execute code without grading\n'
          '• Upload test files to enable automatic grading',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 16),

        if (_useUploadedTestFiles) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Test Files Ready',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_testFiles['inputFilename'] != null)
                  Text('📥 Input: ${_testFiles['inputFilename']}'),
                if (_testFiles['outputFilename'] != null)
                  Text('📤 Expected: ${_testFiles['outputFilename']}'),
                const SizedBox(height: 8),
                Text(
                  'Automatic grading and comparison enabled.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'No Test Files',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload test files using the toolbar button to enable automatic grading.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return Colors.orange[700]!;
      case 'python':
        return Colors.blue[700]!;
      case 'javascript':
      case 'js':
        return Colors.yellow[700]!;
      case 'cpp':
      case 'c++':
        return Colors.indigo[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green[600]!;
      case 'B':
        return Colors.lightGreen[600]!;
      case 'C':
        return Colors.yellow[700]!;
      case 'D':
        return Colors.orange[600]!;
      case 'F':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 90) return Colors.green[600]!;
    if (similarity >= 80) return Colors.lightGreen[600]!;
    if (similarity >= 70) return Colors.yellow[700]!;
    if (similarity >= 60) return Colors.orange[600]!;
    return Colors.red[600]!;
  }
}

class MockGradingProvider implements GradingProviderInterface {
  @override
  final String currentPlatform;

  MockGradingProvider({required this.currentPlatform});

  @override
  String get uploadButtonText {
    switch (currentPlatform.toLowerCase()) {
      case 'moodle':
        return 'Upload to Moodle';
      case 'googleclassroom':
      default:
        return 'Upload Grade';
    }
  }

  @override
  IconData get uploadButtonIcon {
    switch (currentPlatform.toLowerCase()) {
      case 'moodle':
        return Icons.school;
      case 'googleclassroom':
        return Icons.cloud_upload;
      default:
        return Icons.cloud_upload;
    }
  }
}

// Interface for grading provider compatibility
abstract class GradingProviderInterface {
  String get currentPlatform;
  String get uploadButtonText;
  IconData get uploadButtonIcon;
}
