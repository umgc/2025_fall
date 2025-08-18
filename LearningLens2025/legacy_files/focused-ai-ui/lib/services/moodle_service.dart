import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:focused_ai_ui/models/assignment.dart';
import 'package:focused_ai_ui/models/course.dart';
import 'package:focused_ai_ui/models/submission.dart';
import 'package:focused_ai_ui/services/auth_service.dart';

import '../apis/moodle_api.dart';
import '../models/lms.dart';
import '../models/user.dart';
import '../models/user_role.dart';

class MoodleService {
  final MoodleApi _api = MoodleApi();

  Future<Map<String, dynamic>> login(
    String moodleUrl,
    String username,
    String password,
  ) async {
    print('MoodleService: Sending Moodle login request to backend...');
    try {
      final Map<String, dynamic>? backendResponse = await _api.moodleLogin(
        moodleUrl,
        username,
        password,
      );

      if (backendResponse != null && backendResponse.containsKey('jwt')) {
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == backendResponse['role'],
          orElse: () => UserRole.unknown,
        );

        final User user = User(
          id: backendResponse['id'] as String,
          username: username,
          role: role,
          lmsType: LMS.moodle,
        );

        return {'user': user, 'jwt': backendResponse['jwt']};
      } else {
        throw Exception('Moodle login failed: Invalid response from backend');
      }
    } catch (e) {
      print('MoodleService: Error during Moodle login via backend: $e');
      rethrow;
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _api.protectedRequest('GET', '/moodle/courses');

      print('Raw response: $response');
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
      print('Full error details: $e');
      throw Exception('Failed to get courses: ${e.toString()}');
    }
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    try {
      final response = await _api.protectedRequest(
        'GET',
        '/moodle/courses/$courseId/assignments',
      );

      print('Moodle assignments response: $response');
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
        '/moodle/courses/$courseId/assignments/$assignmentId/submissions',
      );

      print('Moodle submissions response: $response');
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

  Future<List<Assignment>> getCourseAssignments({
    required String authToken,
    required String courseId,
  }) async {
    try {
      final response = await _api.protectedRequest(
        'GET',
        '/moodle/assignments/course/$courseId',
      );

      if (response['success'] == true) {
        final assignmentsList = response['assignments'] as List<dynamic>;
        return assignmentsList.map((assignmentData) {
          return Assignment.fromJson(assignmentData as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception(response['error'] ?? 'Failed to load assignments');
      }
    } catch (e) {
      throw Exception('Failed to get course assignments: $e');
    }
  }

  Future<List<Map<String, String>>> getAssignmentChatHistory({
    required String authToken,
    required String assignmentId,
  }) async {
    try {
      print('=== FLUTTER: GETTING MOODLE ASSIGNMENT CHAT HISTORY ===');
      print('Assignment ID: $assignmentId');

      // FIXED: Use the MoodleApi protectedRequest method correctly
      final response = await _api.protectedRequest(
        'GET',
        '/caila/chat/assignment/$assignmentId/history',
      );

      print('Flutter: Assignment history response received');
      print('Response type: ${response.runtimeType}');
      print('Response keys: ${response is Map ? response.keys : 'Not a map'}');

      // FIXED: Handle the new response format from backend
      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          // Extract the chatHistory from the response
          final chatHistoryData = response['chatHistory'];

          if (chatHistoryData is List) {
            List<Map<String, String>> formattedHistory = [];

            for (final chat in chatHistoryData) {
              if (chat is Map<String, dynamic>) {
                formattedHistory.add({
                  'role': chat['role']?.toString() ?? '',
                  'content': chat['content']?.toString() ?? '',
                  'timestamp':
                      chat['timestamp']?.toString() ??
                      DateTime.now().toIso8601String(),
                });
              }
            }

            print(
              'Flutter: Successfully parsed ${formattedHistory.length} chat messages for assignment',
            );
            print(
              '=== END FLUTTER: GETTING MOODLE ASSIGNMENT CHAT HISTORY ===',
            );

            return formattedHistory;
          } else {
            print(
              'Flutter: chatHistory is not a List: ${chatHistoryData.runtimeType}',
            );
          }
        } else {
          print(
            'Flutter: Assignment history request failed: ${response['error']}',
          );
        }
      } else {
        print('Flutter: Unexpected response format: ${response.runtimeType}');
      }

      print('Flutter: Returning empty chat history');
      return [];
    } catch (e, stackTrace) {
      print('Flutter: Error getting Moodle assignment chat history: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  String getAssignmentUrgency(Assignment assignment) {
    if (assignment.status == 'submitted') return 'completed';
    if (assignment.dueDate == null) return 'no_deadline';

    final now = DateTime.now();
    final difference = assignment.dueDate!.difference(now);

    if (difference.isNegative) {
      return 'overdue';
    } else if (difference.inHours <= 24) {
      return 'due_soon';
    } else if (difference.inDays <= 3) {
      return 'due_this_week';
    } else {
      return 'normal';
    }
  }

  String formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      final daysPast = difference.inDays.abs();
      if (daysPast == 0) {
        return 'Due today (overdue)';
      } else if (daysPast == 1) {
        return 'Due yesterday (overdue)';
      } else {
        return 'Due $daysPast days ago (overdue)';
      }
    } else {
      final daysUntil = difference.inDays;
      if (daysUntil == 0) {
        final hoursUntil = difference.inHours;
        if (hoursUntil <= 1) {
          return 'Due in ${difference.inMinutes} minutes';
        } else {
          return 'Due in $hoursUntil hours';
        }
      } else if (daysUntil == 1) {
        return 'Due tomorrow';
      } else if (daysUntil <= 7) {
        return 'Due in $daysUntil days';
      } else {
        return 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    }
  }

  Future<String> chatWithAssignment({
    required String authToken,
    required String prompt,
    required String courseId,
    required String assignmentId,
    String? sessionId,
  }) async {
    try {
      // Use persistent session ID based on assignment
      final effectiveSessionId =
          sessionId ?? 'assignment_${assignmentId}_session';

      final response = await _api.protectedRequest(
        'POST',
        '/caila/chat/assignment',
        body: {
          'prompt': prompt,
          'courseId': courseId,
          'assignmentId': assignmentId,
          'sessionId': effectiveSessionId,
        },
      );

      if (response['success'] == true) {
        return response['response'] ?? 'No response received';
      } else {
        throw Exception(response['error'] ?? 'Chat failed');
      }
    } catch (e) {
      throw Exception('Failed to chat about assignment: $e');
    }
  }

  Color getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'overdue':
        return Colors.red;
      case 'due_soon':
        return Colors.orange;
      case 'due_this_week':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      case 'assigned':
      default:
        return Icons.assignment;
    }
  }
}
