import '../models/test_case.dart';
import '../models/submission.dart';

class Assignment {
  final String id;
  final String courseId;
  final String name;
  final String description;
  final String language;
  final DateTime? dueDate;
  final double maxScore;
  final List<TestCase> testCases;
  final List<Submission> submissions;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Assignment({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.language,
    this.dueDate,
    required this.maxScore,
    this.testCases = const [],
    this.submissions = const [],
    required this.createdAt,
    this.metadata,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      language: json['language'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      maxScore: (json['maxScore'] ?? 100.0).toDouble(),
      testCases: (json['testCases'] as List<dynamic>?)
          ?.map((tc) => TestCase.fromJson(tc))
          .toList() ?? [],
      submissions: (json['submissions'] as List<dynamic>?)
          ?.map((s) => Submission.fromJson(s))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'description': description,
      'language': language,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'maxScore': maxScore,
      'testCases': testCases.map((tc) => tc.toJson()).toList(),
      'submissions': submissions.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  Assignment copyWith({
    String? id,
    String? courseId,
    String? name,
    String? description,
    String? language,
    DateTime? dueDate,
    double? maxScore,
    List<TestCase>? testCases,
    List<Submission>? submissions,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Assignment(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      description: description ?? this.description,
      language: language ?? this.language,
      dueDate: dueDate ?? this.dueDate,
      maxScore: maxScore ?? this.maxScore,
      testCases: testCases ?? this.testCases,
      submissions: submissions ?? this.submissions,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper properties
  bool get hasTestCases => testCases.isNotEmpty;
  bool get hasSubmissions => submissions.isNotEmpty;
  int get gradedSubmissionsCount => submissions.where((s) => s.isGraded).length;
  double get totalTestPoints => testCases.fold(0.0, (sum, tc) => sum + tc.points);
}