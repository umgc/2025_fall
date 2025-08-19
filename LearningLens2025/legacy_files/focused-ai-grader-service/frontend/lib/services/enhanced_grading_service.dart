// lib/services/enhanced_grading_service.dart - COMPLETE VERSION
// This includes full Google Classroom integration and universal assignment grading

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/assignment.dart';
import '../models/submission.dart';
import 'google_auth_helper.dart';

class EnhancedGradingService {
  static const String googleApiKey = 'AIzaSyC-YG3rr-4rvZrSTCxsFMn1Fr8EuJ_kl4Y';
  
  // Moodle Configuration
  static const String moodleBaseUrl = 'http://18.188.18.80/moodle';
  static const String moodleService = 'fai_moodle';
  
  // Google Classroom Configuration
  static const String classroomBaseUrl = 'https://classroom.googleapis.com/v1';
  
  // Authentication tokens
  String? _moodleToken;
  
  // Platform selection
  String _currentPlatform = 'moodle';
  
  // Moodle user credentials
  static const Map<String, String> moodleUsers = {
    'teacher0': 'Teacher0pass!',
    'teacher1': 'Teacher1pass!',
    'admin': 'UMGC2025teamc!',
  };

  /// Set the current platform
  void setPlatform(String platform) {
    _currentPlatform = platform;
    print('📱 Platform set to: $platform');
  }

  /// Set Google OAuth token
  void setGoogleAccessToken(String token) {
    print('🔐 Setting Google access token in grading service...');
    print('   Token length: ${token.length}');
    print('   Token preview: ${token.substring(0, math.min(20, token.length))}...');
    print('✅ Token management delegated to SimpleGoogleAuth');
  }

  /// Get a valid Google token
  Future<String?> _getValidGoogleToken() async {
    try {
      final token = await SimpleGoogleAuth.getValidToken();
      if (token == null) {
        print('❌ No valid Google token available');
        return null;
      }
      
      print('✅ Got valid Google token (${token.length} chars)');
      return token;
    } catch (e) {
      print('❌ Error getting valid token: $e');
      return null;
    }
  }

  // ============ MOODLE INTEGRATION ============
  
  /// Authenticate with Moodle and get token
  Future<bool> authenticateMoodle(String username) async {
    if (!moodleUsers.containsKey(username)) {
      throw Exception('Invalid Moodle username');
    }
    
    final password = moodleUsers[username]!;
    final url = Uri.parse('$moodleBaseUrl/login/token.php');
    
    try {
      final response = await http.get(url.replace(queryParameters: {
        'username': username,
        'password': password,
        'service': moodleService,
      }));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          _moodleToken = data['token'];
          return true;
        } else {
          throw Exception('Authentication failed: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Moodle authentication error: $e');
      return false;
    }
  }

  // ============ GOOGLE CLASSROOM INTEGRATION ============

  /// Get courses from Google Classroom - COMPLETE IMPLEMENTATION
  Future<List<Course>> getClassroomCourses() async {
    print('📚 Getting Google Classroom courses...');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      print('❌ No valid token available for course loading');
      throw Exception('Not authenticated with Google Classroom');
    }

    print('✅ Valid token available for course loading (${token.length} chars)');

    // ✅ ENHANCED: Try different course loading approaches
    final urls = [
      '$classroomBaseUrl/courses?courseStates=ACTIVE&pageSize=50',
      '$classroomBaseUrl/courses?pageSize=50',
      '$classroomBaseUrl/courses',
    ];

