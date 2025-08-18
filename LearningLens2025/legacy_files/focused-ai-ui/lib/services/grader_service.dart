import 'dart:convert';
import 'package:focused_ai_ui/constants/server_constants.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

class GraderService {

  static Future<List<Course>> fetchCourses() async {
    final response = await http.get(Uri.parse('${ServerConstants.graderServerUrl}/google/courses'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  static Future<List<Assignment>> fetchAssignments(String courseId) async {
    final response = await http.get(Uri.parse('${ServerConstants.graderServerUrl}/google/courses/$courseId/assignments'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Assignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assignments');
    }
  }

  static Future<void> createAssignment({
    required String courseId,
    required String title,
    required String description,
    required int maxPoints,
  }) async {
    final url = Uri.parse('${ServerConstants.graderServerUrl}/google/courses/$courseId/assignments');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'maxPoints': maxPoints,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create assignment');
    }
  }

  static Future<List<Map<String, String>>> fetchStudentList(String courseId) async {
    return [
      {'id': '1234567890', 'name': 'Student One'},
      {'id': '9876543210', 'name': 'Student Two'},
    ];
  }

  static Future<List<Submission>> fetchSubmissions(String courseId, String assignmentId) async {
    final url = Uri.parse('${ServerConstants.graderServerUrl}/google/courses/$courseId/courseWork/$assignmentId/submissions');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Submission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load submissions');
    }
  }

  static Future<String?> fetchStudentSubmission({
    required String courseId,
    required String courseworkId,
    required String userId,
  }) async {
    final url = Uri.parse(
      '${ServerConstants.graderServerUrl}/google/courses/$courseId/courseWork/$courseworkId/submissions/$userId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to fetch submission');
    }
  }

  static Future<String> fetchSubmissionText(String courseId, String courseworkId, String userId) async {
    final response = await http.get(
      Uri.parse('${ServerConstants.graderServerUrl}/google/courses/$courseId/courseWork/$courseworkId/submissions/$userId/text'),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to fetch submission text');
    }
  }

  static Future<String> fetchRubricLink(String courseId, String assignmentId) async {
    final url = Uri.parse('${ServerConstants.graderServerUrl}/google/courses/$courseId/courseWork/$assignmentId/rubric');
    print('🔍 Fetching rubric from: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load rubric link');
    }
  }

  static Future<Map<String, String>> gradeStudentSubmission({
    required String courseId,
    required String assignmentId,
    required String userId,
  }) async {
    final url = Uri.parse(
      '${ServerConstants.graderServerUrl}/google/courses/$courseId/courseWork/$assignmentId/submissions/$userId/grade',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      print('📄 Raw body response: $json');

      return {
        'grade': json['grade'] ?? '',
        'comments': json['comments'] ?? '',
      };
    } else {
      throw Exception('Failed to grade submission');
    }
  }

  static Future<void> submitGradeAndComments({
    required String courseId,
    required String assignmentId,
    required String submissionId,
    required int grade,
    required String comments,
  }) async {
    final response = await http.post(
      Uri.parse('${ServerConstants.graderServerUrl}/google/classroom/submit-grade'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'courseId': courseId,
        'assignmentId': assignmentId,
        'submissionId': submissionId,
        'grade': grade,
        'comments': comments,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit grade and comments: ${response.body}');
    }
  }

  /// ✅ NEW: Grade All Submissions
  static Future<List<String>> gradeAllSubmissions(String courseId, String assignmentId) async {
    final url = Uri.parse('${ServerConstants.graderServerUrl}/google/classroom/grade/all');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'courseId': courseId,
        'assignmentId': assignmentId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> failures = data['failedSubmissions'] ?? [];
      return failures.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to grade all submissions');
    }
  }
} 
