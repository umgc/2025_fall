import 'batch_execution_result.dart';
import '../services/code_execution_service.dart';
import 'assignment.dart';

class EnhancedBatchExecutionResult extends BatchExecutionResult {
  final Map<String, double> autoGrades; // submissionId -> calculated grade
  final Map<String, String> autoFeedback; // submissionId -> generated feedback
  final Assignment? assignment; // Add assignment for grade calculations
  
  EnhancedBatchExecutionResult({
    required String batchId,
    required String assignmentId,
    required Map<String, CodeExecutionResult> results,
    required int totalSubmissions,
    required int successfulExecutions,
    required int failedExecutions,
    required int executionTimeMs,
    required DateTime startTime,
    required DateTime endTime,
    required String platform,
    required this.autoGrades,
    required this.autoFeedback,
    this.assignment,
  }) : super(
    batchId: batchId,
    assignmentId: assignmentId,
    results: results,
    totalSubmissions: totalSubmissions,
    successfulExecutions: successfulExecutions,
    failedExecutions: failedExecutions,
    executionTimeMs: executionTimeMs,
    startTime: startTime,
    endTime: endTime,
    platform: platform,
  );

  // Helper method to create from a regular BatchExecutionResult
  factory EnhancedBatchExecutionResult.fromBatchResult(
    BatchExecutionResult originalResult, {
    required Map<String, double> autoGrades,
    required Map<String, String> autoFeedback,
    Assignment? assignment,
  }) {
    return EnhancedBatchExecutionResult(
      batchId: originalResult.batchId,
      assignmentId: originalResult.assignmentId,
      results: originalResult.results,
      totalSubmissions: originalResult.totalSubmissions,
      successfulExecutions: originalResult.successfulExecutions,
      failedExecutions: originalResult.failedExecutions,
      executionTimeMs: originalResult.executionTimeMs,
      startTime: originalResult.startTime,
      endTime: originalResult.endTime,
      platform: originalResult.platform,
      autoGrades: autoGrades,
      autoFeedback: autoFeedback,
      assignment: assignment,
    );
  }

  // Calculate average auto-grade
  double get averageGrade {
    if (autoGrades.isEmpty) return 0.0;
    final total = autoGrades.values.reduce((a, b) => a + b);
    return total / autoGrades.length;
  }

  // Get average grade as percentage
  double get averageGradePercentage {
    if (assignment == null || autoGrades.isEmpty) return 0.0;
    return (averageGrade / assignment!.maxScore) * 100;
  }

  // Count how many grades are above a certain threshold
  int gradesAboveThreshold(double threshold) {
    if (assignment == null) return 0;
    final thresholdScore = (threshold / 100) * assignment!.maxScore;
    return autoGrades.values.where((grade) => grade >= thresholdScore).length;
  }

  @override
  String toString() {
    return 'EnhancedBatchExecutionResult{'
        '${super.toString()}, '
        'autoGrades: ${autoGrades.length} grades, '
        'averageGrade: ${averageGrade.toStringAsFixed(1)}/${assignment?.maxScore ?? 0}'
        '}';
  }
}

class BatchGradingOptions {
  final bool executeCode;
  final bool calculateGrades;
  final bool submitToClassroom;
  final bool saveLocally;
  
  const BatchGradingOptions({
    required this.executeCode,
    required this.calculateGrades,
    required this.submitToClassroom,
    required this.saveLocally,
  });

  @override
  String toString() {
    return 'BatchGradingOptions{'
        'executeCode: $executeCode, '
        'calculateGrades: $calculateGrades, '
        'submitToClassroom: $submitToClassroom, '
        'saveLocally: $saveLocally'
        '}';
  }
}