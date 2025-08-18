import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/server_constants.dart';

class MoodleApi {
  static const String _baseUrl = ServerConstants.baseUrl;
  static const String _endpoint = ServerConstants.moodleEndpoint;

  static Future<Map<String, dynamic>> exportMaterial({
    required String authToken,
    required Map<String, dynamic> exportData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/export'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(exportData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to export material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getCourseNotes({
    required String authToken,
    required String courseId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/notes/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get course notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getChatLogs({
    required String authToken,
    required String courseId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_endpoint/chat-logs/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get chat logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}