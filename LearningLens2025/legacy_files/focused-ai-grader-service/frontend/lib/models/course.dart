// lib/models/course.dart
class Course {
  final String id;
  final String name;
  final String description;
  final String instructor;
  final DateTime createdAt;
  final List<String> assignmentIds;

  Course({
    required this.id,
    required this.name,
    required this.description,
    required this.instructor,
    required this.createdAt,
    required this.assignmentIds,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      instructor: json['instructor'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      assignmentIds: List<String>.from(json['assignmentIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructor': instructor,
      'createdAt': createdAt.toIso8601String(),
      'assignmentIds': assignmentIds,
    };
  }

  @override
  String toString() {
    return 'Course(id: $id, name: $name, instructor: $instructor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to create a copy with updated fields
  Course copyWith({
    String? id,
    String? name,
    String? description,
    String? instructor,
    DateTime? createdAt,
    List<String>? assignmentIds,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      createdAt: createdAt ?? this.createdAt,
      assignmentIds: assignmentIds ?? this.assignmentIds,
    );
  }
}