    for (int attempt = 0; attempt < urls.length; attempt++) {
      final url = Uri.parse(urls[attempt]);
      print('🌐 Attempt ${attempt + 1}: Making API call to: $url');
      
      try {
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('📊 Response status: ${response.statusCode}');
        
        if (response.body.isNotEmpty) {
          print('📄 Response body preview: ${response.body.substring(0, math.min(200, response.body.length))}...');
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> courses = data['courses'] ?? [];
          
          print('✅ Successfully retrieved ${courses.length} courses');
          
          if (courses.isEmpty) {
            print('⚠️ No courses returned from Google Classroom');
            print('📋 Full response: ${response.body}');
            
            // Try to get more details about why no courses
            if (data.containsKey('nextPageToken')) {
              print('📄 Response has pagination token: ${data['nextPageToken']}');
            }
            
            continue; // Try next URL
          }
          
          // Log course details
          for (int i = 0; i < courses.length; i++) {
            final course = courses[i];
            print('📚 Course $i: ${course['name']} (ID: ${course['id']})');
            print('   State: ${course['courseState']}');
            print('   Owner: ${course['ownerId']}');
            print('   Room: ${course['room'] ?? 'N/A'}');
          }
          
          final courseList = courses.map((courseJson) {
            try {
              return Course(
                id: courseJson['id'].toString(),
                name: courseJson['name'] ?? 'Unknown Course',
                description: courseJson['description'] ?? courseJson['descriptionHeading'] ?? '',
                instructor: courseJson['ownerId'] ?? 'Google Classroom Instructor',
                createdAt: DateTime.now(), // Google Classroom doesn't provide creation time in course list
                assignmentIds: [],
              );
            } catch (e) {
              print('⚠️ Error parsing course: $e');
              print('📄 Course data: $courseJson');
              
              // Return a basic course object even if parsing fails
              return Course(
                id: courseJson['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
                name: courseJson['name']?.toString() ?? 'Unknown Course',
                description: 'Course parsing error: $e',
                instructor: 'Unknown Instructor',
                createdAt: DateTime.now(),
                assignmentIds: [],
              );
            }
          }).toList();
          
          print('✅ Successfully parsed ${courseList.length} courses');
          return courseList;
          
        } else if (response.statusCode == 401) {
          print('❌ 401 Unauthorized - clearing tokens and requiring re-auth');
          await SimpleGoogleAuth.signOut();
          throw Exception('Authentication expired. Please sign in again.');
        } else if (response.statusCode == 403) {
          print('❌ 403 Forbidden - checking permissions');
          final errorBody = response.body;
          print('📄 Error response: $errorBody');
          
          if (errorBody.contains('Request had insufficient authentication scopes')) {
            throw Exception('Insufficient permissions. Please sign out and sign in again with full permissions.');
          } else {
            print('⚠️ 403 error, trying next URL...');
            continue; // Try next URL
          }
        } else {
          print('❌ API Error: ${response.statusCode} - ${response.body}');
          if (attempt == urls.length - 1) {
            // Last attempt failed
            throw Exception('Failed to load courses: HTTP ${response.statusCode}');
          }
          continue; // Try next URL
        }
      } catch (e) {
        print('❌ Error on attempt ${attempt + 1}: $e');
        if (attempt == urls.length - 1) {
          // Last attempt failed
          rethrow;
        }
        continue; // Try next URL
      }
    }
    
    // If we get here, all attempts failed
    throw Exception('Failed to load courses after ${urls.length} attempts');
  }

  /// Get assignments for a Google Classroom course - COMPLETE IMPLEMENTATION
  Future<List<Assignment>> getClassroomAssignments(String courseId) async {
    print('📝 Getting assignments for course: $courseId');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      throw Exception('Not authenticated with Google Classroom');
    }

    final url = Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Assignments response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> courseWork = data['courseWork'] ?? [];
        
        print('✅ Found ${courseWork.length} assignments');
        
