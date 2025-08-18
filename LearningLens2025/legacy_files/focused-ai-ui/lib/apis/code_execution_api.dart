import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/server_constants.dart';
import '../models/code_file.dart';
import '../services/auth_service.dart';

class CodeExecutionApi {
  Future<Map<String, dynamic>> executeCode({
    required List<CodeFile> codeFiles,
    required String mainClassName,
    required String language,
  }) async {
    try {
      // Prepare the payload
      final payload = {
        'files': codeFiles.map((file) => file.toJson()).toList(),
        'mainClassName': mainClassName,
      };

      final response = await http
          .post(
            Uri.parse(
              '${ServerConstants.ogServerUrl}/compiler/execute/$language',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...authService.authHeaders,
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout after 30 seconds');
            },
          );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        return {
          'success': false,
          'output': '',
          'error': 'Server error (${response.statusCode}): ${response.body}',
        };
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Cannot resolve server - Backend server not running?';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connection refused - Backend server not running?';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout - Backend server may be overloaded';
      } else {
        errorMessage = 'Network error: $e';
      }

      return {'success': false, 'output': '', 'error': errorMessage};
    }
  }
}
