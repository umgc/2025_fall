// lib/widgets/batch_results_dialog.dart
// ENHANCED VERSION - Adds export functionality and better error messages

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/batch_execution_result.dart';
import '../models/submission.dart';
import '../models/assignment.dart';
import '../services/code_execution_service.dart';
import '../services/enhanced_grading_service.dart';

class BatchResultsDialog extends StatefulWidget {
  final BatchExecutionResult result;
  final List<StudentSubmission> submissions;
  final Assignment? assignment;
  final String? courseId;
  final Function(String) onViewSubmission;
  final VoidCallback onClose;
  final EnhancedGradingService? gradingService;

  const BatchResultsDialog({
    super.key,
    required this.result,
    required this.submissions,
    this.assignment,
    this.courseId,
    required this.onViewSubmission,
    required this.onClose,
    this.gradingService,
  });

  @override
  State<BatchResultsDialog> createState() => _BatchResultsDialogState();
}

class _BatchResultsDialogState extends State<BatchResultsDialog> {
  bool _isSubmittingGrades = false;
  bool _isExporting = false;
  Map<String, double> _calculatedGrades = {};
  Map<String, String> _gradeFeedback = {};
  bool _gradesCalculated = false;

  @override
  void initState() {
    super.initState();
    _calculateGradesFromResults();
  }

  /// Calculate grades based on execution results
  void _calculateGradesFromResults() {
    if (widget.assignment == null) return;

    final maxScore = widget.assignment!.maxScore.toDouble();
    
    for (final submission in widget.submissions) {
      final submissionResult = widget.result.getResultForSubmission(submission.id ?? '');
      
      if (submissionResult != null) {
        // Calculate grade based on execution success
        double grade;
        String feedback;
        
        if (submissionResult.success) {
          // Full points for successful execution
          grade = maxScore;
          feedback = '''✅ Excellent work! Your code executed successfully.

📊 Execution Results:
${submissionResult.hasOutput ? "Output:\n${submissionResult.output}\n" : ""}
⏱️ Execution time: ${submissionResult.executionTimeFormatted}
🏗️ Platform: ${submissionResult.architecture}

Keep up the great programming! 🚀''';
        } else {
          // Partial credit based on error type
          if (submissionResult.isCompilationError) {
            grade = maxScore * 0.3; // 30% for compilation errors
            feedback = '''⚠️ Compilation Error Detected

Your code has syntax or compilation issues that need to be fixed.

🔍 Error Details:
${submissionResult.error}

💡 Suggestions:
• Check your syntax carefully (parentheses, brackets, semicolons)
• Verify variable names and spelling
• Ensure proper indentation (especially in Python)
• Look for missing imports or declarations

Don't give up - debugging is part of learning! 🛠️''';
          } else if (submissionResult.isRuntimeError) {
            grade = maxScore * 0.5; // 50% for runtime errors
            feedback = '''❌ Runtime Error Detected

Your code compiled successfully but encountered an error during execution.

🔍 Error Details:
${submissionResult.error}

💡 Suggestions:
• Check for division by zero
• Verify array/list bounds
• Ensure variables are initialized before use
• Test with different input values

You're on the right track - just need to fix the logic! 🔧''';
          } else {
            grade = 0.0; // No points for other failures
            feedback = '''❌ Execution Failed

Your code could not be executed successfully.

🔍 Error Details:
${submissionResult.error}

💡 General Suggestions:
• Review the error message carefully
• Test your code with simple inputs first
• Break down complex problems into smaller parts
• Ask for help if you're stuck!

Keep practicing - programming takes time to master! 📚''';
          }
        }
        
        _calculatedGrades[submission.id ?? ''] = grade;
        _gradeFeedback[submission.id ?? ''] = feedback;
      } else {
        // No execution result available
        _calculatedGrades[submission.id ?? ''] = 0.0;
        _gradeFeedback[submission.id ?? ''] = 'No execution result available. Please contact your instructor.';
      }
    }
    
    setState(() {
      _gradesCalculated = true;
    });
  }

