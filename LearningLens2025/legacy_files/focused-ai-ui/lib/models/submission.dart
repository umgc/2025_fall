import 'package:focused_ai_ui/models/code_file.dart';

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName; // Now provided by backend via batch lookup
  final List<CodeFile> files; // Files with content already fetched
  final DateTime submittedAt;
  final String status;
  final String platform;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.files,
    required this.submittedAt,
    required this.status,
    required this.platform,
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
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'unknown',
      platform: json['platform'] ?? '',
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
      'platform': platform,
    };
  }

  // Computed properties
  String get primaryLanguage {
    if (files.isEmpty) return 'unknown';
    
    // Count languages
    final languageCounts = <String, int>{};
    for (final file in files) {
      languageCounts[file.language] = (languageCounts[file.language] ?? 0) + 1;
    }
    
    // Return most common language
    return languageCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  bool get hasMultipleFiles => files.length > 1;

  bool get isZipSubmission => files.length > 1;

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
}