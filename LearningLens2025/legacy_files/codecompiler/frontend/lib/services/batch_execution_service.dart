// lib/services/batch_execution_service.dart
// CLEAN VERSION - No duplicate BatchExecutionResult class

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/submission.dart';
import '../models/batch_execution_result.dart'; // ✅ Import from models only
import 'code_execution_service.dart';

class BatchExecutionService {
  static const String baseUrl = 'http://localhost:8080/api/execute';
  
  /// Execute all submissions for an assignment in parallel
  static Future<BatchExecutionResult> executeAllSubmissions({
    required String assignmentId,
    required List<StudentSubmission> submissions,
    String platform = 'focusedai',
  }) async {
    try {
      print('🚀 Starting batch execution for ${submissions.length} submissions');
      
      // Convert submissions to the format expected by backend
      final List<Map<String, dynamic>> submissionData = submissions.map((submission) {
        return {
          'submissionId': submission.id ?? 'unknown',
          'studentId': submission.studentId,
          'studentName': submission.studentName,
          'filename': submission.filename,
          'code': submission.code,
        };
      }).toList();

      final requestBody = {
        'assignmentId': assignmentId,
        'platform': platform,
        'submissions': submissionData,
      };

      print('📤 Sending batch request to backend...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(minutes: 10), // Long timeout for batch processing
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = BatchExecutionResult.fromJson(data);
        
        print('✅ Batch execution completed: ${result.summary}');
        return result;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Batch execution error: $e');
      
      // Return error result using the imported model class
      return BatchExecutionResult(
        batchId: 'error',
        assignmentId: assignmentId,
        results: {},
        totalSubmissions: submissions.length,
        successfulExecutions: 0,
        failedExecutions: submissions.length,
        executionTimeMs: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        platform: platform,
      );
    }
  }

  /// Get the status of a batch execution
  static Future<Map<String, dynamic>?> getBatchStatus(String batchId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/batch/$batchId/status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting batch status: $e');
      return null;
    }
  }

  /// Get supported languages and their configurations
  static Future<Map<String, dynamic>?> getSupportedLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/languages'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting supported languages: $e');
      return null;
    }
  }
}

// ❌ REMOVED: BatchExecutionResult class definition
// It now only exists in lib/models/batch_execution_result.dart