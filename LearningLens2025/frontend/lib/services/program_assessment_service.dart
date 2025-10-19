import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

/// Represents a program assessment job
/// Check the handleGET method in code_eval/index.mjs for properties
class ProrgramAssessmentJob {
  late String courseId;
  late String assignmentId;
  late String expectedOutput;

  /// Programming langauge code was written in
  late String language;

  /// username of the user that started the assessment
  late String username;
  late String status;

  /// List of results that contain information about each student's code submission
  late dynamic resultsJson;
  late DateTime startTime;
  DateTime? finishTime;

  /// Represents a program assessment job.
  /// Check the handleGET method in code_eval/index.mjs for properties
  ProrgramAssessmentJob(dynamic result) {
    courseId = result['course_id'];
    assignmentId = result['assignment_id'];
    expectedOutput = result['expected_output'];
    language = result['language'];
    username = result['username'];
    status = result['status'];
    resultsJson = result['results_json'] == null
        ? null
        : jsonDecode(result['results_json']);
    startTime = DateTime.parse(result['start_time']);
    finishTime = result['finish_time'] == null
        ? null
        : DateTime.parse(result['finish_time']);
  }
}

class ProgramAssessmentService {
  final codeEvalUrl = LocalStorageService.getCodeEvalUrl();
  final LmsInterface lmsService = LmsFactory.getLmsService();

  static Future<void> createDb() async {
    final url =
        Uri.parse("${LocalStorageService.getCodeEvalUrl()}/?command=createDb");
    await http.get(url);
  }

  /// Starts a program assessment
  Future<http.Response> startEvaluation(
      {required Course course,
      required Assignment assignment,
      required String input,
      required String expectedOutput,
      required String language,
      required int timeoutSeconds}) async {
    return await ApiService().httpPost(Uri.parse(codeEvalUrl),
        body: jsonEncode({
          'courseId': course.id,
          'assignmentId': assignment.id.toString(),
          'input': input,
          'expectedOutput': expectedOutput,
          'username': lmsService.userName,
          'language': language,
          'timeoutSeconds': timeoutSeconds.toString()
        }));
  }

  /// Gets code evaluations for all assignments in a course
  Future<List<ProrgramAssessmentJob>> getEvaluations(String username) async {
    final response = await ApiService().httpGet(
      Uri.parse('$codeEvalUrl/?username=$username'),
    );

    if (response.statusCode != 200) return [];

    final evaluations = jsonDecode(response.body) as List<dynamic>;
    return evaluations.map((eval) => ProrgramAssessmentJob(eval)).toList();
  }

  Future<bool> deleteEvaluation(
      {required Course course,
      required Assignment assignment,
      required String username}) async {
    try {
      final response = await http.delete(Uri.parse(codeEvalUrl),
          body: jsonEncode({
            'username': username,
            'assignmentId': assignment.id.toString(),
            'courseId': course.id.toString()
          }));

      return response.statusCode == 200;
    } catch (ex) {
      return false;
    }
  }
}
