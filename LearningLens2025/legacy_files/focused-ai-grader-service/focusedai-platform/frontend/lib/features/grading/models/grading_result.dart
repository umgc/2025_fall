import '../../../core/models/grade.dart';
import '../../../core/config/app_config.dart';

class GradingResult {
  final String? gradeId;
  final String? submissionId;
  final bool success;
  final double score;
  final double maxScore;
  final double percentage;
  final String letterGrade;
  final String feedback;
  final bool passed;
  final String? gradingStrategy;
  final Map<String, dynamic>? executionDetails;
  final Map<String, dynamic>? analysisDetails;
  final DateTime gradedAt;
  final String? gradedBy;
  final String? error;

  GradingResult({
    this.gradeId,
    this.submissionId,
    required this.success,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.letterGrade,
    required this.feedback,
    required this.passed,
    this.gradingStrategy,
    this.executionDetails,
    this.analysisDetails,
    DateTime? gradedAt,
    this.gradedBy,
    this.error,
  }) : gradedAt = gradedAt ?? DateTime.now();

  factory GradingResult.fromJson(Map<String, dynamic> json) {
    return GradingResult(
      gradeId: json['gradeId'] ?? json['id'],
      submissionId: json['submissionId'],
      success: json['success'] ?? (json['error'] == null),
      score: (json['score'] ?? 0.0).toDouble(),
      maxScore: (json['maxScore'] ?? 100.0).toDouble(),
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      letterGrade: json['letterGrade'] ?? 'F',
      feedback: json['feedback'] ?? '',
      passed: json['passed'] ?? json['isPassed'] ?? false,
      gradingStrategy: json['gradingStrategy'],
      executionDetails: json['executionDetails'],
      analysisDetails: json['analysisDetails'],
      gradedAt: json['gradedAt'] != null
          ? DateTime.parse(json['gradedAt'])
          : DateTime.now(),
      gradedBy: json['gradedBy'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (gradeId != null) 'gradeId': gradeId,
      if (submissionId != null) 'submissionId': submissionId,
      'success': success,
      'score': score,
      'maxScore': maxScore,
      'percentage': percentage,
      'letterGrade': letterGrade,
      'feedback': feedback,
      'passed': passed,
      if (gradingStrategy != null) 'gradingStrategy': gradingStrategy,
      if (executionDetails != null) 'executionDetails': executionDetails,
      if (analysisDetails != null) 'analysisDetails': analysisDetails,
      'gradedAt': gradedAt.toIso8601String(),
      if (gradedBy != null) 'gradedBy': gradedBy,
      if (error != null) 'error': error,
    };
  }

  factory GradingResult.error(String errorMessage) {
    return GradingResult(
      success: false,
      score: 0.0,
      maxScore: 100.0,
      percentage: 0.0,
      letterGrade: 'F',
      feedback: 'Grading failed: $errorMessage',
      passed: false,
      error: errorMessage,
    );
  }

  factory GradingResult.fromExecutionResult(
    Map<String, dynamic> executionResult,
    double maxScore,
  ) {
    final success = executionResult['success'] ?? false;
    final testPassed = executionResult['testPassed'] ?? false;
    final similarity = (executionResult['outputSimilarity'] ?? 0).toDouble();
    
    double score = 0.0;
    if (success && testPassed) {
      score = maxScore;
    } else if (success) {
      // Partial credit based on similarity
      score = (similarity / 100) * maxScore;
    }
    
    final percentage = (score / maxScore) * 100;
    final letterGrade = AppConfig.calculateLetterGrade(percentage);
    final passed = AppConfig.isPassingGrade(percentage);
    
    return GradingResult(
      success: success,
      score: score,
      maxScore: maxScore,
      percentage: percentage,
      letterGrade: letterGrade,
      feedback: _generateFeedback(executionResult, testPassed, similarity),
      passed: passed,
      gradingStrategy: executionResult['usedStrategy'],
      executionDetails: executionResult,
    );
  }

  static String _generateFeedback(
    Map<String, dynamic> executionResult,
    bool testPassed,
    double similarity,
  ) {
    final buffer = StringBuffer();
    
    if (testPassed) {
      buffer.writeln('✅ Excellent! Your code passes all tests.');
      buffer.writeln('Your program produces the correct output.');
    } else if (executionResult['success'] == true) {
      buffer.writeln('⚠️ Your code runs but doesn\'t produce the expected output.');
      buffer.writeln('Output similarity: ${similarity.toStringAsFixed(1)}%');
      
      if (similarity >= 70) {
        buffer.writeln('You\'re very close to the correct solution!');
      } else if (similarity >= 40) {
        buffer.writeln('Your output has some similarities to the expected result.');
      } else {
        buffer.writeln('Your output is quite different from what\'s expected.');
      }
    } else {
      buffer.writeln('❌ Your code failed to execute properly.');
      final error = executionResult['error'];
      if (error != null && error.toString().isNotEmpty) {
        buffer.writeln('Error: $error');
      }
      buffer.writeln('Please check your code for syntax and runtime errors.');
    }
    
    final executionTime = executionResult['executionTimeMs'] ?? 0;
    if (executionTime > 0) {
      buffer.writeln('\n⏱️ Execution time: ${executionTime}ms');
    }
    
    return buffer.toString();
  }

  Grade toGrade() {
    return Grade(
      id: gradeId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      submissionId: submissionId ?? '',
      score: score,
      maxScore: maxScore,
      percentage: percentage,
      letterGrade: letterGrade,
      feedback: feedback,
      passed: passed,
      strategy: gradingStrategy,
      executionDetails: executionDetails,
      gradedAt: gradedAt,
      gradedBy: gradedBy,
    );
  }

  GradingResult copyWith({
    String? gradeId,
    String? submissionId,
    bool? success,
    double? score,
    double? maxScore,
    double? percentage,
    String? letterGrade,
    String? feedback,
    bool? passed,
    String? gradingStrategy,
    Map<String, dynamic>? executionDetails,
    Map<String, dynamic>? analysisDetails,
    DateTime? gradedAt,
    String? gradedBy,
    String? error,
  }) {
    return GradingResult(
      gradeId: gradeId ?? this.gradeId,
      submissionId: submissionId ?? this.submissionId,
      success: success ?? this.success,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      letterGrade: letterGrade ?? this.letterGrade,
      feedback: feedback ?? this.feedback,
      passed: passed ?? this.passed,
      gradingStrategy: gradingStrategy ?? this.gradingStrategy,
      executionDetails: executionDetails ?? this.executionDetails,
      analysisDetails: analysisDetails ?? this.analysisDetails,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
      error: error ?? this.error,
    );
  }

  // Helper properties
  bool get hasError => error != null && error!.isNotEmpty;
  bool get isValidGrade => success && !hasError;
  String get statusMessage {
    if (hasError) return 'Grading Error';
    if (!success) return 'Grading Failed';
    if (passed) return 'Passed';
    return 'Failed';
  }
}