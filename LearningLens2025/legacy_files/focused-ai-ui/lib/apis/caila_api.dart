// lib/apis/caila_api.dart - FIXED VERSION with Better Timeouts
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/server_constants.dart';
import '../services/auth_service.dart';

class CailaApi {
  // Different timeouts for different types of requests
  static const Duration _chatTimeout = Duration(seconds: 45);  // Increased from 30
  static const Duration _generateTimeout = Duration(minutes: 3);  // Much longer for generation
  static const Duration _historyTimeout = Duration(seconds: 30);
  static const Duration _evaluateTimeout = Duration(minutes: 2);
  
  static Future<Map<String, dynamic>> chat({
    required String authToken,
    required String prompt,
    String? courseId,
    String? studentId,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    try {
      print('CailaApi: Starting chat request with prompt length: ${prompt.length}');
      
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/chat'),
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
      ).timeout(
        _chatTimeout,
        onTimeout: () {
          throw Exception('Chat request timed out after ${_chatTimeout.inSeconds} seconds. Please try a shorter message or try again.');
        },
      );

      print('CailaApi: Chat response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('CailaApi: Chat response received successfully');
        return responseData;
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else if (response.statusCode == 408 || response.statusCode == 504) {
        throw Exception('Server timeout - the AI is taking longer than usual. Please try again with a simpler request.');
      } else {
        throw Exception('Chat failed with status ${response.statusCode}: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('CailaApi: Chat error: $e');
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        throw Exception('Request timed out. The AI is taking longer than usual - please try a shorter or simpler request.');
      }
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
      print('CailaApi: Starting material generation for type: $materialType');
      print('CailaApi: Prompt length: ${prompt.length}');
      
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/generate'),
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
      ).timeout(
        _generateTimeout,
        onTimeout: () {
          throw Exception('Material generation timed out after ${_generateTimeout.inMinutes} minutes. This can happen with complex requests. Please try:\n\n• Breaking your request into smaller parts\n• Being more specific about what you want\n• Trying again (the server might be busy)');
        },
      );

      print('CailaApi: Generate response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('CailaApi: Material generation completed successfully');
        return responseData;
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else if (response.statusCode == 408 || response.statusCode == 504) {
        throw Exception('Material generation timed out on the server. This can happen with complex requests. Please try:\n\n• Simplifying your request\n• Breaking it into smaller parts\n• Waiting a moment and trying again');
      } else {
        throw Exception('Material generation failed with status ${response.statusCode}: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('CailaApi: Generate material error: $e');
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        throw Exception('Material generation is taking longer than expected. Please try:\n\n• Making your request more specific\n• Breaking complex requests into smaller parts\n• Trying again in a moment');
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getChatHistory({
    required String authToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        _historyTimeout,
        onTimeout: () {
          throw Exception('Chat history request timed out after ${_historyTimeout.inSeconds} seconds');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to get chat history: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
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
      print('CailaApi: Generating material from request - Type: $materialType, Title: $title');
      
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/materials/generate'),
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
      ).timeout(
        _generateTimeout,
        onTimeout: () {
          throw Exception('Material generation timed out. Please try with a simpler request or try again.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to generate material: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
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
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/materials/teacher/$teacherId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        _historyTimeout,
        onTimeout: () {
          throw Exception('Request timed out after ${_historyTimeout.inSeconds} seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to get teacher materials: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
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
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/materials/$materialId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        _historyTimeout,
        onTimeout: () {
          throw Exception('Request timed out after ${_historyTimeout.inSeconds} seconds');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to get material: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add new method for student logs (for teachers to view)
  static Future<Map<String, dynamic>> getStudentChatLogs({
    required String authToken,
    required String courseId,
    String? studentId,
  }) async {
    try {
      final uri = Uri.parse('${ServerConstants.cailaServerUrl}/caila/logs/$courseId');
      final finalUri = studentId != null 
          ? uri.replace(queryParameters: {'studentId': studentId})
          : uri;

      final response = await http.get(
        finalUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(
        _historyTimeout,
        onTimeout: () {
          throw Exception('Request timed out after ${_historyTimeout.inSeconds} seconds');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to get student chat logs: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add method for evaluating student answers
  static Future<Map<String, dynamic>> evaluateAnswer({
    required String authToken,
    required String assignmentId,
    required String studentAnswer,
    String? rubric,
    String? courseId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/evaluate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'assignmentId': assignmentId,
          'studentAnswer': studentAnswer,
          if (rubric != null) 'rubric': rubric,
          if (courseId != null) 'courseId': courseId,
        }),
      ).timeout(
        _evaluateTimeout,
        onTimeout: () {
          throw Exception('Answer evaluation timed out after ${_evaluateTimeout.inMinutes} minutes. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to evaluate answer: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add method for generating rubrics
  static Future<Map<String, dynamic>> generateRubric({
    required String authToken,
    required String assignmentPrompt,
    String? courseId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/rubric/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'assignmentPrompt': assignmentPrompt,
          if (courseId != null) 'courseId': courseId,
        }),
      ).timeout(
        _generateTimeout,
        onTimeout: () {
          throw Exception('Rubric generation timed out. Please try with a simpler assignment description.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else {
        throw Exception('Failed to generate rubric: ${response.statusCode}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method to determine if a request is likely to be a material generation request
  static bool _isMaterialGenerationRequest(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    return lowerPrompt.contains('create') || 
           lowerPrompt.contains('generate') || 
           lowerPrompt.contains('make') ||
           lowerPrompt.contains('assignment') ||
           lowerPrompt.contains('quiz') ||
           lowerPrompt.contains('lesson') ||
           lowerPrompt.contains('worksheet') ||
           lowerPrompt.contains('rubric');
  }

  // Enhanced chat method that automatically uses appropriate timeout based on request type
  static Future<Map<String, dynamic>> chatWithAdaptiveTimeout({
    required String authToken,
    required String prompt,
    String? courseId,
    String? studentId,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    // Determine if this looks like a material generation request
    final isGenerationRequest = _isMaterialGenerationRequest(prompt);
    final timeout = isGenerationRequest ? _generateTimeout : _chatTimeout;
    
    try {
      print('CailaApi: Using ${timeout.inSeconds}s timeout for ${isGenerationRequest ? "generation" : "chat"} request');
      
      final response = await http.post(
        Uri.parse('${ServerConstants.cailaServerUrl}/caila/chat'),
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
      ).timeout(
        timeout,
        onTimeout: () {
          print("we timed out here for some reason");
          if (isGenerationRequest) {
            throw Exception('Material generation is taking longer than expected (${timeout.inMinutes} minutes). Please try:\n\n• Making your request more specific\n• Breaking complex requests into smaller parts\n• Trying again in a moment');
          } else {
            throw Exception('Request timed out after ${timeout.inSeconds} seconds. Please try a shorter message.');
          }
        },
      );
print("didn't time out but response code is ${response.statusCode}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await authService.handleUnauthorized();
        throw SessionExpiredException();
      } else if (response.statusCode == 408 || response.statusCode == 504) {
        throw Exception('Server is taking longer than usual. Please try again with a simpler request.');
      } else {
        throw Exception('Request failed with status ${response.statusCode}: ${response.body}');
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      print('CailaApi: Error with adaptive timeout: $e');
      if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
        if (isGenerationRequest) {
          throw Exception('Material generation is taking too long. Please try:\n\n• Simplifying your request\n• Being more specific about what you want\n• Breaking complex requests into parts\n• Trying again (server might be busy)');
        } else {
          throw Exception('Request timed out. Please try a shorter or simpler message.');
        }
      }
      throw Exception('Network error: $e');
    }
  }

  // Get teacher chat history
  static Future<Map<String, dynamic>> getTeacherChatHistory({
  required String authToken,
}) async {
  try {
    print('CailaApi: Getting teacher chat history');
    
    final response = await http.get(
      Uri.parse('${ServerConstants.cailaServerUrl}/caila/history/teacher'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    ).timeout(
      _historyTimeout,
      onTimeout: () {
        throw Exception('Teacher chat history request timed out after ${_historyTimeout.inSeconds} seconds');
      },
    );

    print('CailaApi: Teacher history response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('CailaApi: Teacher history response received successfully');
      return responseData;
    } else if (response.statusCode == 401) {
      await authService.handleUnauthorized();
      throw SessionExpiredException();
    } else {
      throw Exception('Failed to get teacher chat history: ${response.statusCode}');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print('CailaApi: Teacher history error: $e');
    throw Exception('Network error: $e');
  }
}

  static Future<Map<String, dynamic>> getTeacherChatSession({
  required String authToken,
  required String sessionId,
}) async {
  try {
    print('CailaApi: Getting teacher chat session: $sessionId');
    
    final response = await http.get(
      Uri.parse('${ServerConstants.cailaServerUrl}/caila/history/teacher/session/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    ).timeout(
      _historyTimeout,
      onTimeout: () {
        throw Exception('Teacher chat session request timed out after ${_historyTimeout.inSeconds} seconds');
      },
    );

    print('CailaApi: Teacher session response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('CailaApi: Teacher session response received successfully');
      return responseData;
    } else if (response.statusCode == 401) {
      await authService.handleUnauthorized();
      throw SessionExpiredException();
    } else {
      throw Exception('Failed to get teacher chat session: ${response.statusCode}');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print('CailaApi: Teacher session error: $e');
    throw Exception('Network error: $e');
  }
}

static Future<Map<String, dynamic>> resumeChatSession({
  required String authToken,
  required String prompt,
  required String sessionId,
  required List<Map<String, String>> conversationHistory,
  String? courseId,
}) async {
  try {
    print('CailaApi: Resuming chat session: $sessionId');
    
    final response = await http.post(
      Uri.parse('${ServerConstants.cailaServerUrl}/caila/chat/resume'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'prompt': prompt,
        'sessionId': sessionId,
        'conversationHistory': conversationHistory,
        if (courseId != null) 'courseId': courseId,
      }),
    ).timeout(
      _chatTimeout,
      onTimeout: () {
        throw Exception('Resume chat request timed out after ${_chatTimeout.inSeconds} seconds');
      },
    );

    print('CailaApi: Resume chat response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('CailaApi: Resume chat response received successfully');
      return responseData;
    } else if (response.statusCode == 401) {
      await authService.handleUnauthorized();
      throw SessionExpiredException();
    } else {
      throw Exception('Failed to resume chat session: ${response.statusCode}');
    }
  } on SessionExpiredException {
    rethrow;
  } catch (e) {
    print('CailaApi: Resume chat error: $e');
    if (e.toString().contains('timeout') || e.toString().contains('timed out')) {
      throw Exception('Resume chat request timed out. Please try again.');
    }
    throw Exception('Network error: $e');
  }
}
}