import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

class GradingService {
  final String baseUrl = 'http://localhost:8080/api';

  // === SYSTEM STATUS ===
  
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/status'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get system status');
      }
    } catch (e) {
      throw Exception('Cannot connect to grading service: $e');
    }
  }

  // === COURSE MANAGEMENT ===
  
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get courses');
      }
    } catch (e) {
      throw Exception('Error getting courses: $e');
    }
  }

  Future<Map<String, dynamic>?> getCourse(String courseId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses/$courseId'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get course');
      }
    } catch (e) {
      throw Exception('Error getting course: $e');
    }
  }

  // === ASSIGNMENT MANAGEMENT ===
  
  Future<Assignment> createAssignmentForCourse(String courseId, Assignment assignment) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courses/$courseId/assignments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(assignment.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Assignment.fromJson(data['assignment']);
      } else {
        throw Exception('Failed to create assignment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating assignment: $e');
    }
  }

  Future<List<Assignment>> getAssignmentsByCourse(String courseId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courses/$courseId/assignments'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Assignment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get assignments for course');
      }
    } catch (e) {
      throw Exception('Error getting assignments: $e');
    }
  }

  Future<List<Assignment>> getAssignments() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assignments'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Assignment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get assignments');
      }
    } catch (e) {
      throw Exception('Error getting assignments: $e');
    }
  }

  Future<Assignment?> getAssignment(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assignments/$id'));
      
      if (response.statusCode == 200) {
        return Assignment.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get assignment');
      }
    } catch (e) {
      throw Exception('Error getting assignment: $e');
    }
  }

  Future<bool> deleteAssignment(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/assignments/$id'));
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else {
        throw Exception('Failed to delete assignment');
      }
    } catch (e) {
      throw Exception('Error deleting assignment: $e');
    }
  }

  // === SUBMISSION MANAGEMENT ===
  
  Future<List<StudentSubmission>> getSubmissionsByAssignment(String assignmentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assignments/$assignmentId/submissions'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StudentSubmission.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get submissions');
      }
    } catch (e) {
      throw Exception('Error getting submissions: $e');
    }
  }

  Future<Map<String, dynamic>> uploadSubmissions(
    String assignmentId, 
    List<StudentSubmission> submissions
  ) async {
    try {
      final payload = {
        'submissions': submissions.map((s) => s.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/assignments/$assignmentId/submissions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload submissions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading submissions: $e');
    }
  }

  // === GRADING MANAGEMENT ===
  
  Future<Map<String, dynamic>> gradeSubmission(
    String submissionId,
    double score,
    String feedback,
  ) async {
    try {
      final payload = {
        'score': score,
        'feedback': feedback,
        'gradedAt': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/submissions/$submissionId/grade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to grade submission: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error grading submission: $e');
    }
  }

  Future<Map<String, dynamic>?> getGrade(String submissionId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/submissions/$submissionId/grade'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['graded'] == true) {
          return data['grade'];
        }
        return null;
      } else {
        throw Exception('Failed to get grade');
      }
    } catch (e) {
      throw Exception('Error getting grade: $e');
    }
  }

  Future<Map<String, dynamic>> gradeAllSubmissions(String assignmentId) async {
    try {
      final payload = {
        'autoGrade': true,
        'batchMode': true,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/assignments/$assignmentId/grade-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to start batch grading: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error starting batch grading: $e');
    }
  }

  // === TEST FILE MANAGEMENT ===
  
  Future<Map<String, dynamic>> uploadTestFiles(
    String assignmentId,
    PlatformFile? inputFile,
    PlatformFile? outputFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/assignments/$assignmentId/test-files')
      );

      if (inputFile != null && inputFile.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'inputFile',
            inputFile.bytes!,
            filename: inputFile.name,
          ),
        );
      }

      if (outputFile != null && outputFile.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'outputFile',
            outputFile.bytes!,
            filename: outputFile.name,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      } else {
        throw Exception('Failed to upload test files: $responseData');
      }
    } catch (e) {
      throw Exception('Error uploading test files: $e');
    }
  }

  // === CODE EXECUTION (Mock Implementation) ===
  
  Future<Map<String, dynamic>> executeCode(
    String code,
    String language,
    String? input,
  ) async {
    // Mock code execution - in production, integrate with actual code execution service
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate different outputs based on code content
    String output;
    bool success = true;
    
    if (code.toLowerCase().contains('hello')) {
      output = 'Hello, World!';
    } else if (code.toLowerCase().contains('error')) {
      output = 'Error: Compilation failed';
      success = false;
    } else {
      output = 'Program executed successfully';
    }
    
    return {
      'success': success,
      'output': output,
      'executionTime': 150, // milliseconds
      'memory': 1024, // KB
    };
  }

  // === UTILITY METHODS ===
  
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final futures = await Future.wait([
        http.get(Uri.parse('$baseUrl/assignments/count')),
        http.get(Uri.parse('$baseUrl/submissions/count')),
        http.get(Uri.parse('$baseUrl/grades/count')),
      ]);

      final stats = <String, dynamic>{};
      
      if (futures[0].statusCode == 200) {
        stats['assignments'] = jsonDecode(futures[0].body)['count'];
      }
      
      if (futures[1].statusCode == 200) {
        stats['submissions'] = jsonDecode(futures[1].body)['count'];
      }
      
      if (futures[2].statusCode == 200) {
        stats['grades'] = jsonDecode(futures[2].body)['count'];
      }

      return stats;
    } catch (e) {
      throw Exception('Error getting system statistics: $e');
    }
  }

  // === LEGACY COMPATIBILITY METHODS ===
  
  // For backward compatibility with existing create assignment screen
  Future<Assignment> createAssignment(Assignment assignment) async {
    // Default to first course for legacy compatibility
    final courses = await getCourses();
    if (courses.isEmpty) {
      throw Exception('No courses available. Please create a course first.');
    }
    
    return createAssignmentForCourse(courses.first['id'], assignment);
  }

  // For backward compatibility with existing upload submissions screen
  Future<Map<String, dynamic>> startGrading(
    String assignmentId,
    List<StudentSubmission> submissions,
  ) async {
    // Upload submissions first, then start grading
    await uploadSubmissions(assignmentId, submissions);
    return gradeAllSubmissions(assignmentId);
  }

  // === MOCK DATA METHODS (for development/testing) ===
  
  /// Generate mock submissions for testing the code editor interface
  List<StudentSubmission> generateMockSubmissions(String assignmentId) {
    return [
      StudentSubmission(
        id: 'sub1',
        studentId: 'student001',
        studentName: 'John Doe',
        filename: 'Main.java',
        code: '''public class Main {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}''',
        assignmentId: assignmentId,
        status: 'uploaded',
        fileExtension: 'java',
        fileSize: 156,
      ),
      StudentSubmission(
        id: 'sub2',
        studentId: 'student002',
        studentName: 'Jane Smith',
        filename: 'Solution.java',
        code: '''public class Solution {
    public static void main(String[] args) {
        System.out.println("Hello from Jane!");
        System.out.println("This is my solution.");
    }
}''',
        assignmentId: assignmentId,
        status: 'uploaded',
        fileExtension: 'java',
        fileSize: 203,
      ),
      StudentSubmission(
        id: 'sub3',
        studentId: 'student003',
        studentName: 'Bob Johnson',
        filename: 'assignment.py',
        code: '''def main():
    print("Hello, World!")
    print("Python solution by Bob")

if __name__ == "__main__":
    main()''',
        assignmentId: assignmentId,
        status: 'graded',
        fileExtension: 'py',
        fileSize: 178,
        gradeId: 'grade123',
      ),
    ];
  }

  /// Generate mock courses for testing
  List<Map<String, dynamic>> generateMockCourses() {
    return [
      {
        'id': 'CS101',
        'name': 'Introduction to Computer Science',
        'description': 'Basic programming concepts and problem solving',
        'instructor': 'Dr. Smith',
      },
      {
        'id': 'CS201',
        'name': 'Data Structures and Algorithms',
        'description': 'Advanced programming with data structures',
        'instructor': 'Prof. Johnson',
      },
      {
        'id': 'CS301',
        'name': 'Software Engineering',
        'description': 'Software development practices and methodologies',
        'instructor': 'Dr. Williams',
      },
    ];
  }
}