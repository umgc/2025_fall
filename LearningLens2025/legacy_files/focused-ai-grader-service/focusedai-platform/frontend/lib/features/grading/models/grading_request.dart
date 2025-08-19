import '../../../core/models/code_file.dart';

class GradingRequest {
  final String submissionId;
  final String assignmentId;
  final String language;
  final List<CodeFile> files;
  final String testInput;
  final String expectedOutput;
  final String? studentId;
  final String? studentName;
  final double maxScore;
  final String gradingMode;
  final List<String>? customCriteria;
  final Map<String, dynamic>? metadata;

  GradingRequest({
    required this.submissionId,
    required this.assignmentId,
    required this.language,
    required this.files,
    this.testInput = '',
    this.expectedOutput = '',
    this.studentId,
    this.studentName,
    this.maxScore = 100.0,
    this.gradingMode = 'AUTO',
    this.customCriteria,
    this.metadata,
  });

  factory GradingRequest.fromJson(Map<String, dynamic> json) {
    return GradingRequest(
      submissionId: json['submissionId'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      language: json['language'] ?? '',
      files: (json['files'] as List<dynamic>?)
          ?.map((f) => CodeFile.fromJson(f))
          .toList() ?? [],
      testInput: json['testInput'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '',
      studentId: json['studentId'],
      studentName: json['studentName'],
      maxScore: (json['maxScore'] ?? 100.0).toDouble(),
      gradingMode: json['gradingMode'] ?? 'AUTO',
      customCriteria: json['customCriteria'] != null
          ? List<String>.from(json['customCriteria'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submissionId': submissionId,
      'assignmentId': assignmentId,
      'language': language,
      'files': files.map((f) => f.toJson()).toList(),
      'testInput': testInput,
      'expectedOutput': expectedOutput,
      if (studentId != null) 'studentId': studentId,
      if (studentName != null) 'studentName': studentName,
      'maxScore': maxScore,
      'gradingMode': gradingMode,
      if (customCriteria != null) 'customCriteria': customCriteria,
      if (metadata != null) 'metadata': metadata,
    };
  }

  GradingRequest copyWith({
    String? submissionId,
    String? assignmentId,
    String? language,
    List<CodeFile>? files,
    String? testInput,
    String? expectedOutput,
    String? studentId,
    String? studentName,
    double? maxScore,
    String? gradingMode,
    List<String>? customCriteria,
    Map<String, dynamic>? metadata,
  }) {
    return GradingRequest(
      submissionId: submissionId ?? this.submissionId,
      assignmentId: assignmentId ?? this.assignmentId,
      language: language ?? this.language,
      files: files ?? this.files,
      testInput: testInput ?? this.testInput,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      maxScore: maxScore ?? this.maxScore,
      gradingMode: gradingMode ?? this.gradingMode,
      customCriteria: customCriteria ?? this.customCriteria,
      metadata: metadata ?? this.metadata,
    );
  }
}