  /// Export results to CSV file
  Future<void> _exportResults() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final csvContent = _generateCSVContent();
      final fileName = 'batch_execution_results_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      // Create blob and download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Results exported to $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  /// Generate CSV content from results
  String _generateCSVContent() {
    final lines = <String>[];
    
    // Add header
    lines.add('Student Name,Student ID,Filename,Execution Status,Grade,Grade Percentage,Output,Error,Execution Time,Language');
    
    // Add data rows
    for (final submission in widget.submissions) {
      final submissionResult = widget.result.getResultForSubmission(submission.id ?? '');
      final grade = _calculatedGrades[submission.id ?? ''] ?? 0.0;
      final maxScore = widget.assignment?.maxScore ?? 100;
      final percentage = maxScore > 0 ? (grade / maxScore) * 100 : 0.0;
      
      final row = [
        _escapeCsvField(submission.studentName),
        _escapeCsvField(submission.studentId),
        _escapeCsvField(submission.filename),
        submissionResult?.success == true ? 'Success' : 'Failed',
        grade.toStringAsFixed(1),
        '${percentage.toStringAsFixed(1)}%',
        _escapeCsvField(submissionResult?.output ?? ''),
        _escapeCsvField(submissionResult?.error ?? ''),
        submissionResult?.executionTimeFormatted ?? '',
        submissionResult?.language ?? '',
      ];
      
      lines.add(row.join(','));
    }
    
    // Add summary at the end
    lines.add('');
    lines.add('SUMMARY');
    lines.add('Total Submissions,${widget.result.totalSubmissions}');
    lines.add('Successful Executions,${widget.result.successfulExecutions}');
    lines.add('Failed Executions,${widget.result.failedExecutions}');
    lines.add('Success Rate,${widget.result.successRate.toStringAsFixed(1)}%');
    lines.add('Total Execution Time,${widget.result.executionTimeFormatted}');
    lines.add('Average Grade,${_getAverageGrade().toStringAsFixed(1)}/${widget.assignment?.maxScore ?? 100}');
    lines.add('Passing Students (≥70%),${_getPassingCount()}/${widget.submissions.length}');
    lines.add('Export Date,${DateTime.now().toIso8601String()}');
    
    return lines.join('\n');
  }

  /// Escape CSV field to handle commas, quotes, and newlines
  String _escapeCsvField(String field) {
    // Remove newlines and replace with spaces
    String escaped = field.replaceAll('\n', ' ').replaceAll('\r', ' ');
    
    // If field contains comma, quote, or space, wrap in quotes
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      // Escape existing quotes by doubling them
      escaped = escaped.replaceAll('"', '""');
      return '"$escaped"';
    }
    
