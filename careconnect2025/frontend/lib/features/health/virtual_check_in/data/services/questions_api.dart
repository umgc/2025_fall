// lib/features/health/virtual-check-in/data/questions_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:care_connect_app/features/health/virtual_check_in/data/dto/virtual_check_in_backend_question_dto.dart';


class QuestionsApi {
  QuestionsApi(this.baseUrl);
  final String baseUrl; // e.g. http://192.168.1.155:8080

  Future<List<BackendQuestionDTO>> listQuestions({bool? active}) async {
    final uri = Uri.parse('$baseUrl/api/questions')
        .replace(queryParameters: {
      if (active != null) 'active': active.toString(),
    });
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch questions: ${res.statusCode} ${res.body}');
    }
    final List<dynamic> arr = json.decode(res.body) as List<dynamic>;
    return arr.map((e) => BackendQuestionDTO.fromJson(e as Map<String, dynamic>)).toList();
  }
}
