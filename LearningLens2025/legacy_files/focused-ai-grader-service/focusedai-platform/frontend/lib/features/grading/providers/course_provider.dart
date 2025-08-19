// lib/core/providers/course_provider.dart
import 'package:flutter/foundation.dart';
import '../../../core/models/assignment.dart';
import '../../../core/models/course.dart';
import '../../../core/services/api_service.dart';

class CourseProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Course> _courses = [];
  Course? _selectedCourse;
  Assignment? _selectedAssignment;
  bool _isLoading = false;
  String? _error;

  CourseProvider({
    String? backendUrl,
    Map<String, String>? authHeaders,
  }) : _apiService = ApiService(
          baseUrl: backendUrl,
          authHeaders: authHeaders,
        );

  // Getters
  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  Assignment? get selectedAssignment => _selectedAssignment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasCourses => _courses.isNotEmpty;
  bool get hasSelectedCourse => _selectedCourse != null;
  bool get hasSelectedAssignment => _selectedAssignment != null;

  // Set courses from parent application
  void setCourses(List<Course> courses) {
    _courses = courses;
    _clearError();
    notifyListeners();
  }

  // Load courses from API
  Future<void> loadCourses({String? platform}) async {
    _setLoading(true);
    _clearError();

    try {
      // Use the get method directly since your ApiService uses generic HTTP methods
      final coursesData = await _apiService.get('/api/courses${platform != null ? '?platform=$platform' : ''}');
      
      // Handle both List and wrapped response formats
      List<dynamic> coursesList;
      if (coursesData is List) {
        coursesList = coursesData;
      } else if (coursesData is Map<String, dynamic>) {
        coursesList = coursesData['data'] ?? coursesData['courses'] ?? [];
      } else {
        throw Exception('Unexpected response format for courses');
      }
      
      _courses = coursesList.map((data) => Course.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load courses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Select a course
  Future<void> selectCourse(String courseId) async {
    _clearError();
    
    try {
      // First check if course exists in current list
      Course? existingCourse;
      try {
        existingCourse = _courses.firstWhere((course) => course.id == courseId);
      } catch (e) {
        existingCourse = null;
      }
      
      if (existingCourse != null) {
        _selectedCourse = existingCourse;
        _selectedAssignment = null; // Clear assignment when course changes
        notifyListeners();
        return;
      }
      
      // If not found, try to load from API
      _setLoading(true);
      try {
        final courseData = await _apiService.get('/api/courses/$courseId');
        
        // Handle wrapped response
        Map<String, dynamic> courseMap;
        if (courseData is Map<String, dynamic>) {
          courseMap = courseData['data'] ?? courseData;
        } else {
          throw Exception('Unexpected response format for course');
        }
        
        _selectedCourse = Course.fromJson(courseMap);
        _selectedAssignment = null;
        notifyListeners();
      } catch (apiError) {
        // If course not found in API, create fallback
        _selectedCourse = _createFallbackCourse(courseId);
        _selectedAssignment = null;
        notifyListeners();
      }
      
    } catch (e) {
      _setError('Failed to load course: $e');
      // Create fallback course if all else fails
      _selectedCourse = _createFallbackCourse(courseId);
      _selectedAssignment = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Select an assignment
  void selectAssignment(String assignmentId) {
    if (_selectedCourse == null) {
      _setError('Please select a course first');
      return;
    }

    try {
      final assignment = _selectedCourse!.assignments.firstWhere(
        (a) => a.id == assignmentId,
      );
      _selectedAssignment = assignment;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Assignment not found: $assignmentId');
    }
  }

  // Get assignment by ID from all courses
  Assignment? getAssignmentById(String assignmentId) {
    for (final course in _courses) {
      try {
        return course.assignments.firstWhere((a) => a.id == assignmentId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Get course by assignment ID
  Course? getCourseByAssignmentId(String assignmentId) {
    for (final course in _courses) {
      final hasAssignment = course.assignments.any((a) => a.id == assignmentId);
      if (hasAssignment) {
        return course;
      }
    }
    return null;
  }

  // Select assignment with course context
  Future<void> selectAssignmentWithCourseContext(String assignmentId) async {
    final course = getCourseByAssignmentId(assignmentId);
    if (course != null) {
      await selectCourse(course.id);
    }
    
    final assignment = getAssignmentById(assignmentId);
    if (assignment != null) {
      _selectedAssignment = assignment;
      notifyListeners();
    }
  }

  // Get all assignments across all courses
  List<Assignment> get allAssignments {
    final List<Assignment> assignments = [];
    for (final course in _courses) {
      assignments.addAll(course.assignments);
    }
    return assignments;
  }

  // Create fallback course when API fails
  Course _createFallbackCourse(String courseId) {
    return Course(
      id: courseId,
      name: 'Programming Course',
      description: 'Computer Science programming course with automated grading',
      platform: 'default',
      instructor: 'Course Instructor',
      enrollmentCount: 25,
      createdAt: DateTime.now(),
      assignments: _createFallbackAssignments(courseId),
    );
  }

  // Create fallback assignments
  List<Assignment> _createFallbackAssignments(String courseId) {
    return [
      Assignment(
        id: 'hello-world-$courseId',
        courseId: courseId,
        name: 'Hello World Program',
        description: 'Write a simple Hello World program in Java that prints "Hello, World!" to the console.',
        language: 'java',
        maxScore: 100.0,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 3)),
        testCases: const [],
        submissions: const [],
      ),
      Assignment(
        id: 'calculator-$courseId',
        courseId: courseId,
        name: 'Simple Calculator',
        description: 'Create a calculator program that reads two integers and performs addition and subtraction.',
        language: 'java',
        maxScore: 150.0,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        testCases: const [],
        submissions: const [],
      ),
      Assignment(
        id: 'array-ops-$courseId',
        courseId: courseId,
        name: 'Array Operations',
        description: 'Implement various array manipulation methods including sorting and searching.',
        language: 'java',
        maxScore: 200.0,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        testCases: const [],
        submissions: const [],
      ),
    ];
  }

  // Refresh selected course
  Future<void> refreshSelectedCourse() async {
    if (_selectedCourse != null) {
      await selectCourse(_selectedCourse!.id);
    }
  }

  // Clear selection
  void clearSelection() {
    _selectedCourse = null;
    _selectedAssignment = null;
    _clearError();
    notifyListeners();
  }

  // Reset provider
  void reset() {
    _courses = [];
    _selectedCourse = null;
    _selectedAssignment = null;
    _isLoading = false;
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _courses = [];
    _selectedCourse = null;
    _selectedAssignment = null;
    super.dispose();
  }
}