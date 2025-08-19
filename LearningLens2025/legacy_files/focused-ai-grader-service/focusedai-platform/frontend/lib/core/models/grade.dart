class Grade {
  final String id;
  final String submissionId;
  final double score;
  final double maxScore;
  final double percentage;
  final String letterGrade;
  final String feedback;
  final bool passed;
  final String? strategy;
  final Map<String, dynamic>? executionDetails;
  final DateTime gradedAt;
  final String? gradedBy;

  Grade({
    required this.id,
    required this.submissionId,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.letterGrade,
    required this.feedback,
    required this.passed,
    this.strategy,
    this.executionDetails,
    required this.gradedAt,
    this.gradedBy,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? json['gradeId'] ?? '',
      submissionId: json['submissionId'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      maxScore: (json['maxScore'] ?? 100.0).toDouble(),
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      letterGrade: json['letterGrade'] ?? 'F',
      feedback: json['feedback'] ?? '',
      passed: json['passed'] ?? json['isPassed'] ?? false,
      strategy: json['strategy'] ?? json['gradingStrategy'],
      executionDetails: json['executionDetails'],
      gradedAt: json['gradedAt'] != null
          ? DateTime.parse(json['gradedAt'])
          : DateTime.now(),
      gradedBy: json['gradedBy'],
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
      'passed': passed,
      if (strategy != null) 'strategy': strategy,
      if (executionDetails != null) 'executionDetails': executionDetails,
      'gradedAt': gradedAt.toIso8601String(),
      if (gradedBy != null) 'gradedBy': gradedBy,
    };
  }

  Grade copyWith({
    String? id,
    String? submissionId,
    double? score,
    double? maxScore,
    double? percentage,
    String? letterGrade,
    String? feedback,
    bool? passed,
    String? strategy,
    Map<String, dynamic>? executionDetails,
    DateTime? gradedAt,
    String? gradedBy,
  }) {
    return Grade(
      id: id ?? this.id,
      submissionId: submissionId ?? this.submissionId,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      letterGrade: letterGrade ?? this.letterGrade,
      feedback: feedback ?? this.feedback,
      passed: passed ?? this.passed,
      strategy: strategy ?? this.strategy,
      executionDetails: executionDetails ?? this.executionDetails,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
    );
  }
}