class Grade {
  final String studentId;
  final String assignmentTitle;
  final double grade;

  Grade({
    required this.studentId,
    required this.assignmentTitle,
    required this.grade,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      studentId: json['studentId'],
      assignmentTitle: json['assignmentTitle'],
      grade: (json['grade'] as num).toDouble(),
    );
  }
}

