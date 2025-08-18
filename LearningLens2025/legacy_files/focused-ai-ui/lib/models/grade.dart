class Grade {
  final String id;
  final String submissionId;
  final double score;
  final double maxScore;
  final double percentage;
  final String letterGrade;
  final String feedback;
  final double? similarity;
  final ExecutionResult? executionResult;
  final DateTime gradedAt;
  final String gradedBy;

  Grade({
    required this.id,
    required this.submissionId,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.letterGrade,
    required this.feedback,
    this.similarity,
    this.executionResult,
    required this.gradedAt,
    required this.gradedBy,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? '',
      submissionId: json['submissionId'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      maxScore: (json['maxScore'] ?? 100.0).toDouble(),
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      letterGrade: json['letterGrade'] ?? 'F',
      feedback: json['feedback'] ?? '',
      similarity: json['similarity']?.toDouble(),
      executionResult: json['executionResult'] != null 
          ? ExecutionResult.fromJson(json['executionResult']) 
          : null,
      gradedAt: DateTime.parse(json['gradedAt'] ?? DateTime.now().toIso8601String()),
      gradedBy: json['gradedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionId': submissionId,
      'score': score,
      'maxScore': maxScore,
      'percentage': percentage,
      'letterGrade': letterGrade,
      'feedback': feedback,
      'similarity': similarity,
      'executionResult': executionResult?.toJson(),
      'gradedAt': gradedAt.toIso8601String(),
      'gradedBy': gradedBy,
    };
  }
}

class ExecutionResult {
  final bool success;
  final String output;
  final String error;
  final int executionTime;

  ExecutionResult({
    required this.success,
    required this.output,
    required this.error,
    required this.executionTime,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      success: json['success'] ?? false,
      output: json['output'] ?? '',
      error: json['error'] ?? '',
      executionTime: json['executionTime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'output': output,
      'error': error,
      'executionTime': executionTime,
    };
  }
}
