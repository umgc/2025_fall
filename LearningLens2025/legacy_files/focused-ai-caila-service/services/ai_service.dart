import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiUrl = 'https://api.deepseek.com/chat/completions'; // adjust as needed
  static const String apiKey = 'sk-f4ab0b9470de49b58ddd0470294e8240';

  static Future<String> sendMessage(String prompt) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/caila/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data']?['response'] ?? 'No response';
    } else {
      throw Exception('Failed to get AI response');
    }
  }

  static Future<String> generateRubric(String prompt) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/caila/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data']?['response'] ?? 'No response';
    } else {
      throw Exception('Rubric generation failed');
    }
  }
}
