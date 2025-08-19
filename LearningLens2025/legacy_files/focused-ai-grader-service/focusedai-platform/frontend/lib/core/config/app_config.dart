// lib/core/config/app_config.dart - Updated with helper methods
import 'package:flutter/material.dart';

class AppConfig {
  // API Configuration
  static const String defaultBackendUrl = 'http://localhost:8080';
  static const String apiVersion = '/api';
  static const String appName = 'Code Grading Interface';
  static const String version = '2.0.0';

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 4);
  static const int defaultPageSize = 20;

  // Grading Configuration
  static const Map<String, double> gradeScale = {
    'A': 90.0,
    'B': 80.0,
    'C': 70.0,
    'D': 60.0,
    'F': 0.0,
  };

  // Language Configuration
  static const Map<String, String> supportedLanguages = {
    'java': 'Java',
    'python': 'Python',
    'javascript': 'JavaScript',
    'cpp': 'C++',
    'c': 'C',
    'csharp': 'C#',
    'go': 'Go',
    'rust': 'Rust',
    'kotlin': 'Kotlin',
    'swift': 'Swift',
  };

  // Platform Configuration
  static const Map<String, String> supportedPlatforms = {
    'moodle': 'Moodle',
    'google': 'Google Classroom',
    'canvas': 'Canvas',
    'blackboard': 'Blackboard',
  };

  // File Configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedCodeExtensions = [
    'java', 'py', 'js', 'cpp', 'c', 'h', 'cs', 'go', 'rs', 'kt', 'swift'
  ];
  static const List<String> allowedTestFileExtensions = ['txt', 'in', 'out'];

  // Execution Configuration
  static const int executionTimeoutSeconds = 60;
  static const int maxOutputLength = 50000; // characters
  static const int maxExecutionsPerMinute = 30;
  static const int defaultTimeoutMs = 60000; // 60 seconds in milliseconds
  static const int defaultMaxMemoryMb = 512; // 512 MB default memory limit

  // Helper methods
  static Duration getAnimationDuration() => animationDuration;
  static Duration getSnackbarDuration() => snackbarDuration;
  static int getDefaultTimeoutMs() => defaultTimeoutMs;
  static int getDefaultMaxMemoryMb() => defaultMaxMemoryMb;

  // Grade calculation methods
  static String calculateLetterGrade(double percentage) {
    if (percentage >= gradeScale['A']!) return 'A';
    if (percentage >= gradeScale['B']!) return 'B';
    if (percentage >= gradeScale['C']!) return 'C';
    if (percentage >= gradeScale['D']!) return 'D';
    return 'F';
  }

  static bool isPassingGrade(double percentage) {
    return percentage >= gradeScale['D']!;
  }

  static Color getGradeColor(String letterGrade) {
    switch (letterGrade.toUpperCase()) {
      case 'A':
        return const Color(0xFF4CAF50); // Green
      case 'B':
        return const Color(0xFF8BC34A); // Light Green
      case 'C':
        return const Color(0xFFFFEB3B); // Yellow
      case 'D':
        return const Color(0xFFFF9800); // Orange
      case 'F':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  // Language detection and support
  static String detectLanguageFromExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'java':
        return 'java';
      case 'py':
        return 'python';
      case 'js':
        return 'javascript';
      case 'cpp':
      case 'cc':
      case 'cxx':
        return 'cpp';
      case 'c':
        return 'c';
      case 'cs':
        return 'csharp';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'kt':
        return 'kotlin';
      case 'swift':
        return 'swift';
      default:
        return 'unknown';
    }
  }

  // Check if a language is supported
  static bool isLanguageSupported(String language) {
    return supportedLanguages.containsKey(language.toLowerCase());
  }

  // File validation
  static bool isValidCodeFile(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedCodeExtensions.contains(extension);
  }

  static bool isValidTestFile(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return allowedTestFileExtensions.contains(extension);
  }

  static List<String> getSupportedLanguages() {
    return supportedLanguages.keys.toList();
  }

  // Platform helpers
  static String getPlatformDisplayName(String platform) {
    return supportedPlatforms[platform.toLowerCase()] ?? platform;
  }

  static String getLanguageDisplayName(String language) {
    return supportedLanguages[language.toLowerCase()] ?? language;
  }

  // Theme helpers
  static Color getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
      case 'classroom':
        return const Color(0xFF4285F4); // Google Blue
      case 'moodle':
        return const Color(0xFFFF8800); // Moodle Orange
      case 'canvas':
        return const Color(0xFFE13C2B); // Canvas Red
      case 'blackboard':
        return const Color(0xFF000000); // Blackboard Black
      default:
        return const Color(0xFF666666); // Default Grey
    }
  }

  static Color getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return const Color(0xFFED8B00);
      case 'python':
        return const Color(0xFF3776AB);
      case 'javascript':
      case 'js':
        return const Color(0xFFF7DF1E);
      case 'cpp':
      case 'c++':
        return const Color(0xFF00599C);
      case 'c':
        return const Color(0xFFA8B9CC);
      case 'csharp':
      case 'c#':
        return const Color(0xFF239120);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'rust':
        return const Color(0xFF000000);
      case 'kotlin':
        return const Color(0xFF7F52FF);
      case 'swift':
        return const Color(0xFFFA7343);
      default:
        return const Color(0xFF666666);
    }
  }

  // Error messages
  static const Map<String, String> errorMessages = {
    'network': 'Network error. Please check your internet connection.',
    'authentication': 'Authentication failed. Please login again.',
    'authorization': 'You are not authorized to perform this action.',
    'fileUpload': 'File upload failed. Please try again.',
    'execution': 'Code execution failed. Please check your code.',
    'grading': 'Grading failed. Please try again.',
    'invalidFile': 'Invalid file format or size.',
    'timeout': 'Request timed out. Please try again.',
  };

  static String getErrorMessage(String errorType) {
    return errorMessages[errorType] ?? 'An unknown error occurred.';
  }

  // Success messages
  static const Map<String, String> successMessages = {
    'fileUploaded': 'File uploaded successfully!',
    'codeExecuted': 'Code executed successfully!',
    'submissionGraded': 'Submission graded successfully!',
    'testPassed': 'All tests passed!',
    'batchCompleted': 'Batch operation completed successfully!',
  };

  static String getSuccessMessage(String successType) {
    return successMessages[successType] ?? 'Operation completed successfully!';
  }
}