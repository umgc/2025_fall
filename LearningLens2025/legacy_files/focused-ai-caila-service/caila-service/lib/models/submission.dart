class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final DateTime submittedAt;
  final String status;
  final List<CodeFile> files;

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    required this.status,
    required this.files,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      files: (json['files'] as List<dynamic>?)
          ?.map((file) => CodeFile.fromJson(file as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
      'files': files.map((file) => file.toJson()).toList(),
    };
  }
}

class CodeFile {
  final String filename;
  final String content;
  final String language;

  const CodeFile({
    required this.filename,
    required this.content,
    required this.language,
  });

  factory CodeFile.fromJson(Map<String, dynamic> json) {
    return CodeFile(
      filename: json['filename'] ?? '',
      content: json['content'] ?? '',
      language: json['language'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content': content,
      'language': language,
    };
  }
}