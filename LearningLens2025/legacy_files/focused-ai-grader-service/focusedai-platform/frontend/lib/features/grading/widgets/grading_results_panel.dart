// lib/features/grading/widgets/grading_results_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../code_execution/providers/execution_provider.dart';
import '../../code_execution/models/execution_result.dart';
import '../providers/grading_provider.dart';

class GradingResultsPanel extends StatelessWidget {
  const GradingResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
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
                const Icon(Icons.assessment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Grading Results',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Consumer2<ExecutionProvider, GradingProvider>(
                  builder: (context, executionProvider, gradingProvider, child) {
                    if (executionProvider.hasResult || gradingProvider.lastGradingResult != null) {
                      return TextButton.icon(
                        onPressed: () {
                          executionProvider.clearResults();
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text('Clear', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: const Size(0, 0),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer2<ExecutionProvider, GradingProvider>(
              builder: (context, executionProvider, gradingProvider, child) {
                // Show grading result if available (priority)
                if (gradingProvider.lastGradingResult != null) {
                  return _buildGradingResult(gradingProvider.lastGradingResult!);
                }
                
                // Show execution result if available
                if (executionProvider.lastResult != null) {
                  return _buildExecutionResult(executionProvider.lastResult!);
                }
                
                // Show loading state
                if (executionProvider.isExecuting || gradingProvider.isGrading) {
                  return _buildLoadingState(gradingProvider.isGrading);
                }
                
                // Show placeholder
                return _buildPlaceholder();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingResult(dynamic gradingResult) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gradingResult.passed ? Colors.green[50] : Colors.red[50],
              border: Border.all(
                color: gradingResult.passed ? Colors.green[200]! : Colors.red[200]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      gradingResult.passed ? Icons.check_circle : Icons.cancel,
                      color: gradingResult.passed ? Colors.green[600] : Colors.red[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grade: ${gradingResult.letterGrade}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: gradingResult.passed ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          Text(
                            '${gradingResult.score.toStringAsFixed(1)}/${gradingResult.maxScore.toStringAsFixed(1)} (${gradingResult.percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: gradingResult.passed ? Colors.green[600] : Colors.red[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        gradingResult.passed ? 'PASSED' : 'FAILED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (gradingResult.strategy != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Strategy: ${gradingResult.strategy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Feedback Section
          if (gradingResult.feedback.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.feedback, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Feedback',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gradingResult.feedback,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Execution Details
          if (gradingResult.executionDetails != null) ...[
            _buildExecutionDetails(gradingResult.executionDetails!),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutionResult(ExecutionResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: result.success ? Colors.green[50] : Colors.red[50],
              border: Border.all(
                color: result.success ? Colors.green[200]! : Colors.red[200]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green[600] : Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.success ? 'Execution Successful' : 'Execution Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: result.success ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      if (result.testPassed) ...[
                        Text(
                          'Test Passed ✅',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (result.success && result.outputSimilarity > 0) ...[
                        Text(
                          'Output Similarity: ${result.outputSimilarity.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (result.executionTimeMs > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${result.executionTimeMs}ms',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Error Display
          if (result.hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                        'Error Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
                      result.error,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Output Display
          if (result.hasOutput) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                        'Program Output',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${result.output.length} characters',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 80,
                      maxHeight: 300,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        result.output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Strategy Information
          if (result.usedStrategy != null || result.detectedStrategy != null) ...[
            Container(
              width: double.infinity,
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
                    'Execution Strategy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (result.usedStrategy != null) ...[
                    Text('Used: ${result.usedStrategy}'),
                  ],
                  if (result.detectedStrategy != null) ...[
                    Text('Detected: ${result.detectedStrategy}'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutionDetails(Map<String, dynamic> details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.info, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Execution Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (details['executionTimeMs'] != null)
                _buildDetailChip('Time', '${details['executionTimeMs']}ms', Icons.timer),
              if (details['memoryUsedMb'] != null)
                _buildDetailChip('Memory', '${details['memoryUsedMb']}MB', Icons.memory),
              if (details['exitCode'] != null)
                _buildDetailChip('Exit Code', '${details['exitCode']}', Icons.exit_to_app),
              if (details['testPassed'] != null)
                _buildDetailChip(
                  'Test', 
                  details['testPassed'] ? 'Passed' : 'Failed', 
                  details['testPassed'] ? Icons.check : Icons.close,
                ),
              if (details['outputSimilarity'] != null)
                _buildDetailChip(
                  'Similarity', 
                  '${details['outputSimilarity'].toStringAsFixed(1)}%', 
                  Icons.compare,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isGrading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            isGrading ? 'Grading submission...' : 'Executing code...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGrading 
                ? 'Analyzing code and generating feedback'
                : 'Running your code with test inputs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run code or start grading to see results here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
                const SizedBox(height: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Select a submission to view code\n'
                  '• Upload test files to enable grading\n'
                  '• Use "Run" to test code execution\n'
                  '• Use "Grade" for automatic assessment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}