        return courseWork.map((workJson) => Assignment(
          id: workJson['id'].toString(),
          name: workJson['title'] ?? 'Unknown Assignment',
          description: workJson['description'] ?? '',
          language: 'text',
          courseId: courseId,
          timeoutSeconds: 30,
          maxScore: workJson['maxPoints']?.toDouble()?.toInt() ?? 100,
          testCases: [],
          createdAt: DateTime.parse(workJson['creationTime'] ?? DateTime.now().toIso8601String()),
          createdBy: 'classroom',
          testFiles: {},
        )).toList();
      } else if (response.statusCode == 401) {
        await SimpleGoogleAuth.signOut();
        throw Exception('Authentication expired. Please sign in again.');
      } else {
        throw Exception('Failed to load assignments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading assignments: $e');
      rethrow;
    }
  }

  /// Get submissions for a Google Classroom assignment - COMPLETE IMPLEMENTATION
  Future<List<StudentSubmission>> getClassroomSubmissions(String courseId, String assignmentId) async {
    print('📤 Getting submissions for assignment: $assignmentId');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      throw Exception('Not authenticated with Google Classroom');
    }

    final url = Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId/studentSubmissions');
    
    print('🌐 Making submissions API call to: $url');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Submissions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> submissions = data['studentSubmissions'] ?? [];
        
        print('✅ Found ${submissions.length} submissions');
        
        List<StudentSubmission> result = [];
        
        for (var submissionJson in submissions) {
          final attachments = submissionJson['assignmentSubmission']?['attachments'] ?? [];
          String filename = 'submission';
          String fileId = '';
          
          if (attachments.isNotEmpty) {
            final driveFile = attachments[0]['driveFile'];
            if (driveFile != null) {
              filename = driveFile['title'] ?? 'submission';
              fileId = driveFile['id'] ?? '';
            }
          }
          
          result.add(StudentSubmission(
            id: submissionJson['id'].toString(),
            studentId: submissionJson['userId'].toString(),
            studentName: 'Student ${submissionJson['userId']}',
            filename: filename,
            code: fileId.isNotEmpty ? 'DRIVE_FILE:$fileId' : 'No file attached',
            assignmentId: assignmentId,
            submittedAt: DateTime.parse(
              submissionJson['updateTime'] ?? DateTime.now().toIso8601String(),
            ),
            status: submissionJson['state'] ?? 'CREATED',
            fileSize: 0,
            fileExtension: filename.split('.').last,
            gradeId: null,
          ));
        }
        
        return result;
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized in submissions');
        await SimpleGoogleAuth.signOut();
        throw Exception('Authentication expired. Please sign in again.');
      } else {
        throw Exception('Failed to load submissions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading submissions: $e');
      rethrow;
    }
  }

  /// Download file from Google Drive - COMPLETE IMPLEMENTATION
  Future<String> downloadGoogleDriveFile(String fileId) async {
    print('📁 Downloading Google Drive file: $fileId');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      throw Exception('Not authenticated with Google');
    }

    try {
      // Try export first (for Google Docs)
      var response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId/export?mimeType=text/plain'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ File exported as text successfully');
        return response.body;
      }

      // Try direct download
      response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ File downloaded directly');
        return response.body;
      }

      throw Exception('Could not download file: HTTP ${response.statusCode}');

    } catch (e) {
      print('❌ Error downloading file: $e');
      return 'Error loading file: $e\nFile ID: $fileId';
    }
  }

  /// Create assignment in Google Classroom - COMPLETE IMPLEMENTATION
  Future<Assignment> createGoogleClassroomAssignment({
    required String courseId,
    required String title,
    required String description,
    double maxPoints = 100,
    DateTime? dueDate,
  }) async {
    print('📝 Creating Google Classroom assignment via API...');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      throw Exception('Not authenticated with Google Classroom');
    }

    final url = Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork');
    
    final assignmentData = {
      'title': title,
      'description': description,
      'workType': 'ASSIGNMENT',
      'state': 'PUBLISHED',
      'maxPoints': maxPoints,
    };

    if (dueDate != null) {
      assignmentData['dueDate'] = {
        'year': dueDate.year,
        'month': dueDate.month,
        'day': dueDate.day,
      };
      assignmentData['dueTime'] = {
        'hours': 23,
        'minutes': 59,
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(assignmentData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Assignment created successfully!');
        
        return Assignment(
          id: data['id'].toString(),
          name: data['title'] ?? title,
          description: data['description'] ?? description,
          language: 'text',
          courseId: courseId,
          maxScore: (data['maxPoints'] ?? maxPoints).toInt(),
          testCases: [],
          createdAt: DateTime.parse(data['creationTime'] ?? DateTime.now().toIso8601String()),
          createdBy: 'api',
        );
      } else {
        throw Exception('Failed to create assignment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating assignment: $e');
      rethrow;
    }
  }

  // ============ ENHANCED GOOGLE CLASSROOM GRADING ============

  /// Submit grade to Google Classroom - ENHANCED VERSION
  /// This works for ANY assignment, regardless of how it was created
  Future<bool> submitGradeToClassroom({
    required String courseId,
    required String assignmentId,
    required String submissionId,
    required String studentId,
    required double grade,
    required String feedback,
  }) async {
    print('🎓 Submitting grade to Google Classroom (Enhanced)...');
    print('   Course: $courseId');
    print('   Assignment: $assignmentId');
    print('   Submission: $submissionId');
    print('   Grade: $grade');

    final token = await _getValidGoogleToken();
    if (token == null) {
      throw Exception('Not authenticated with Google Classroom');
    }

    try {
      // ✅ STEP 1: Get assignment details to understand point scale
      print('📋 Step 1: Getting assignment details...');
      final assignmentDetails = await _getAssignmentDetails(courseId, assignmentId, token);
      if (assignmentDetails == null) {
        throw Exception('Could not retrieve assignment details');
      }

      final maxPoints = assignmentDetails['maxPoints'] as num?;
      print('📊 Assignment max points: $maxPoints');

      // ✅ STEP 2: Determine the correct grade format
      double finalGrade;
      if (maxPoints != null && maxPoints > 0) {
        // Assignment has points - use the grade as-is if it's within range
        if (grade <= maxPoints) {
          finalGrade = grade;
        } else {
          // Grade is a percentage, convert to points
          finalGrade = (grade / 100) * maxPoints.toDouble();
        }
      } else {
        // No max points defined, treat as percentage (0-100)
        finalGrade = grade > 1 ? grade : grade * 100;
      }

      print('📈 Final grade to submit: $finalGrade');

      // ✅ STEP 3: Get current submission state
      print('📋 Step 2: Getting current submission state...');
      final currentSubmission = await _getSubmissionDetails(courseId, assignmentId, submissionId, token);
      if (currentSubmission == null) {
        throw Exception('Could not retrieve submission details');
      }

      print('📊 Current submission state: ${currentSubmission['state']}');

      // ✅ STEP 4: Prepare the grade update request
      final url = Uri.parse(
        '$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId/studentSubmissions/$submissionId'
      ).replace(queryParameters: {
        'updateMask': 'assignedGrade,draftGrade', // Update both grades
      });

      final gradeData = {
        'assignedGrade': finalGrade,
        'draftGrade': finalGrade,
      };

      print('🌐 Submitting to: $url');
      print('📊 Grade data: $gradeData');

      // ✅ STEP 5: Submit the grade
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(gradeData),
      );

      print('📈 Grade submission response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Grade submitted successfully!');
        
        // ✅ STEP 6: Add feedback if provided
        if (feedback.isNotEmpty) {
          await _addFeedbackToSubmission(courseId, assignmentId, submissionId, feedback, token);
        }
        
        return true;
      } else {
        // ✅ ENHANCED ERROR HANDLING
        await _handleGradeSubmissionError(response, courseId, assignmentId, submissionId);
        return false;
      }

    } catch (e) {
      print('❌ Error submitting grade: $e');
      rethrow;
    }
  }

  /// Get assignment details including max points
  Future<Map<String, dynamic>?> _getAssignmentDetails(String courseId, String assignmentId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Failed to get assignment details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting assignment details: $e');
      return null;
    }
  }

  /// Get current submission details
  Future<Map<String, dynamic>?> _getSubmissionDetails(String courseId, String assignmentId, String submissionId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId/studentSubmissions/$submissionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Failed to get submission details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting submission details: $e');
      return null;
    }
  }

  /// Add feedback comment to submission
  Future<void> _addFeedbackToSubmission(String courseId, String assignmentId, String submissionId, String feedback, String token) async {
    try {
      print('💬 Adding feedback to submission...');
      
      final response = await http.post(
        Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId/studentSubmissions/$submissionId:modifyAttachments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'addAttachments': [
            {
              'comment': {
                'text': feedback
              }
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Feedback added successfully');
      } else {
        print('⚠️ Could not add feedback: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error adding feedback: $e');
      // Don't throw - feedback is optional
    }
  }

  /// Enhanced error handling for grade submission
  Future<void> _handleGradeSubmissionError(http.Response response, String courseId, String assignmentId, String submissionId) async {
    final statusCode = response.statusCode;
    final responseBody = response.body;
    
    print('❌ Grade submission failed with status: $statusCode');
    print('📄 Response body: $responseBody');

    try {
      final errorData = jsonDecode(responseBody);
      final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
      final errorCode = errorData['error']?['code'] ?? statusCode;
      
      switch (statusCode) {
        case 401:
          await SimpleGoogleAuth.signOut();
          throw Exception('Authentication expired. Please sign in again.');
          
        case 403:
          // ✅ IMPROVED 403 HANDLING - Don't assume it's about assignment creation
          print('🔍 Analyzing 403 error...');
          
          if (errorMessage.toLowerCase().contains('permission') && 
              errorMessage.toLowerCase().contains('denied')) {
            
            // Check if it's specifically about assignment permissions
            if (errorMessage.toLowerCase().contains('coursework') || 
                errorMessage.toLowerCase().contains('assignment')) {
              throw Exception('''
🔒 Insufficient Permissions for Assignment Grading

This could be due to:
1. Missing required OAuth scopes
2. Assignment settings that restrict grading
3. Course permissions that limit teacher access

Suggested solutions:
• Sign out and sign in again with full permissions
• Ensure you have teacher access to this course
• Check if the assignment allows grading modifications
• Contact your administrator if the issue persists

Technical details: $errorMessage
''');
            } else {
              // General permission error
              throw Exception('''
🔒 Permission Error

Error: $errorMessage

Possible solutions:
• Check your permissions for this course
• Ensure you're authenticated as a teacher
• Verify the submission exists and is accessible
• Try refreshing your authentication
''');
            }
          } else {
            throw Exception('Permission denied: $errorMessage');
          }
          
        case 404:
          throw Exception('''
❌ Resource Not Found

One of the following was not found:
• Course ID: $courseId
• Assignment ID: $assignmentId  
• Submission ID: $submissionId

Please verify these IDs are correct and the resources exist.
''');
          
        case 400:
          throw Exception('''
❌ Bad Request

The grade submission request was invalid:
$errorMessage

This could be due to:
• Invalid grade value
• Incorrect request format
• Missing required fields
''');
          
        case 409:
          throw Exception('''
⚠️ Conflict

The submission state conflicts with the grading request:
$errorMessage

This might happen if:
• The submission is already returned
• The assignment is archived
• There's a concurrent modification
''');
          
        default:
          throw Exception('Failed to submit grade: HTTP $statusCode - $errorMessage');
      }
      
    } catch (FormatException) {
      // Response is not JSON
      throw Exception('Failed to submit grade: HTTP $statusCode - $responseBody');
    }
  }

  // ============ DIAGNOSTIC METHODS ============

  /// Enhanced token validation specifically for course access
  Future<bool> validateTokenForCourseAccess() async {
    print('🔍 Validating token for course access...');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      print('❌ No token available');
      return false;
    }

    try {
      // Test basic classroom access
      final response = await http.get(
        Uri.parse('https://classroom.googleapis.com/v1/courses?pageSize=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('🔍 Token validation response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Token is valid for course access');
        return true;
      } else {
        print('❌ Token validation failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  /// Get detailed information about current authentication status
  Future<Map<String, dynamic>> getDetailedAuthStatus() async {
    print('🔍 Getting detailed authentication status...');
    
    final token = await _getValidGoogleToken();
    final basicStatus = await getAuthenticationStatus();
    
    Map<String, dynamic> detailedStatus = {
      ...basicStatus,
      'tokenPreview': token?.substring(0, math.min(30, token?.length ?? 0)),
      'tokenValidForCourses': false,
      'tokenScopes': <String>[],
      'apiAccessible': false,
    };

    if (token != null) {
      // Test API accessibility
      try {
        final apiResponse = await http.get(
          Uri.parse('https://classroom.googleapis.com/v1/courses?pageSize=1'),
          headers: {'Authorization': 'Bearer $token'},
        );
        detailedStatus['apiAccessible'] = apiResponse.statusCode == 200;
        detailedStatus['apiResponseCode'] = apiResponse.statusCode;
      } catch (e) {
        detailedStatus['apiError'] = e.toString();
      }

      // Get token scopes
      try {
        final tokenInfoResponse = await http.get(
          Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$token'),
        );
        
        if (tokenInfoResponse.statusCode == 200) {
          final tokenInfo = jsonDecode(tokenInfoResponse.body);
          final scopes = tokenInfo['scope']?.toString().split(' ') ?? <String>[];
          detailedStatus['tokenScopes'] = scopes;
          detailedStatus['tokenValidForCourses'] = scopes.any((scope) => scope.contains('classroom'));
        }
      } catch (e) {
        detailedStatus['tokenScopeError'] = e.toString();
      }
    }

    print('📊 Detailed status: $detailedStatus');
    return detailedStatus;
  }

  /// Debug course loading issues comprehensively
  Future<void> debugCourseLoadingIssues() async {
    print('🔍 === COMPREHENSIVE COURSE LOADING DEBUG ===');
    
    try {
      // 1. Check basic authentication
      print('🔐 Step 1: Checking authentication...');
      final authStatus = await getDetailedAuthStatus();
      print('   Platform: ${authStatus['platform']}');
      print('   Google Authenticated: ${authStatus['googleAuthenticated']}');
      print('   Token Valid: ${authStatus['googleTokenValid']}');
      print('   API Accessible: ${authStatus['apiAccessible']}');
      print('   Token Scopes: ${authStatus['tokenScopes']}');

      // 2. Test token validation
      print('🔍 Step 2: Validating token for course access...');
      final tokenValid = await validateTokenForCourseAccess();
      print('   Token valid for courses: $tokenValid');

      // 3. Try to load courses with full debugging
      print('📚 Step 3: Attempting to load courses...');
      try {
        final courses = await getClassroomCourses();
        print('   ✅ Successfully loaded ${courses.length} courses');
        
        for (int i = 0; i < math.min(courses.length, 5); i++) {
          final course = courses[i];
          print('   📚 Course $i: ${course.name} (${course.id})');
        }
      } catch (e) {
        print('   ❌ Course loading failed: $e');
      }

      // 4. Test direct API call
      print('🌐 Step 4: Testing direct API call...');
      final token = await _getValidGoogleToken();
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('https://classroom.googleapis.com/v1/courses'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          print('   Direct API response: ${response.statusCode}');
          print('   Response body length: ${response.body.length}');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('   Courses in response: ${data['courses']?.length ?? 0}');
          }
        } catch (e) {
          print('   Direct API error: $e');
        }
      }

    } catch (e) {
      print('❌ Debug error: $e');
    }
    
    print('🔍 === END COMPREHENSIVE DEBUG ===');
  }

  /// Test if we can grade a specific assignment (diagnostic function)
  Future<Map<String, dynamic>> testAssignmentGradingCapability({
    required String courseId,
    required String assignmentId,
  }) async {
    print('🧪 Testing grading capability for assignment...');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      return {
        'canGrade': false,
        'error': 'Not authenticated',
        'details': 'No valid authentication token available'
      };
    }

    try {
      // Get assignment details
      final assignmentDetails = await _getAssignmentDetails(courseId, assignmentId, token);
      if (assignmentDetails == null) {
        return {
          'canGrade': false,
          'error': 'Cannot access assignment',
          'details': 'Failed to retrieve assignment details'
        };
      }

      // Get submissions to test access
      final response = await http.get(
        Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId/studentSubmissions?pageSize=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final submissions = data['studentSubmissions'] as List?;
        
        return {
          'canGrade': true,
          'assignmentTitle': assignmentDetails['title'],
          'maxPoints': assignmentDetails['maxPoints'],
          'submissionCount': submissions?.length ?? 0,
          'details': 'Assignment is accessible and gradable'
        };
      } else {
        return {
          'canGrade': false,
          'error': 'Cannot access submissions',
          'details': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }

    } catch (e) {
      return {
        'canGrade': false,
        'error': 'Test failed',
        'details': e.toString()
      };
    }
  }

  /// Enhanced debug method for assignment grading issues
  Future<void> debugAssignmentGradingIssues({
    required String courseId,
    required String assignmentId,
    String? submissionId,
  }) async {
    print('🔍 === ASSIGNMENT GRADING DEBUG ===');
    
    final token = await _getValidGoogleToken();
    if (token == null) {
      print('❌ No authentication token available');
      return;
    }

    try {
      // 1. Test basic authentication
      print('🔐 Testing authentication...');
      final authTest = await http.get(
        Uri.parse('https://classroom.googleapis.com/v1/courses?pageSize=1'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('   Auth test result: ${authTest.statusCode}');

      // 2. Check assignment details
      print('📋 Getting assignment details...');
      final assignmentDetails = await _getAssignmentDetails(courseId, assignmentId, token);
      if (assignmentDetails != null) {
        print('   ✅ Assignment accessible');
        print('   Title: ${assignmentDetails['title']}');
        print('   Max Points: ${assignmentDetails['maxPoints']}');
        print('   State: ${assignmentDetails['state']}');
        print('   Work Type: ${assignmentDetails['workType']}');
      } else {
        print('   ❌ Cannot access assignment');
      }

      // 3. Check submissions access
      print('📤 Testing submissions access...');
      final submissionsResponse = await http.get(
        Uri.parse('$classroomBaseUrl/courses/$courseId/courseWork/$assignmentId/studentSubmissions?pageSize=5'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('   Submissions access: ${submissionsResponse.statusCode}');
      
      if (submissionsResponse.statusCode == 200) {
        final submissionsData = jsonDecode(submissionsResponse.body);
        final submissions = submissionsData['studentSubmissions'] as List?;
        print('   Found ${submissions?.length ?? 0} submissions');
      }

      // 4. Test specific submission if provided
      if (submissionId != null) {
        print('🎯 Testing specific submission: $submissionId');
        final submissionDetails = await _getSubmissionDetails(courseId, assignmentId, submissionId, token);
        if (submissionDetails != null) {
          print('   ✅ Submission accessible');
          print('   State: ${submissionDetails['state']}');
          print('   User ID: ${submissionDetails['userId']}');
          print('   Current Grade: ${submissionDetails['assignedGrade']}');
        } else {
          print('   ❌ Cannot access submission');
        }
      }

      // 5. Check token scopes
      print('🔍 Checking token scopes...');
      await _checkTokenScopes(token);

    } catch (e) {
      print('❌ Debug error: $e');
    }
    
    print('🔍 === END DEBUG ===');
  }

  /// Check what scopes the current token has
  Future<void> _checkTokenScopes(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$token'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenScopes = data['scope'].toString();
        
        print('📋 Current token scopes:');
        final scopes = tokenScopes.split(' ');
        for (final scope in scopes) {
          print('   • $scope');
        }
        
        // Check critical scopes for grading
        final requiredScopes = [
          'classroom.coursework.students',
          'classroom.coursework.me',
          'classroom.courses',
          'classroom.student-submissions',
        ];
        
        print('📊 Required scopes for grading:');
        for (final required in requiredScopes) {
          final hasScope = tokenScopes.contains(required);
          print('   ${hasScope ? "✅" : "❌"} $required');
        }
      }
    } catch (e) {
      print('⚠️ Could not check token scopes: $e');
    }
  }

  // ============ MOODLE METHODS (placeholders for now) ============
  
  Future<List<Course>> getMoodleCourses() async => [];
  Future<List<Assignment>> getMoodleAssignments(String courseId) async => [];
  Future<List<StudentSubmission>> getMoodleSubmissions(String assignmentId) async => [];

  // ============ UNIFIED INTERFACE ============
  
  Future<List<Course>> getCourses() async {
    print('📚 getCourses() called for platform: $_currentPlatform');
    
    try {
      if (_currentPlatform == 'moodle') {
        print('📚 Loading Moodle courses...');
        return await getMoodleCourses();
      } else if (_currentPlatform == 'classroom') {
        print('📚 Loading Google Classroom courses...');
        
        // ✅ ENHANCED: Add token validation before loading courses
        final tokenValid = await validateTokenForCourseAccess();
        if (!tokenValid) {
          throw Exception('Invalid authentication token. Please sign out and sign in again.');
        }
        
        return await getClassroomCourses();
      } else {
        throw Exception('Invalid platform: $_currentPlatform');
      }
    } catch (e) {
      print('❌ getCourses() error: $e');
      rethrow;
    }
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    if (_currentPlatform == 'moodle') {
      return await getMoodleAssignments(courseId);
    } else if (_currentPlatform == 'classroom') {
      return await getClassroomAssignments(courseId);
    } else {
      throw Exception('Invalid platform: $_currentPlatform');
    }
  }

  Future<List<StudentSubmission>> getSubmissions(String courseId, String assignmentId) async {
    if (_currentPlatform == 'moodle') {
      return await getMoodleSubmissions(assignmentId);
    } else if (_currentPlatform == 'classroom') {
      return await getClassroomSubmissions(courseId, assignmentId);
    } else {
      throw Exception('Invalid platform: $_currentPlatform');
    }
  }

  void clearAuthentication() {
    print('🧹 Clearing authentication...');
    _moodleToken = null;
    print('✅ Authentication cleared');
  }

  Future<Map<String, dynamic>> getAuthenticationStatus() async {
    final googleStatus = await SimpleGoogleAuth.getAuthStatus();
    
    return {
      'platform': _currentPlatform,
      'moodleAuthenticated': _moodleToken != null,
      'googleAuthenticated': googleStatus['hasToken'],
      'googleTokenLength': googleStatus['tokenLength'],
      'googleTokenValid': googleStatus['isValid'],
      'googleTokenExpiry': googleStatus['expiry'],
    };
  }

  Future<void> debugTokenAndRequest({
    required String courseId,
    required String assignmentId,
    required String submissionId,
  }) async {
    await debugAssignmentGradingIssues(
      courseId: courseId,
      assignmentId: assignmentId,
      submissionId: submissionId,
    );
  }
}