import 'dart:convert';
import 'package:focused_ai_ui/models/grade.dart';
import 'package:http/http.dart' as http;
import '../apis/google_classroom_api.dart';
import '../models/course.dart';
import '../models/participant.dart';
import 'auth_service.dart';

class AnalyticsService {
  final GoogleClassroomApi _api = GoogleClassroomApi();

  Future<List<Course>> getCourses() async {
    try {
      final response = await _api.protectedRequest('GET', '/google/courses');
      
      print('Google courses response: $response');
      print('Response type: ${response.runtimeType}');
      
      // Handle the CourseList wrapper from backend
      if (response is Map<String, dynamic> && response.containsKey('courses')) {
        final coursesList = response['courses'] as List<dynamic>;
        return coursesList.map((courseJson) {
          try {
            final Map<String, dynamic> courseMap = courseJson as Map<String, dynamic>;
            print('Parsing course: $courseMap');
            return Course.fromJson(courseMap);
          } catch (e) {
            print('Failed to parse course: $courseJson');
            print('Parse error: $e');
            throw Exception('Invalid course data format: $e');
          }
        }).toList();
      } else {
        throw Exception('Unexpected response format: expected CourseList wrapper');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  Future<List<Participant>> getParticipantsForCourse(int courseId) async {
    try {
      final response = await _api.protectedRequest('GET', '/google/courses/$courseId/students');

      print('Students response: $response');
      print('Response type: ${response.runtimeType}');

      if (response is Map<String, dynamic> && response.containsKey('students')) {
        final List<dynamic> studentList = response['students'];

        return studentList.map((json) {
          try {
            final Map<String, dynamic> participantMap = json as Map<String, dynamic>;
            return Participant.fromJson(participantMap);
          } catch (e) {
            print('Failed to parse participant: $json');
            print('Error: $e');
            throw Exception('Invalid participant data format: $e');
          }
        }).toList();
      } else {
        throw Exception('Unexpected response format: expected StudentList with "students" key');
      }
    } catch (e) {
      throw Exception('Failed to load participants: $e');
    }
  }

  Future<List<Participant>> getStudentSubmissions(int courseId, String courseWorkId) async {
  try {
    final response = await _api.protectedRequest(
      'GET',
      '/google/courses/$courseId/courseWork/$courseWorkId/submissions',
    );

    print('Submissions response: $response');
    print('Response type: ${response.runtimeType}');

    if (response is Map<String, dynamic> && response.containsKey('submissions')) {
      final List<dynamic> submissionsList = response['submissions'];

      return submissionsList.map((json) {
        try {
          final Map<String, dynamic> submissionMap = json as Map<String, dynamic>;
          return Participant.fromJson(submissionMap);
        } catch (e) {
          print('Failed to parse submission: $json');
          print('Error: $e');
          throw Exception('Invalid submission data format: $e');
        }
      }).toList();
    } else {
      throw Exception('Unexpected response format: expected "submissions" key');
    }
  } catch (e) {
    throw Exception('Failed to load student submissions: $e');
  }
}

  
/*
      Future<List<Assessment>> getAssessments(int courseId) async {
        final response = await http.get(Uri.parse('$baseUrl/assessments?courseId=$courseId'));
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          return jsonList.map((e) => Assessment.fromJson(e)).toList();
        } else {
          throw Exception('Failed to load assessments');
        }
      }

      Future<List<QuestionStats>> getQuestionStats(int assessmentId) async {
        final response = await http.get(Uri.parse('$baseUrl/questions?assessmentId=$assessmentId'));
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          return jsonList.map((e) => QuestionStats.fromJson(e)).toList();
        } else {
          throw Exception('Failed to load question stats');
        }
      }

      Future<List<Map<String, dynamic>>> analyzeWithAI(String prompt) async {
        final response = await http.post(
          Uri.parse('$baseUrl/ai/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        );
        if (response.statusCode == 200) {
          return List<Map<String, dynamic>>.from(jsonDecode(response.body));
        } else {
          throw Exception('AI analysis failed');
        }
      }*/

      Future<List<Participant>> getStudentReport(int courseId, int assessmentId) async {
        var baseUrl;
        final response = await http.get(Uri.parse('$baseUrl/report?courseId=$courseId&assessmentId=$assessmentId'));
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          return jsonList.map((e) => Participant.fromJson(e)).toList();
        } else {
          throw Exception('Failed to load student report');
        }
      }

      Future<List<Grade>> fetchQuizGrades(int courseId) async {
  try {
    final response = await _api.protectedRequest(
      'GET',
      '/google/courses/$courseId/grades',
    );

    if (response is List) {
      return response.map((e) => Grade.fromJson(e)).toList();
    } else {
      throw Exception('Unexpected grade response format');
    }
  } catch (e) {
    throw Exception('Failed to fetch quiz grades: $e');
  }
}


}
