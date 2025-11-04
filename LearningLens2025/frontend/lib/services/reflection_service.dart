import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

/// Represents a program assessment job
/// Check the handleGET method in code_eval/index.mjs for properties
// AssignedGame model
class Reflection {
  final String? uuid;
  final int courseId;
  final int assignmentId;
  final String question;
  final DateTime date = DateTime.now();
  LmsType lms = LocalStorageService.getSelectedClassroom();

  Reflection(
      {required this.courseId,
      required this.assignmentId,
      required this.question,
      this.uuid});
}

class ReflectionResponse {
  final String? uuid;
  final String reflectionId;
  final int studentId;
  final String response;
  final DateTime date = DateTime.now();

  ReflectionResponse(
      {required this.studentId,
      required this.response,
      required this.reflectionId,
      this.uuid});
}

class ReflectionService {
  final reflectionUrl = LocalStorageService.getReflectionsUrl();

  static Uri? _buildCommandUri(
    String baseUrl,
    String command, {
    Map<String, String>? params,
  }) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.scheme.isEmpty) {
      return null;
    }

    final query = <String, String>{'command': command};
    if (params != null) {
      query.addAll(params);
    }

    final path = parsed.path.isEmpty ? '/' : parsed.path;
    return parsed.replace(path: path, queryParameters: query);
  }

  Uri _requireUri(
    String command, {
    Map<String, String>? params,
  }) {
    final uri = _buildCommandUri(reflectionUrl, command, params: params);
    if (uri == null) {
      throw StateError(
        'Reflection service URL not configured. Please verify the REFLECTION_URL setting.',
      );
    }
    return uri;
  }

  static Future<void> createDb() async {
    final baseUrl = LocalStorageService.getReflectionsUrl();
    final uri = _buildCommandUri(baseUrl, 'createDb');

    if (uri == null) {
      developer.log(
        'Skipping reflection database init; REFLECTION_URL is not set or invalid.',
        name: 'ReflectionService',
      );
      return;
    }

    try {
      await http.post(uri);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to initialize reflection database.',
        name: 'ReflectionService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Starts a program assessment
  Future<http.Response> createReflection(Reflection ref) async {
    final uri = _requireUri('createReflection');
    return await ApiService().httpPost(uri,
        body: jsonEncode({
          'courseId': ref.courseId,
          'assignmentId': ref.assignmentId,
          'question': ref.question,
          'lmsType': ref.lms.index,
        }));
  }

  /// Starts a program assessment
  Future<http.Response> completeReflection(ReflectionResponse resp) async {
    final uri = _requireUri('completeReflection');
    return await ApiService().httpPost(uri,
        body: jsonEncode({
          'studentId': resp.studentId,
          'response': resp.response,
          'reflectionId': resp.reflectionId
        }));
  }

  /// Gets code evaluations for all assignments in a course
  Future<List<Reflection>> getReflectionsForAssignment(
      int courseId, int assignmentId) async {
    final uri = _requireUri(
      'getReflection',
      params: {
        'courseId': '$courseId',
        'assignmentId': '$assignmentId',
        'lmsType': '${LocalStorageService.getSelectedClassroom().index}'
      },
    );
    final response = await ApiService().httpGet(uri);

    if (response.statusCode != 200) return [];

    final reflections = jsonDecode(response.body) as List<dynamic>;
    return reflections.map((ref) {
      return Reflection(
        uuid: ref['reflection_id'],
        courseId: courseId,
        assignmentId: assignmentId,
        question: ref['question'],
      );
    }).toList();
  }

  /// Gets code evaluations for all assignments in a course
  Future<ReflectionResponse?> getReflectionForSubmission(
      String reflectionId, int studentId) async {
    final uri = _requireUri(
      'getCompletedReflection',
      params: {'reflectionId': reflectionId, 'studentId': '$studentId'},
    );
    final response = await ApiService().httpGet(uri);

    if (response.statusCode != 200) return null;

    final reflections = jsonDecode(response.body);

    if (reflections is List<dynamic>) {
      return reflections
          .map((ref) {
            return ReflectionResponse(
              uuid: ref['response_id'],
              studentId: studentId,
              response: ref['response'],
              reflectionId: ref['reflection'],
            );
          })
          .toList()
          .firstOrNull;
    } else {
      return null;
    }
  }
}
