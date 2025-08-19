import '../apis/google_classroom_api.dart';
import '../models/course.dart';
import '../models/assignment.dart';

class GoogleClassroomService {
  static Future<Map<String, dynamic>> createGoogleForm({
    required String authToken,
    required String title,
    required String description,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      final formData = {
        'title': title,
        'description': description,
        'questions': questions,
      };

      return await GoogleClassroomApi.createForm(
        authToken: authToken,
        formData: formData,
      );
    } catch (e) {
      throw Exception('Failed to create Google Form: $e');
    }
  }

  static Future<Map<String, dynamic>> createClassroomAssignment({
    required String authToken,
    required String courseId,
    required String title,
    required String description,
    double? maxPoints,
  }) async {
    try {
      final assignmentData = {
        'courseId': courseId,
        'title': title,
        'description': description,
        if (maxPoints != null) 'maxPoints': maxPoints,
      };

      return await GoogleClassroomApi.createClassroomAssignment(
        authToken: authToken,
        assignmentData: assignmentData,
      );
    } catch (e) {
      throw Exception('Failed to create classroom assignment: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getChatLogs({
    required String authToken,
    required String courseId,
  }) async {
    try {
      final response = await GoogleClassroomApi.getChatLogs(
        authToken: authToken,
        courseId: courseId,
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['logs'] ?? []);
      } else {
        throw Exception(response['error'] ?? 'Failed to get chat logs');
      }
    } catch (e) {
      throw Exception('Failed to get chat logs: $e');
    }
  }

  // Helper method to parse quiz content for Google Forms
  static List<Map<String, dynamic>> parseQuizContent(String content) {
    List<Map<String, dynamic>> questions = [];
    List<String> lines = content.split('\n');
    
    String currentQuestion = '';
    List<String> options = [];
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Detect question (starts with number or "Question")
      if (RegExp(r'^\d+\.|\bQuestion\s+\d+').hasMatch(line)) {
        // Save previous question if exists
        if (currentQuestion.isNotEmpty) {
          questions.add({
            'title': currentQuestion,
            'type': options.isNotEmpty ? 'MULTIPLE_CHOICE' : 'SHORT_ANSWER',
            'options': List.from(options),
            'required': true,
          });
        }
        
        // Start new question
        currentQuestion = line.replaceFirst(RegExp(r'^\d+\.\s*|Question\s+\d+:\s*'), '');
        options.clear();
      }
      // Detect multiple choice options
      else if (RegExp(r'^[a-dA-D][\.\)]\s+').hasMatch(line)) {
        String option = line.replaceFirst(RegExp(r'^[a-dA-D][\.\)]\s+'), '');
        options.add(option);
      }
      // Continue question text
      else if (currentQuestion.isNotEmpty && !line.startsWith('Answer:')) {
        currentQuestion += ' ' + line;
      }
    }
    
    // Add last question
    if (currentQuestion.isNotEmpty) {
      questions.add({
        'title': currentQuestion,
        'type': options.isNotEmpty ? 'MULTIPLE_CHOICE' : 'SHORT_ANSWER',
        'options': List.from(options),
        'required': true,
      });
    }
    
    return questions;
  }
}