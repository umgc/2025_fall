class Course {
  final String id;
  final String name;
  final String description;
  final String platform;
  final String? instructor;
  final int? enrollmentCount;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.platform,
    this.instructor,
    this.enrollmentCount,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      platform: json['platform'] ?? '',
      instructor: json['instructor'],
      enrollmentCount: json['enrollmentCount'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
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
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}