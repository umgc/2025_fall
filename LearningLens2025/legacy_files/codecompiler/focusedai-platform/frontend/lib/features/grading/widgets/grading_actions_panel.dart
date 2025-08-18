// lib/features/grading/widgets/grading_actions_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../providers/grading_provider.dart';
import '../../code_execution/providers/execution_provider.dart';
import '../models/grading_request.dart';

class GradingActionsPanel extends StatelessWidget {
  final bool isGradingEnabled;
  final Map<String, dynamic> testFiles;

  const GradingActionsPanel({
    super.key,
    required this.isGradingEnabled,
    required this.testFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<GradingProvider, ExecutionProvider>(
      builder: (context, gradingProvider, executionProvider, child) {
        final hasSubmissions = gradingProvider.hasSubmissions;
        final hasSelectedSubmission = gradingProvider.selectedSubmission != null;
        final isProcessing = gradingProvider.isGrading || 
                            gradingProvider.isBatchGrading ||
                            executionProvider.isExecuting;
        
        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.grade,
                    size: 16,
                    color: isGradingEnabled ? Colors.green[600] : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Grading Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Test Files Status
              _buildTestFilesStatus(),
              
              const SizedBox(height: 16),
              
              // Quick Execute Actions
              _buildQuickActions(context, executionProvider, hasSelectedSubmission, isProcessing),
              
              const SizedBox(height: 16),
              
              // Grading Actions
              _buildGradingActions(context, gradingProvider, hasSubmissions, hasSelectedSubmission, isProcessing),
              
              const SizedBox(height: 16),
              
              // Batch Actions
              _buildBatchActions(context, gradingProvider, hasSubmissions, isProcessing),
              
              // Help Text
              if (!isGradingEnabled) ...[
                const SizedBox(height: 12),
                _buildHelpText(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;
    
    if (isGradingEnabled) {
      badgeColor = Colors.green;
      badgeText = 'Ready';
      badgeIcon = Icons.check_circle;
    } else if (testFiles['hasInputFile'] == true || testFiles['hasOutputFile'] == true) {
      badgeColor = Colors.orange;
      badgeText = 'Partial';
      badgeIcon = Icons.warning;
    } else {
      badgeColor = Colors.grey;
      badgeText = 'No Tests';
      badgeIcon = Icons.upload_file;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestFilesStatus() {
    final hasInput = testFiles['hasInputFile'] == true;
    final hasOutput = testFiles['hasOutputFile'] == true;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGradingEnabled ? Colors.green[50] : 
               (hasInput || hasOutput) ? Colors.orange[50] : Colors.grey[50],
        border: Border.all(
          color: isGradingEnabled ? Colors.green[200]! : 
                 (hasInput || hasOutput) ? Colors.orange[200]! : Colors.grey[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                size: 16,
                color: isGradingEnabled ? Colors.green[600] : 
                       (hasInput || hasOutput) ? Colors.orange[600] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              const Text(
                'Test Files Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      hasInput ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 14,
                      color: hasInput ? Colors.green[600] : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasInput ? testFiles['inputFilename'] ?? 'Input Ready' : 'No Input File',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasInput ? Colors.green[700] : Colors.grey[600],
                          fontWeight: hasInput ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      hasOutput ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 14,
                      color: hasOutput ? Colors.green[600] : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasOutput ? testFiles['outputFilename'] ?? 'Output Ready' : 'No Output File',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasOutput ? Colors.green[700] : Colors.grey[600],
                          fontWeight: hasOutput ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (isGradingEnabled) ...[
            const SizedBox(height: 8),
            Text(
              '✅ Automatic grading and comparison enabled',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (hasInput || hasOutput) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Upload ${!hasInput ? 'input' : 'output'} file to enable grading',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ExecutionProvider executionProvider,
    bool hasSelectedSubmission,
    bool isProcessing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Execute',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (hasSelectedSubmission && !isProcessing) 
                    ? () => _runCode(context, executionProvider)
                    : null,
                icon: executionProvider.isExecuting
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
                  executionProvider.isExecuting ? 'Running...' : 'Run Code',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _analyzeCode(context, executionProvider),
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('Analyze', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradingActions(
    BuildContext context,
    GradingProvider gradingProvider,
    bool hasSubmissions,
    bool hasSelectedSubmission,
    bool isProcessing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Individual Grading',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (isGradingEnabled && hasSelectedSubmission && !isProcessing)
                ? () => _gradeSubmission(context, gradingProvider)
                : null,
            icon: gradingProvider.isGrading
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
              gradingProvider.isGrading ? 'Grading...' : 'Grade Selected',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isGradingEnabled ? Colors.green[600] : Colors.grey[300],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchActions(
    BuildContext context,
    GradingProvider gradingProvider,
    bool hasSubmissions,
    bool isProcessing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Batch Operations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (isGradingEnabled && hasSubmissions && !isProcessing)
                    ? () => _gradeBatch(context, gradingProvider)
                    : null,
                icon: gradingProvider.isBatchGrading
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
                  gradingProvider.isBatchGrading 
                      ? 'Grading...' 
                      : 'Grade All (${gradingProvider.submissionCount})',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGradingEnabled ? Colors.purple[600] : Colors.grey[300],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasSubmissions ? () => _exportResults(context, gradingProvider) : null,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Container(
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
              Icon(Icons.help_outline, size: 14, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Text(
                'Getting Started',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '1. Upload test files using the toolbar button\n'
            '2. Select a submission from the left panel\n'
            '3. Use "Run Code" to test execution\n'
            '4. Use "Grade" buttons for automatic assessment',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _runCode(BuildContext context, ExecutionProvider executionProvider) async {
    final gradingProvider = Provider.of<GradingProvider>(context, listen: false);
    final submission = gradingProvider.selectedSubmission;
    
    if (submission == null || submission.files.isEmpty) {
      _showMessage(context, 'No submission selected or no files found', Colors.orange);
      return;
    }

    try {
      final request = _createExecutionRequest(submission, isGrading: false);
      await executionProvider.executeCode(request);
      
      if (context.mounted) {
        _showMessage(context, 'Code executed successfully!', Colors.blue);
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Execution failed: $e', Colors.red);
      }
    }
  }

  Future<void> _analyzeCode(BuildContext context, ExecutionProvider executionProvider) async {
    final gradingProvider = Provider.of<GradingProvider>(context, listen: false);
    final submission = gradingProvider.selectedSubmission;
    
    if (submission == null || submission.files.isEmpty) {
      _showMessage(context, 'No submission selected for analysis', Colors.orange);
      return;
    }

    try {
      final request = _createExecutionRequest(submission, isGrading: false);
      final analysis = await executionProvider.analyzeCode(request);
      
      if (context.mounted && analysis != null) {
        _showAnalysisDialog(context, analysis);
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Analysis failed: $e', Colors.red);
      }
    }
  }

  Future<void> _gradeSubmission(BuildContext context, GradingProvider gradingProvider) async {
    final submission = gradingProvider.selectedSubmission;
    
    if (submission == null) {
      _showMessage(context, 'No submission selected', Colors.orange);
      return;
    }

    try {
      final request = _createGradingRequest(submission);
      await gradingProvider.gradeSubmission(request);
      
      if (context.mounted) {
        _showMessage(context, 'Submission graded successfully!', Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Grading failed: $e', Colors.red);
      }
    }
  }

  Future<void> _gradeBatch(BuildContext context, GradingProvider gradingProvider) async {
    final confirmed = await _showBatchConfirmationDialog(
      context, 
      gradingProvider.submissionCount,
    );
    
    if (confirmed != true) return;

    try {
      final requests = gradingProvider.submissions
          .map((submission) => _createGradingRequest(submission))
          .toList();
      
      await gradingProvider.gradeBatch(requests);
      
      if (context.mounted) {
        _showMessage(
          context, 
          'Batch grading completed for ${gradingProvider.submissionCount} submissions!', 
          Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Batch grading failed: $e', Colors.red);
      }
    }
  }

  void _exportResults(BuildContext context, GradingProvider gradingProvider) {
    // This would typically trigger a CSV export or similar functionality
    _showMessage(context, 'Export functionality would be implemented here', Colors.blue);
  }

  // Helper Methods
  dynamic _createExecutionRequest(dynamic submission, {required bool isGrading}) {
    // This would create an ExecutionRequest object
    // Implementation depends on your specific ExecutionRequest model
    return {
      'submissionId': submission.id,
      'files': submission.files,
      'testInput': isGrading ? (testFiles['inputContent'] ?? '') : '',
      'expectedOutput': isGrading ? (testFiles['outputContent'] ?? '') : '',
      'language': submission.primaryLanguage,
    };
  }

  GradingRequest _createGradingRequest(dynamic submission) {
    return GradingRequest(
      submissionId: submission.id,
      assignmentId: submission.assignmentId,
      language: submission.primaryLanguage,
      files: submission.files,
      testInput: testFiles['inputContent'] ?? '',
      expectedOutput: testFiles['outputContent'] ?? '',
      studentId: submission.studentId,
      studentName: submission.studentName,
    );
  }

  void _showMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: AppConfig.getSnackbarDuration(),
      ),
    );
  }

  void _showAnalysisDialog(BuildContext context, dynamic analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code Analysis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Strategy: ${analysis.recommendedStrategy}'),
            Text('Confidence: ${analysis.confidence.toStringAsFixed(1)}%'),
            Text('Features: ${analysis.detectedFeatures.join(", ")}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showBatchConfirmationDialog(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Grading'),
        content: Text(
          'Are you sure you want to grade all $count submissions?\n\n'
          'This operation cannot be undone and may take several minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
            child: const Text('Grade All'),
          ),
        ],
      ),
    );
  }
}