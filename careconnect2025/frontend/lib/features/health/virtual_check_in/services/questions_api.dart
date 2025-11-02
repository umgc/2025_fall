// lib/features/health/virtual-check-in/models/questions_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_backend_question_model.dart';

class QuestionsApi {
  QuestionsApi(String baseUrl)
      : _base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  final String _base; // e.g. http://10.0.2.2:8080 or http://localhost:8080 (web)

  /// GET /api/questions?active=true|false
  Future<List<BackendQuestionDto>> listQuestions({bool? active}) async {
    final uri = Uri.parse('$_base/api/questions').replace(queryParameters: {
      if (active != null) 'active': active.toString(),
    });
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch questions: ${res.statusCode} ${res.body}');
    }
    final List<dynamic> arr = json.decode(res.body) as List<dynamic>;
    return arr
        .map((e) => BackendQuestionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ✅ GET /api/checkins/{checkInId}/questions
  /// (This is the line you lost — restored here.)
  Future<List<BackendQuestionDto>> listQuestionsForCheckIn(String checkInId) async {
    final uri = Uri.parse('$_base/api/checkins/$checkInId/questions'); // <— the line you wanted
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch check-in questions: ${res.statusCode} ${res.body}');
    }
    final List<dynamic> arr = json.decode(res.body) as List<dynamic>;
    return arr
        .map((e) => BackendQuestionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

