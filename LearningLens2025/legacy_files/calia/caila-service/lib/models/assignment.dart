class Assignment {
  final String id;
  final String courseId;
  final String name;
  final String description;
  final String language;
  final DateTime? dueDate;
  final double? maxScore;
  final String platform;
  final String status;
  final int submissionCount;
  final DateTime createdAt;

  const Assignment({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.language,
    this.dueDate,
    this.maxScore,
    required this.platform,
    required this.status,
    required this.submissionCount,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      language: json['language'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      maxScore: json['maxScore']?.toDouble(),
      platform: json['platform'] ?? '',
      status: json['status'] ?? '',
      submissionCount: json['submissionCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'description': description,
      'language': language,
      'dueDate': dueDate?.toIso8601String(),
      'maxScore': maxScore,
      'platform': platform,
      'status': status,
      'submissionCount': submissionCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Add the copyWith method
  Assignment copyWith({
    String? id,
    String? courseId,
    String? name,
    String? description,
    String? language,
    DateTime? dueDate,
    double? maxScore,
    String? platform,
    String? status,
    int? submissionCount,
    DateTime? createdAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      description: description ?? this.description,
      language: language ?? this.language,
      dueDate: dueDate ?? this.dueDate,
      maxScore: maxScore ?? this.maxScore,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      submissionCount: submissionCount ?? this.submissionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Assignment &&
        other.id == id &&
        other.courseId == courseId &&
        other.name == name &&
        other.description == description &&
        other.language == language &&
        other.dueDate == dueDate &&
        other.maxScore == maxScore &&
        other.platform == platform &&
        other.status == status &&
        other.submissionCount == submissionCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      courseId,
      name,
      description,
      language,
      dueDate,
      maxScore,
      platform,
      status,
      submissionCount,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Assignment(id: $id, name: $name, courseId: $courseId, status: $status)';
  }
}