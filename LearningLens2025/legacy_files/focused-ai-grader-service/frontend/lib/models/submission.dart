class StudentSubmission {
  String? id; // 🆕 Added ID field for backend tracking
  String studentId;
  String studentName;
  String filename;
  String code;
  String? assignmentId;
  DateTime? submittedAt;
  String status; // 🆕 Added status tracking (uploaded, grading, graded)
  int? fileSize;
  String? fileExtension;
  String? gradeId; // 🆕 Added grade relationship
  DateTime? uploadedAt; // 🆕 Added upload timestamp

  StudentSubmission({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.filename,
    required this.code,
    this.assignmentId,
    this.submittedAt,
    this.status = 'uploaded', // 🆕 Default status
    this.fileSize,
    this.fileExtension,
    this.gradeId,
    this.uploadedAt,
  });

  factory StudentSubmission.fromJson(Map<String, dynamic> json) {
    return StudentSubmission(
      id: json['id'], // 🆕 Parse ID from JSON
      studentId: json['studentId'],
      studentName: json['studentName'],
      filename: json['filename'],
      code: json['code'],
      assignmentId: json['assignmentId'],
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      status: json['status'] ?? 'uploaded', // 🆕 Parse status
      fileSize: json['fileSize'],
      fileExtension: json['fileExtension'],
      gradeId: json['gradeId'], // 🆕 Parse grade relationship
      uploadedAt: json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt']) : null, // 🆕 Parse upload time
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // 🆕 Include ID in JSON
      'studentId': studentId,
      'studentName': studentName,
      'filename': filename,
      'code': code,
      'assignmentId': assignmentId,
      'submittedAt': submittedAt?.toIso8601String(),
      'status': status, // 🆕 Include status in JSON
      'fileSize': fileSize,
      'fileExtension': fileExtension,
      'gradeId': gradeId, // 🆕 Include grade relationship
      'uploadedAt': uploadedAt?.toIso8601String(), // 🆕 Include upload time
    };
  }

  // 🆕 Helper methods for status checking
  bool get isUploaded => status == 'uploaded';
  bool get isGrading => status == 'grading';
  bool get isGraded => status == 'graded';
  bool get hasGrade => gradeId != null && gradeId!.isNotEmpty;

  // 🆕 Helper method to get file size in readable format
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).ceil()}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // 🆕 Helper method to get language icon based on file extension
  String get languageDisplayName {
    switch (fileExtension?.toLowerCase()) {
      case 'java':
        return 'Java';
      case 'py':
        return 'Python';
      case 'js':
        return 'JavaScript';
      case 'cpp':
      case 'c++':
      case 'cxx':
        return 'C++';
      case 'c':
        return 'C';
      case 'cs':
        return 'C#';
      default:
        return fileExtension?.toUpperCase() ?? 'Code';
    }
  }

  // 🆕 Helper method to create a copy with updated status
  StudentSubmission copyWithStatus(String newStatus) {
    return StudentSubmission(
      id: id,
      studentId: studentId,
      studentName: studentName,
      filename: filename,
      code: code,
      assignmentId: assignmentId,
      submittedAt: submittedAt,
      status: newStatus,
      fileSize: fileSize,
      fileExtension: fileExtension,
      gradeId: gradeId,
      uploadedAt: uploadedAt,
    );
  }

  // 🆕 Helper method to create a copy with grade assigned
  StudentSubmission copyWithGrade(String gradeId) {
    return StudentSubmission(
      id: id,
      studentId: studentId,
      studentName: studentName,
      filename: filename,
      code: code,
      assignmentId: assignmentId,
      submittedAt: submittedAt,
      status: 'graded',
      fileSize: fileSize,
      fileExtension: fileExtension,
      gradeId: gradeId,
      uploadedAt: uploadedAt,
    );
  }

  // 🆕 Validation method
  bool get isValid {
    return studentId.isNotEmpty &&
           studentName.isNotEmpty &&
           filename.isNotEmpty &&
           code.isNotEmpty;
  }

  // 🆕 Display name for UI
  String get displayName => '$studentName ($studentId)';

  // 🆕 Short code preview for UI
  String get codePreview {
    if (code.length <= 100) return code;
    return '${code.substring(0, 97)}...';
  }
}

// 🆕 Enum for submission status
enum SubmissionStatus {
  uploaded('uploaded'),
  grading('grading'),
  graded('graded'),
  error('error');

  const SubmissionStatus(this.value);
  final String value;

  static SubmissionStatus fromString(String value) {
    return SubmissionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubmissionStatus.uploaded,
    );
  }
}

// 🆕 Batch processing class for multiple submissions
class GradingBatch {
  String batchId;
  String assignmentId;
  List<StudentSubmission> submissions;
  BatchStatus status;
  DateTime createdAt;
  String? errorMessage;
  int totalSubmissions;
  int processedSubmissions;

  GradingBatch({
    required this.batchId,
    required this.assignmentId,
    required this.submissions,
    this.status = BatchStatus.pending,
    required this.createdAt,
    this.errorMessage,
    this.totalSubmissions = 0,
    this.processedSubmissions = 0,
  });

  double get progressPercentage {
    if (totalSubmissions == 0) return 0.0;
    return (processedSubmissions / totalSubmissions) * 100.0;
  }

  factory GradingBatch.fromJson(Map<String, dynamic> json) {
    return GradingBatch(
      batchId: json['batchId'],
      assignmentId: json['assignmentId'],
      submissions: (json['submissions'] as List<dynamic>?)
          ?.map((s) => StudentSubmission.fromJson(s))
          .toList() ?? [],
      status: BatchStatus.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt']),
      errorMessage: json['errorMessage'],
      totalSubmissions: json['totalSubmissions'] ?? 0,
      processedSubmissions: json['processedSubmissions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'assignmentId': assignmentId,
      'submissions': submissions.map((s) => s.toJson()).toList(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'errorMessage': errorMessage,
      'totalSubmissions': totalSubmissions,
      'processedSubmissions': processedSubmissions,
    };
  }
}

enum BatchStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed');

  const BatchStatus(this.value);
  final String value;

  static BatchStatus fromString(String value) {
    return BatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BatchStatus.pending,
    );
  }
}