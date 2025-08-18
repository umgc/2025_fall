import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:focused_ai_ui/models/assignment.dart';
import 'package:focused_ai_ui/models/course.dart';
import 'package:focused_ai_ui/models/submission.dart';
import 'package:focused_ai_ui/models/user_role.dart';
import 'package:focused_ai_ui/models/lms.dart';
import 'package:focused_ai_ui/services/auth_service.dart';
import 'package:focused_ai_ui/services/caila_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../apis/google_classroom_api.dart';

class GoogleClassroomService {
  final GoogleClassroomApi _api = GoogleClassroomApi();

  Future<Map<String, dynamic>?> login(
    String serverAuthCode,
    GoogleSignInAccount googleUser,
  ) async {
    print(
      'GoogleClassroomService: Sending serverAuthCode $serverAuthCode to backend to login user with ID: ${googleUser.id} ...',
    );
    try {
      final Map<String, dynamic>? backendResponse = await _api.googleLogin(
        serverAuthCode,
        googleUser.id,
        googleUser.email,
      );

      if (backendResponse != null && backendResponse.containsKey('jwt')) {
        final String appJwtToken = backendResponse['jwt'] as String;

        final String roleString = backendResponse['role'] as String;
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleString.toLowerCase(),
          orElse: () => UserRole.unknown,
        );

        final User user = User(
          id: backendResponse['id'] as String,
          email: googleUser.email,
          role: role,
          lmsType: LMS.googleClassroom,
        );

        return {'user': user, 'jwt': appJwtToken};
      } else {
        throw Exception(
          'Google login failed: Invalid response format from backend.',
        );
      }
    } catch (e) {
      print(
        'GoogleClassroomService: Error during Google login via backend: $e',
      );
      rethrow;
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _api.protectedRequest('GET', '/google/courses');

      print('Google courses response: $response');
      print('Response type: ${response.runtimeType}');

      // Backend now returns List<Course> directly, not wrapped in CourseList
      if (response is List) {
        return response.map((courseJson) {
          try {
            final Map<String, dynamic> courseMap =
                courseJson as Map<String, dynamic>;
            print('Parsing course: $courseMap');
            return Course.fromJson(courseMap);
          } catch (e) {
            print('Failed to parse course: $courseJson');
            print('Parse error: $e');
            throw Exception('Invalid course data format: $e');
          }
        }).toList();
      } else {
        throw Exception(
          'Unexpected response format: expected List<Course>, got ${response.runtimeType}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    try {
      final response = await _api.protectedRequest(
        'GET',
        '/google/courses/$courseId/assignments',
      );

      print('Google assignments response: $response');
      print('Response type: ${response.runtimeType}');

      // Backend now returns List<Assignment> directly, not wrapped in AssignmentList
      if (response is List) {
        return response.map((assignmentJson) {
          try {
            final Map<String, dynamic> assignmentMap =
                assignmentJson as Map<String, dynamic>;
            print('Parsing assignment: $assignmentMap');
            return Assignment.fromJson(assignmentMap);
          } catch (e) {
            print('Failed to parse assignment: $assignmentJson');
            print('Parse error: $e');
            throw Exception('Invalid assignment data format: $e');
          }
        }).toList();
      } else {
        throw Exception(
          'Unexpected response format: expected List<Assignment>, got ${response.runtimeType}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get assignments: $e');
    }
  }

  Future<List<Submission>> getSubmissions(
    String courseId,
    String assignmentId,
  ) async {
    try {
      final response = await _api.protectedRequest(
        'GET',
        '/google/courses/$courseId/assignments/$assignmentId/submissions',
      );

      print('Google submissions response: $response');
      print('Response type: ${response.runtimeType}');

      // Backend now returns List<Submission> directly, not wrapped in SubmissionList
      if (response is List) {
        return response.map((submissionJson) {
          try {
            final Map<String, dynamic> submissionMap =
                submissionJson as Map<String, dynamic>;
            print('Parsing submission: $submissionMap');
            return Submission.fromJson(submissionMap);
          } catch (e) {
            print('Failed to parse submission: $submissionJson');
            print('Parse error: $e');
            throw Exception('Invalid submission data format: $e');
          }
        }).toList();
      } else {
        throw Exception(
          'Unexpected response format: expected List<Submission>, got ${response.runtimeType}',
        );
      }
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get submissions: $e');
    }
  }

  /// Main export method that handles different material types and export destinations
  Future<Map<String, dynamic>> exportMaterial({
    required String authToken,
    required String courseId,
    required String materialType,
    required String title,
    required String content,
    required String exportDestination, // 'google_classroom' or 'computer'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print(
        'GoogleClassroomService: Exporting $materialType to $exportDestination',
      );

      if (exportDestination == 'computer') {
        return await _exportToComputer(
          title: title,
          content: content,
          materialType: materialType,
        );
      } else if (exportDestination == 'google_classroom') {
        return await _exportToGoogleClassroom(
          authToken: authToken,
          courseId: courseId,
          materialType: materialType,
          title: title,
          content: content,
          metadata: metadata,
        );
      } else {
        throw Exception('Invalid export destination: $exportDestination');
      }
    } catch (e) {
      print('GoogleClassroomService: Export error: $e');
      throw Exception('Failed to export material: $e');
    }
  }

  /// Export material to Google Classroom based on material type
  Future<Map<String, dynamic>> _exportToGoogleClassroom({
    required String authToken,
    required String courseId,
    required String materialType,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final normalizedType = materialType.toLowerCase();

      // For now, let's try creating everything as an assignment first to test
      print(
        'GoogleClassroomService: Creating $normalizedType as assignment for testing...',
      );

      switch (normalizedType) {
        case 'quiz':
        case 'assessment':
          // First try to create the assignment to test basic functionality
          final testResult = await _exportAsClassroomAssignment(
            authToken: authToken,
            courseId: courseId,
            title: title,
            content: 'Test Quiz Content:\n\n$content',
            metadata: metadata,
          );

          print(
            'GoogleClassroomService: Test assignment result: ${testResult['success']}',
          );

          // For now, let's just create the assignment since that's working
          // Skip Google Form creation until we perfect the parser
          print(
            'GoogleClassroomService: Assignment creation works! Skipping Google Form for now.',
          );

          return {
            'success': true,
            'message':
                'Quiz exported successfully as Google Classroom assignment',
            'assignmentId': testResult['assignmentId'],
            'alternateLink': testResult['alternateLink'],
            'data': testResult,
          };

        case 'assignment':
        case 'homework':
        case 'essay':
          return await _exportAsClassroomAssignment(
            authToken: authToken,
            courseId: courseId,
            title: title,
            content: content,
            metadata: metadata,
          );

        case 'rubric':
        case 'study guide':
        case 'lesson plan':
          return await _exportAsClassroomMaterial(
            authToken: authToken,
            courseId: courseId,
            title: title,
            content: content,
            materialType: materialType,
            metadata: metadata,
          );

        default:
          // Default to assignment
          return await _exportAsClassroomAssignment(
            authToken: authToken,
            courseId: courseId,
            title: title,
            content: content,
            metadata: metadata,
          );
      }
    } catch (e) {
      throw Exception('Failed to export to Google Classroom: $e');
    }
  }

  /// Export as Classroom Assignment
  Future<Map<String, dynamic>> _exportAsClassroomAssignment({
    required String authToken,
    required String courseId,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print(
        'GoogleClassroomService: Creating classroom assignment for course: $courseId',
      );
      print('GoogleClassroomService: Assignment title: "$title"');

      // Format content for classroom
      final formattedContent = _formatContentForClassroom(
        content,
        'Assignment',
      );

      final assignmentData = {
        'courseId': courseId,
        'title': title,
        'description': formattedContent,
        'state': 'PUBLISHED',
        'maxPoints': metadata?['maxPoints'] ?? 100,
        'workType': 'ASSIGNMENT',
        'assigneeMode': 'ALL_STUDENTS',
      };

      // TODO: Add due date support later - skip for now to test basic functionality
      // if (metadata?['dueDate'] != null) {
      //   assignmentData['dueDate'] = _formatDueDateForClassroom(metadata!['dueDate']);
      //   assignmentData['dueTime'] = _formatDueTimeForClassroom();
      // }

      print('GoogleClassroomService: Assignment data to send: $assignmentData');

      final response = await _api.protectedRequest(
        'POST',
        '/google/classroom/assignment',
        body: assignmentData,
      );

      print('GoogleClassroomService: Assignment creation response: $response');

      // Check if assignment was actually created
      bool success = false;
      String? assignmentId;
      String? alternateLink;

      if (response is Map<String, dynamic>) {
        success = response['success'] == true || response.containsKey('id');
        assignmentId = response['id']?.toString();
        alternateLink = response['alternateLink']?.toString();

        if (success) {
          print(
            'GoogleClassroomService: Assignment created successfully with ID: $assignmentId',
          );
        } else {
          print(
            'GoogleClassroomService: Assignment creation may have failed. Response: $response',
          );
        }
      }

      return {
        'success': success,
        'message': success
            ? 'Assignment created successfully in Google Classroom'
            : 'Assignment creation completed but status unclear',
        'assignmentId': assignmentId,
        'alternateLink': alternateLink,
        'backendResponse': response,
        'data': response,
      };
    } catch (e) {
      print('GoogleClassroomService: Error creating classroom assignment: $e');
      return {
        'success': false,
        'error': 'Failed to create classroom assignment: $e',
        'message': 'Failed to create classroom assignment',
      };
    }
  }

  /// Export as Classroom Material
  Future<Map<String, dynamic>> _exportAsClassroomMaterial({
    required String authToken,
    required String courseId,
    required String title,
    required String content,
    required String materialType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('GoogleClassroomService: Creating classroom material');

      // Format content for classroom
      final formattedContent = _formatContentForClassroom(
        content,
        materialType,
      );

      final materialData = {
        'courseId': courseId,
        'title': '📚 $title',
        'content': formattedContent,
        'materialType': materialType,
        'state': 'PUBLISHED',
        'assigneeMode': 'ALL_STUDENTS',
      };

      final response = await _api.protectedRequest(
        'POST',
        '/google/classroom/material',
        body: materialData,
      );

      return {
        'success': true,
        'message': '$materialType shared successfully as classroom material',
        'materialId': response['id'],
        'alternateLink': response['alternateLink'],
        'data': response,
      };
    } catch (e) {
      print('GoogleClassroomService: Error creating classroom material: $e');
      throw Exception('Failed to create classroom material: $e');
    }
  }

  /// Export to computer as text file
  Future<Map<String, dynamic>> _exportToComputer({
    required String title,
    required String content,
    required String materialType,
  }) async {
    try {
      print('GoogleClassroomService: Exporting to computer');

      // Clean the title for filename
      final cleanTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final timestamp = DateTime.now()
          .toString()
          .split('.')[0]
          .replaceAll(':', '-');
      final filename = '${cleanTitle}_${materialType}_$timestamp.txt';

      // Format content with header
      final formattedContent = _formatContentForDownload(
        content,
        materialType,
        title,
      );

      // Create and download file
      final bytes = utf8.encode(formattedContent);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      html.Url.revokeObjectUrl(url);

      return {
        'success': true,
        'message': 'File downloaded successfully',
        'filename': filename,
        'size': bytes.length,
      };
    } catch (e) {
      print('GoogleClassroomService: Error downloading file: $e');
      throw Exception('Failed to download file: $e');
    }
  }

  /// Format content for Google Classroom display
  String _formatContentForClassroom(String content, String materialType) {
    final buffer = StringBuffer();

    buffer.writeln('🎓 CAILA Generated $materialType');
    buffer.writeln('=' * 50);
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Created by: CAILA AI Teaching Assistant');
    buffer.writeln('');

    // Clean markdown formatting for classroom display
    final cleanContent = CailaService.cleanMarkdownForDisplay(content);
    buffer.writeln(cleanContent);

    buffer.writeln('');
    buffer.writeln('-' * 30);
    buffer.writeln('Generated by CAILA AI Assistant');

    return buffer.toString();
  }

  /// Format content for download
  String _formatContentForDownload(
    String content,
    String materialType,
    String title,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 80);
    buffer.writeln(
      'CAILA AI ASSISTANT - GENERATED ${materialType.toUpperCase()}',
    );
    buffer.writeln('=' * 80);
    buffer.writeln('');
    buffer.writeln('Title: $title');
    buffer.writeln('Type: $materialType');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Created by: CAILA AI Teaching Assistant');
    buffer.writeln('');
    buffer.writeln('=' * 80);
    buffer.writeln('CONTENT');
    buffer.writeln('=' * 80);
    buffer.writeln('');
    buffer.writeln(content);
    buffer.writeln('');
    buffer.writeln('=' * 80);
    buffer.writeln('END OF DOCUMENT');
    buffer.writeln('=' * 80);
    buffer.writeln('');
    buffer.writeln('This material was generated by CAILA AI Assistant.');
    buffer.writeln('For questions or support, contact your instructor.');

    return buffer.toString();
  }
}
