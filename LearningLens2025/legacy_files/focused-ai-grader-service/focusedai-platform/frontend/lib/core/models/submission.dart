import '../models/code_file.dart';
import '../models/grade.dart';

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final List<CodeFile> files;
  final DateTime submittedAt;
  final String status;
  final Grade? grade;
  final bool isZipSubmission;
  final Map<String, dynamic>? metadata;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.files,
    required this.submittedAt,
    required this.status,
    this.grade,
    this.isZipSubmission = false,
    this.metadata,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      files: (json['files'] as List<dynamic>?)
          ?.map((f) => CodeFile.fromJson(f))
          .toList() ?? [],
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : DateTime.now(),
      status: json['status'] ?? 'submitted',
      grade: json['grade'] != null ? Grade.fromJson(json['grade']) : null,
      isZipSubmission: json['isZipSubmission'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'files': files.map((f) => f.toJson()).toList(),
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
      if (grade != null) 'grade': grade!.toJson(),
      'isZipSubmission': isZipSubmission,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Helper properties
  bool get hasMultipleFiles => files.length > 1;
  
  bool get isGraded => grade != null;
  
  String get primaryLanguage {
    if (files.isEmpty) return 'unknown';
    
    final languageCounts = <String, int>{};
    for (final file in files) {
      languageCounts[file.language] = (languageCounts[file.language] ?? 0) + 1;
    }
    
    return languageCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  String get filesSummary {
    if (files.isEmpty) return 'No files';
    if (files.length == 1) return files.first.filename;
    
    final filenames = files.map((f) => f.filename).toList();
    if (filenames.length <= 3) {
      return filenames.join(', ');
    } else {
      return '${filenames.take(2).join(', ')}, +${filenames.length - 2} more';
    }
  }

  Submission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    List<CodeFile>? files,
    DateTime? submittedAt,
    String? status,
    Grade? grade,
    bool? isZipSubmission,
    Map<String, dynamic>? metadata,
  }) {
    return Submission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      files: files ?? this.files,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      isZipSubmission: isZipSubmission ?? this.isZipSubmission,
      metadata: metadata ?? this.metadata,
    );
  }

  Submission copyWithGrade(Grade newGrade) {
    return copyWith(
      grade: newGrade,
      status: 'graded',
    );
  }
}