    return escaped;
  }

  /// Submit all calculated grades to Google Classroom with enhanced error handling
  Future<void> _submitAllGradesToClassroom() async {
    if (widget.gradingService == null || 
        widget.assignment == null || 
        widget.courseId == null) {
      _showGradeSubmissionErrorDialog('Missing required information for grade submission');
      return;
    }

    setState(() {
      _isSubmittingGrades = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;
      List<String> failedSubmissions = [];
      String? primaryError;

      // Submit grades one by one
      for (final submission in widget.submissions) {
        try {
          final submissionId = submission.id;
          if (submissionId == null) {
            failureCount++;
            failedSubmissions.add('${submission.studentName} (No submission ID)');
            continue;
          }

          final grade = _calculatedGrades[submissionId] ?? 0.0;
          final feedback = _gradeFeedback[submissionId] ?? '';

          await widget.gradingService!.submitGradeToClassroom(
            courseId: widget.courseId!,
            assignmentId: widget.assignment!.id,
            submissionId: submissionId,
            studentId: submission.studentId,
            grade: grade,
            feedback: feedback,
          );

          successCount++;
          print('✅ Grade submitted for ${submission.studentName}: ${grade.toStringAsFixed(1)}/${widget.assignment!.maxScore}');

        } catch (e) {
          failureCount++;
          failedSubmissions.add('${submission.studentName}');
          
          // Capture the primary error type
          if (primaryError == null) {
            primaryError = e.toString();
          }
          
          print('❌ Failed to submit grade for ${submission.studentName}: $e');
        }
      }

      setState(() {
        _isSubmittingGrades = false;
      });

      // Show appropriate results based on the errors
      if (failureCount > 0 && primaryError != null && primaryError!.contains('ProjectPermissionDenied')) {
        _showProjectPermissionDeniedDialog(successCount, failureCount);
      } else {
        _showSubmissionResultsDialog(successCount, failureCount, failedSubmissions);
      }

    } catch (e) {
      setState(() {
        _isSubmittingGrades = false;
      });
      
      // Check if it's the specific ProjectPermissionDenied error
      if (e.toString().contains('ProjectPermissionDenied')) {
        _showProjectPermissionDeniedDialog(0, widget.submissions.length);
      } else {
        _showGradeSubmissionErrorDialog('Batch grade submission failed: $e');
      }
    }
  }

  /// Show user-friendly ProjectPermissionDenied dialog
  void _showProjectPermissionDeniedDialog(int successCount, int failureCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cannot Submit Grades'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                          'Why can\'t I submit grades?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '🔒 Google Classroom Security Policy:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('You can only grade assignments that were created by the same Google Cloud Console project (this app).'),
                    SizedBox(height: 12),
                    Text('This assignment was created manually in Google Classroom, not through this grading app.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '💡 What you can do:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('1. 📝 Save grades locally in this app (your grades are still calculated!)'),
              const Text('2. 📋 Export results to CSV and import into Google Classroom'),
              const Text('3. ✏️ Manually enter grades in Google Classroom'),
              const Text('4. 🆕 For future assignments, use the "Create Assignment" button in this app'),
              
              if (successCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '✅ Successfully submitted: $successCount grades\n❌ Permission denied: $failureCount grades',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportResults();
            },
            icon: const Icon(Icons.download),
            label: const Text('Export Results'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCreateAssignmentInfo();
            },
            icon: const Icon(Icons.add),
            label: const Text('Learn About Creating Assignments'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show information about creating assignments
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
              Text('3. You can then auto-grade all submissions with full access'),
              SizedBox(height: 16),
              Text(
                '📋 Step-by-Step Workflow:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Select a course in this app'),
              Text('2. Click the green "Create Assignment" button'),
              Text('3. Fill in assignment details (title, description, points)'),
              Text('4. Share the assignment with students'),
              Text('5. Students submit their code files'),
              Text('6. Use "Grade All" to automatically grade and submit to Classroom'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showSubmissionResultsDialog(int successCount, int failureCount, List<String> failedSubmissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              successCount > 0 ? Icons.check_circle : Icons.error,
              color: successCount > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Grade Submission Results'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successCount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: successCount > 0 ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submission Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('✅ Successfully submitted: $successCount grades'),
                    Text('❌ Failed submissions: $failureCount grades'),
                    Text('📊 Success rate: ${successCount > 0 ? ((successCount / (successCount + failureCount)) * 100).toStringAsFixed(1) : "0"}%'),
                  ],
                ),
              ),
              
              if (failedSubmissions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Failed Submissions:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: failedSubmissions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          '• ${failedSubmissions[index]}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (failureCount > 0)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRetryDialog(failedSubmissions);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Failed'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(List<String> failedSubmissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Failed Submissions'),
        content: Text(
          'Would you like to retry submitting grades for the ${failedSubmissions.length} failed submissions?\n\n'
          'This might resolve temporary network issues or authentication problems.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAllGradesToClassroom();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showGradeSubmissionErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Grade Submission Error'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.result.isSuccess ? Icons.check_circle : Icons.warning,
                  color: widget.result.isSuccess ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Batch Execution Results',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.result.summary,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Summary Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Submissions',
                      widget.result.totalSubmissions.toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Successful',
                      widget.result.successfulExecutions.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Failed',
                      widget.result.failedExecutions.toString(),
                      Icons.error,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Success Rate',
                      '${widget.result.successRate.toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Grade Summary (if calculated)
            if (_gradesCalculated && widget.assignment != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grade, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Calculated Grades',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Average Grade: ${_getAverageGrade().toStringAsFixed(1)}/${widget.assignment!.maxScore}'),
                        const SizedBox(width: 20),
                        Text('Passing (≥70%): ${_getPassingCount()}/${widget.submissions.length}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Results List
            const Text(
              'Individual Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: widget.submissions.length,
                  itemBuilder: (context, index) {
                    final submission = widget.submissions[index];
                    final submissionResult = widget.result.getResultForSubmission(submission.id ?? '');
                    final calculatedGrade = _calculatedGrades[submission.id ?? ''];
                    
                    return ListTile(
                      leading: Icon(
                        submissionResult?.success == true ? Icons.check_circle : Icons.error,
                        color: submissionResult?.success == true ? Colors.green : Colors.red,
                      ),
                      title: Text(submission.studentName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('File: ${submission.filename}'),
                          if (submissionResult != null) ...[
                            Text(
                              submissionResult.success 
                                  ? 'Executed successfully' 
                                  : 'Execution failed',
                              style: TextStyle(
                                color: submissionResult.success ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (calculatedGrade != null && widget.assignment != null)
                              Text(
                                'Grade: ${calculatedGrade.toStringAsFixed(1)}/${widget.assignment!.maxScore} (${((calculatedGrade / widget.assignment!.maxScore) * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ] else
                            const Text('No result available'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (submissionResult != null && submissionResult.hasOutput)
                            IconButton(
                              onPressed: () => _showOutputDialog(context, submission, submissionResult),
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              tooltip: 'View Output',
                            ),
                          if (submissionResult != null && submissionResult.hasError)
                            IconButton(
                              onPressed: () => _showExecutionErrorDialog(context, submission, submissionResult),
                              icon: const Icon(Icons.error_outline, color: Colors.red),
                              tooltip: 'View Error',
                            ),
                          IconButton(
                            onPressed: () => widget.onViewSubmission(submission.id ?? ''),
                            icon: const Icon(Icons.code),
                            tooltip: 'View Code',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Execution completed in ${widget.result.executionTimeFormatted}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    // Export Results Button with enhanced functionality
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportResults,
                      icon: _isExporting 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting ? 'Exporting...' : 'Export Results'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isExporting ? Colors.grey : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Submit Grades to Classroom Button
                    if (widget.gradingService != null && 
                        widget.assignment != null && 
                        widget.courseId != null &&
                        _gradesCalculated) ...[
                      ElevatedButton.icon(
                        onPressed: _isSubmittingGrades ? null : _submitAllGradesToClassroom,
                        icon: _isSubmittingGrades 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(_isSubmittingGrades ? 'Submitting...' : 'Submit to Classroom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubmittingGrades ? Colors.grey : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    // Close Button
                    ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double _getAverageGrade() {
    if (_calculatedGrades.isEmpty) return 0.0;
    final total = _calculatedGrades.values.reduce((a, b) => a + b);
    return total / _calculatedGrades.length;
  }

  int _getPassingCount() {
    if (widget.assignment == null) return 0;
    final passingThreshold = widget.assignment!.maxScore * 0.7; // 70%
    return _calculatedGrades.values.where((grade) => grade >= passingThreshold).length;
  }

  void _showOutputDialog(BuildContext context, StudentSubmission submission, CodeExecutionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Output - ${submission.studentName}'),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.output,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExecutionErrorDialog(BuildContext context, StudentSubmission submission, CodeExecutionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error - ${submission.studentName}'),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.error,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.red),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}