import 'package:focused_ai_ui/models/grade.dart';

class CourseWorkWithSubmissions {
  final String courseWorkId;
  final String title;
  final String workType;
  final List<Grade> grades;

  CourseWorkWithSubmissions({
    required this.courseWorkId,
    required this.title,
    required this.workType,
    required this.grades,
  });

  factory CourseWorkWithSubmissions.fromJson(Map<String, dynamic> json) {
    return CourseWorkWithSubmissions(
      courseWorkId: json['courseWorkId'],
      title: json['title'],
      workType: json['workType'],
      grades: (json['grades'] as List).map((g) => Grade.fromJson(g)).toList(),
    );
  }
}
