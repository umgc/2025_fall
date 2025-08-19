import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/server_constants.dart';

class CailaApi {
  static const String _baseUrl = ServerConstants.baseUrl;
  static const String _endpoint = ServerConstants.cailaEndpoint;

  static Future<Map<String, dynamic>> chat({
    required String authToken,
    required String prompt,
    String? courseId,
    String? studentId,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'prompt': prompt,
          if (courseId != null) 'courseId': courseId,
          if (studentId != null) 'studentId': studentId,
          if (sessionId != null) 'sessionId': sessionId,
          if (history != null) 'history': history,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to chat with CAILA: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> generateMaterial({
    required String authToken,
    required String prompt,
    String? materialType,
    String? courseId,
    String? title,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'prompt': prompt,
          if (materialType != null) 'materialType': materialType,
          if (courseId != null) 'courseId': courseId,
          if (title != null) 'title': title,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getChatHistory({
    required String authToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get chat history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> generateMaterialFromRequest({
    required String authToken,
    required String title,
    required String materialType,
    required String content,
    required String prompt,
    String? courseId,
    String? courseName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/materials/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'title': title,
          'materialType': materialType,
          'content': content,
          'prompt': prompt,
          if (courseId != null) 'courseId': courseId,
          if (courseName != null) 'courseName': courseName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherMaterials({
    required String authToken,
    required String teacherId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/materials/teacher/$teacherId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get teacher materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getMaterial({
    required String authToken,
    required String materialId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/materials/$materialId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}