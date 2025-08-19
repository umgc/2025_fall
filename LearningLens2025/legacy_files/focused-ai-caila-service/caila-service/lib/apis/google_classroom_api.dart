import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/server_constants.dart';

class GoogleClassroomApi {
  static const String _baseUrl = ServerConstants.baseUrl;
  static const String _endpoint = ServerConstants.googleEndpoint;

  static Future<Map<String, dynamic>> createForm({
    required String authToken,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/forms/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create form: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createClassroomAssignment({
    required String authToken,
    required Map<String, dynamic> assignmentData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint/classroom/assignment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(assignmentData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create classroom assignment: ${response.statusCode}');
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
        Uri.parse('$_baseUrl$_endpoint/drive/chat-logs/$courseId'),
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