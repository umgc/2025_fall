import '../apis/moodle_api.dart';
import '../models/course.dart';

class MoodleService {
  static Future<Map<String, dynamic>> exportMaterial({
    required String authToken,
    required String courseId,
    required String title,
    required String content,
    required String materialType,
    String exportType = 'note',
  }) async {
    try {
      final exportData = {
        'courseId': courseId,
        'title': title,
        'content': content,
        'materialType': materialType,
        'exportType': exportType,
      };

      return await MoodleApi.exportMaterial(
        authToken: authToken,
        exportData: exportData,
      );
    } catch (e) {
      throw Exception('Failed to export material to Moodle: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCourseNotes({
    required String authToken,
    required String courseId,
  }) async {
    try {
      final response = await MoodleApi.getCourseNotes(
        authToken: authToken,
        courseId: courseId,
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['notes'] ?? []);
      } else {
        throw Exception(response['error'] ?? 'Failed to get course notes');
      }
    } catch (e) {
      throw Exception('Failed to get course notes: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getChatLogs({
    required String authToken,
    required String courseId,
  }) async {
    try {
      final response = await MoodleApi.getChatLogs(
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

  // Helper method to format content for Moodle
  static String formatContentForMoodle(String content, String materialType) {
    final buffer = StringBuffer();
    
    buffer.writeln('<div style="border: 3px solid #ff9800; padding: 15px; margin-bottom: 20px; background-color: #fff3e0;">');
    buffer.writeln('<h2 style="color: #ff9800; margin: 0;">🎓 CAILA Generated ${materialType.toUpperCase()}</h2>');
    buffer.writeln('<p style="margin: 8px 0 0 0;">');
    buffer.writeln('<strong>Generated:</strong> ${DateTime.now().toString().split('.')[0]}<br>');
    buffer.writeln('</p>');
    buffer.writeln('</div>');
    
    buffer.writeln('<div style="border: 1px solid #ddd; padding: 15px; background-color: white;">');
    buffer.writeln(content.replaceAll('\n', '<br>'));
    buffer.writeln('</div>');
    
    return buffer.toString();
  }
}
