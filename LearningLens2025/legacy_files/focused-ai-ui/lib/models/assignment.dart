class Assignment {
  final String id;
  final String courseId;
  final String name;
  final String description;
  final String platform; // 'google' or 'moodle'
  final DateTime? createdAt;
  final DateTime? dueDate;
  final double? maxPoints;
  final String? state; // For Google assignments
  final String status;             // 'assigned', 'submitted', etc.
  final int submissionCount;

  Assignment({
    required this.id,
    required this.courseId,
    required this.name,
    required this.description,
    required this.platform,
    this.createdAt,
    this.dueDate,
    this.maxPoints,
    this.state,
    required this.status,
    required this.submissionCount,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      platform: json['platform'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      maxPoints: json['maxPoints']?.toDouble(),
      state: json['state'],
      status: json['status'],
      submissionCount: json['submissionCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'name': name,
      'description': description,
      'platform': platform,
      'createdAt': createdAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'maxPoints': maxPoints,
      'state': state,
      'status': status,
      'submissionCount': submissionCount,
    };
  }
}