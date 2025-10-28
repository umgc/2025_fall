// lib/features/health/virtual_check_in/models/services/checkin_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_backend_question_model.dart';
import 'package:care_connect_app/features/health/virtual_check_in/models/virtual_check_in_backend_model.dart'
    show SubmitAnswersRequest;

class CheckInApi {
  final String _base;
  final http.Client _client;
  final Duration _timeout;
  final String? _jwt; // optional bearer token

  CheckInApi(
      String baseUrl, {
        http.Client? client,
        Duration timeout = const Duration(seconds: 15),
        String? jwt,
      })  : _base = _normalizeBase(baseUrl),
        _client = client ?? http.Client(),
        _timeout = timeout,
        _jwt = jwt;

  static String _normalizeBase(String v) {
    v = v.trim();
    if (v.endsWith('/')) v = v.substring(0, v.length - 1);
    return v;
  }

  Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = _jwt;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  /// GET /api/checkins/{checkInId}/questions
  /// Return typed DTOs for mapping to UI.
  Future<List<BackendQuestionDto>> getQuestions(String checkInId) async {
    final uri = Uri.parse('$_base/api/checkins/$checkInId/questions');
    final res = await _client.get(uri, headers: _headers()).timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Failed to load questions: ${res.statusCode} ${res.body}');
    }
    final raw = jsonDecode(res.body) as List;
    return raw
        .map((e) => BackendQuestionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// POST /api/checkins/{checkInId}/answers
  Future<void> submitAnswers(String checkInId, SubmitAnswersRequest req) async {
    final uri = Uri.parse('$_base/api/checkins/$checkInId/answers');
    final res = await _client
        .post(uri, headers: _headers(), body: jsonEncode(req.toJson()))
        .timeout(_timeout);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to submit answers: ${res.statusCode} ${res.body}');
    }
  }

  void close() => _client.close();
}
