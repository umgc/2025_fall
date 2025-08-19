import '../models/assignment.dart';

class Course {
  final String id;
  final String name;
  final String description;
  final String platform;
  final String instructor;
  final int enrollmentCount;
  final DateTime createdAt;
  final List<Assignment> assignments;
  final Map<String, dynamic>? metadata;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.platform,
    required this.instructor,
    required this.enrollmentCount,
    required this.createdAt,
    this.assignments = const [],
    this.metadata,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      platform: json['platform'] ?? '',
      instructor: json['instructor'] ?? '',
      enrollmentCount: json['enrollmentCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      assignments: (json['assignments'] as List<dynamic>?)
          ?.map((a) => Assignment.fromJson(a))
          .toList() ?? [],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'platform': platform,
      'instructor': instructor,
      'enrollmentCount': enrollmentCount,
      'createdAt': createdAt.toIso8601String(),
      'assignments': assignments.map((a) => a.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  Course copyWith({
    String? id,
    String? name,
    String? description,
    String? platform,
    String? instructor,
    int? enrollmentCount,
    DateTime? createdAt,
    List<Assignment>? assignments,
    Map<String, dynamic>? metadata,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      platform: platform ?? this.platform,
      instructor: instructor ?? this.instructor,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      createdAt: createdAt ?? this.createdAt,
      assignments: assignments ?? this.assignments,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper properties
  bool get hasAssignments => assignments.isNotEmpty;
  int get totalAssignments => assignments.length;
  int get totalSubmissions => assignments.fold(0, (sum, a) => sum + a.submissions.length);
}