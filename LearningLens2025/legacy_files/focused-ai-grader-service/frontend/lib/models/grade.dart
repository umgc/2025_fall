class Grade {
  String? id;
  String submissionId;
  double score;
  double maxScore;
  String feedback;
  DateTime? gradedAt;
  String? gradedBy;
  String? batchId;
  Map<String, dynamic>? testResults;

  Grade({
    this.id,
    required this.submissionId,
    required this.score,
    required this.maxScore,
    this.feedback = '',
    this.gradedAt,
    this.gradedBy,
    this.batchId,
    this.testResults,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
  
  String get letterGrade {
    final percent = percentage;
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      submissionId: json['submissionId'],
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100.0,
      feedback: json['feedback'] ?? '',
      gradedAt: json['gradedAt'] != null ? DateTime.parse(json['gradedAt']) : null,
      gradedBy: json['gradedBy'],
      batchId: json['batchId'],
      testResults: json['testResults'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionId': submissionId,
      'score': score,
      'maxScore': maxScore,
      'feedback': feedback,
      'gradedAt': gradedAt?.toIso8601String(),
      'gradedBy': gradedBy,
      'batchId': batchId,
      'testResults': testResults,
    };
  }
}

class Course {
  String id;
  String name;
  String description;
  String? instructor;
  DateTime? createdAt;
  List<String> assignmentIds;

  Course({
    required this.id,
    required this.name,
    this.description = '',
    this.instructor,
    this.createdAt,
    this.assignmentIds = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      instructor: json['instructor'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      assignmentIds: (json['assignmentIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructor': instructor,
      'createdAt': createdAt?.toIso8601String(),
      'assignmentIds': assignmentIds,
    };
  }
}