# FocusedAI Teacher - Code Grading Interface

A Flutter web application for intelligent code grading that integrates with Learning Management Systems (LMS) like Google Classroom and Moodle. This frontend provides a comprehensive interface for teachers to grade programming assignments with automated code execution and testing.

## 🎯 Overview

FocusedAI Teacher Frontend is a Flutter-based grading interface that enables educators to:
- Import and manage programming assignments from various LMS platforms
- Upload test files for automated code evaluation
- Execute student code with real-time feedback
- Grade submissions individually or in batches
- Export grading results and upload back to LMS platforms
- Support multiple programming languages (Java, Python, JavaScript, C++)

## 🏗 Current Architecture

### Core Components

**State Management (Provider Pattern)**
- `CourseProvider`: Manages course and assignment data
- `GradingProvider`: Handles submission processing and grading workflow  
- `ExecutionProvider`: Manages code execution and testing

**Code Execution & Analysis**
- Integration with backend Lambda functions for secure code execution
- Automatic strategy detection for different code patterns
- Real-time output comparison and similarity analysis
- Support for multiple execution strategies (STDIN_STDOUT, METHOD_CALL, UNIT_TEST, etc.)

**File Management**
- Test file upload system with input/output file pairing
- Multi-file code editor with syntax highlighting
- ZIP submission processing and extraction
- Assignment-specific file isolation

### Key Features

1. **Multi-Language Support**: Java, Python, JavaScript, C++
2. **Smart Code Analysis**: Automatic execution strategy detection
3. **Flexible Testing**: Upload custom input/output test files
4. **Batch Operations**: Grade multiple submissions simultaneously
5. **Export Capabilities**: Download results as CSV
6. **Platform Integration**: Ready for LMS authentication integration

## 🚀 Standalone Setup

### Prerequisites

- Flutter SDK (version 3.0+)
- Dart SDK
- Web browser (Chrome/Firefox/Safari)
- Backend server running (see backend setup)

### Quick Start

1. **Clone and setup:**
```bash
git clone <repository-url>
cd flutter_frontend
flutter pub get
```

2. **Configure backend URL:**
Update the default backend URL in your environment or use the default `localhost:8080`.

3. **Run the application:**
```bash
flutter run -d chrome --web-port 3000
```

The app will be available at `http://localhost:3000`

## 🔌 Integration as a Widget

This frontend is designed to be easily integrated into existing applications that handle authentication. Use the `CodeGradingInterface` widget for seamless integration.

### Basic Integration

```dart
import 'package:focusedai_teacher/app/app.dart';

class YourParentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Your LMS Platform')),
        body: CodeGradingInterface(
          backendUrl: 'https://your-backend.com',
          authHeaders: {
            'Authorization': 'Bearer your-jwt-token',
            'Content-Type': 'application/json',
          },
          onGradeSubmitted: (gradeData) {
            // Handle grade submission in your parent app
            print('Grade submitted: $gradeData');
          },
          onAssignmentSelected: (assignmentId) {
            // Handle assignment selection
            print('Assignment selected: $assignmentId');
          },
          onError: () {
            // Handle errors
            print('Grading interface error occurred');
          },
        ),
      ),
    );
  }
}
```

### Advanced Integration with Data

```dart
CodeGradingInterface(
  backendUrl: 'https://your-backend.com',
  authHeaders: {
    'Authorization': 'Bearer your-jwt-token',
    'X-User-ID': 'teacher-123',
    'X-Platform': 'google_classroom', // or 'moodle'
  },
  
  // Provide initial data to avoid API calls
  courses: yourCoursesList,
  assignments: yourAssignmentsList,
  submissions: yourSubmissionsList,
  
  // Handle callbacks
  onGradeSubmitted: (gradeData) {
    // Upload grades to your LMS
    uploadGradeToLMS(gradeData);
  },
  
  onCourseSelected: (courseId) {
    // Track course selection for analytics
    trackCourseSelection(courseId);
  },
  
  onAssignmentSelected: (assignmentId) {
    // Load assignment-specific data
    loadAssignmentData(assignmentId);
  },
  
  onError: () {
    // Show error notifications in your UI
    showErrorSnackbar();
  },
)
```

### Integration Examples

#### Google Classroom Integration

```dart
class GoogleClassroomIntegration extends StatefulWidget {
  @override
  _GoogleClassroomIntegrationState createState() => _GoogleClassroomIntegrationState();
}

class _GoogleClassroomIntegrationState extends State<GoogleClassroomIntegration> {
  String? accessToken;
  List<Course> courses = [];
  
  @override
  void initState() {
    super.initState();
    authenticateWithGoogle();
  }
  
  Future<void> authenticateWithGoogle() async {
    // Your Google OAuth implementation
    accessToken = await GoogleAuth.signIn();
    courses = await GoogleClassroomAPI.getCourses(accessToken);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    if (accessToken == null) {
      return LoginScreen();
    }
    
    return CodeGradingInterface(
      backendUrl: 'https://your-backend.com',
      authHeaders: {
        'Authorization': 'Bearer $accessToken',
        'X-Platform': 'google_classroom',
      },
      courses: courses,
      onGradeSubmitted: (gradeData) async {
        // Upload grade back to Google Classroom
        await GoogleClassroomAPI.updateGrade(
          accessToken!, 
          gradeData['submissionId'], 
          gradeData['result']['score'],
        );
      },
    );
  }
}
```

#### Moodle Integration

```dart
class MoodleIntegration extends StatefulWidget {
  @override
  _MoodleIntegrationState createState() => _MoodleIntegrationState();
}

class _MoodleIntegrationState extends State<MoodleIntegration> {
  String? webServiceToken;
  String? moodleDomain;
  
  @override
  Widget build(BuildContext context) {
    return CodeGradingInterface(
      backendUrl: 'https://your-backend.com',
      authHeaders: {
        'Authorization': 'Bearer your-jwt-token',
        'X-Platform': 'moodle',
        'X-Moodle-Domain': moodleDomain,
        'X-Moodle-Token': webServiceToken,
      },
      onGradeSubmitted: (gradeData) async {
        // Upload grade to Moodle
        await MoodleAPI.updateGrade(
          moodleDomain!,
          webServiceToken!,
          gradeData['submissionId'],
          gradeData['result'],
        );
      },
    );
  }
}
```

## 🎨 User Interface

### Main Grading Interface

The interface features a three-panel layout optimized for code grading:

1. **Left Sidebar (350px)**
   - Course and assignment selection
   - Submission list with status indicators
   - Grading action controls
   - Test file management

2. **Center Panel (Flexible)**
   - Multi-file code editor with syntax highlighting
   - Read-only view of student submissions
   - File tabs for multi-file projects
   - Student and assignment context indicators

3. **Right Panel (Flexible)**
   - Execution results and output
   - Grading feedback and scores
   - Error messages and debugging info
   - Execution statistics and timing

### Key UI Components

#### Test File Upload Widget
```dart
TestFileUploadWidget(
  assignmentId: selectedAssignment?.id,
  onFilesChanged: (files) {
    // Handle test file uploads
    // files contains input/output file content
  },
)
```

#### Code Editor
```dart
CodeEditor(
  files: submission.files,
  readOnly: true, // For grading interface
  onCodeChanged: (filename, content) {
    // Handle code modifications (if editing enabled)
  },
)
```

#### Grading Results Panel
- Real-time execution feedback
- Grade calculation and display
- Error reporting and debugging
- Similarity comparison results

## 📡 Backend Integration

### Expected API Endpoints

The frontend expects these backend endpoints:

```
# Course Management
GET  /api/courses                     # List courses
GET  /api/courses/{courseId}          # Get course details
GET  /api/courses/{courseId}/assignments # Get course assignments

# Assignment Operations  
GET  /api/assignments/{assignmentId}           # Get assignment
GET  /api/assignments/{assignmentId}/submissions # Get submissions

# Code Execution
POST /api/execute/{language}          # Execute single code
POST /api/execute/batch               # Batch execute
POST /api/execute/analyze             # Analyze code
GET  /api/execute/strategies          # Get execution strategies
GET  /api/execute/health              # Health check

# Grading
POST /api/grade/submission            # Grade single submission
POST /api/grade/batch                 # Batch grade
GET  /api/grade/{submissionId}        # Get existing grade
GET  /api/grading/criteria/{language} # Get grading criteria

# Test Cases
POST /api/testcases                   # Create test cases
GET  /api/testcases/{assignmentId}    # Get test cases
PUT  /api/testcases/{assignmentId}    # Update test cases
```

### Authentication Headers

The frontend sends authentication information via headers:

```dart
Map<String, String> authHeaders = {
  'Authorization': 'Bearer jwt-token',  // Required
  'X-User-ID': 'user-identifier',      // Optional
  'X-Platform': 'google_classroom',    // Optional: google_classroom, moodle
  'X-Moodle-Domain': 'moodle.url',     // For Moodle integration
  'X-Moodle-Token': 'webservice-token', // For Moodle integration
};
```

### Request/Response Models

#### Execution Request
```json
{
  "language": "java",
  "files": [
    {
      "filename": "HelloWorld.java",
      "content": "public class HelloWorld { ... }",
      "language": "java"
    }
  ],
  "testInput": "input data",
  "expectedOutput": "expected output",
  "submissionId": "submission-123",
  "timeoutMs": 60000,
  "maxMemoryMb": 512
}
```

#### Grading Response
```json
{
  "success": true,
  "gradeId": "grade-123",
  "submissionId": "submission-123",
  "score": 85.5,
  "maxScore": 100.0,
  "percentage": 85.5,
  "letterGrade": "B",
  "feedback": "Code executes correctly with minor style issues.",
  "passed": true,
  "gradingStrategy": "STDIN_STDOUT",
  "executionDetails": {
    "executionTimeMs": 1250,
    "memoryUsedMb": 64,
    "testPassed": true,
    "outputSimilarity": 100.0
  }
}
```

## ⚙️ Configuration Options

### App Configuration

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String defaultBackendUrl = 'http://localhost:8080';
  static const int defaultTimeoutMs = 60000;
  static const int defaultMaxMemoryMb = 512;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'java': 'Java',
    'python': 'Python', 
    'javascript': 'JavaScript',
    'cpp': 'C++',
  };
}
```

### Theme Customization

```dart
// lib/core/config/theme.dart
class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF4CAF50);
  
  static ThemeData lightTheme = ThemeData(
    // Custom theme configuration
  );
}
```

## 🔧 Core Features Deep Dive

### 1. Code Execution System

The frontend integrates with a backend execution service that supports multiple strategies:

- **STDIN_STDOUT**: Traditional input/output testing
- **METHOD_CALL**: Direct method invocation testing  
- **UNIT_TEST**: JUnit-style test execution
- **INTERACTIVE**: Multi-step interactive programs
- **FILE_IO**: File input/output operations

### 2. Automatic Strategy Detection

The system analyzes code to determine the best execution approach:

```dart
// Code analysis results
CodeAnalysis {
  language: 'java',
  recommendedStrategy: 'STDIN_STDOUT',
  confidence: 85.2,
  detectedFeatures: ['main_method', 'scanner_input', 'system_output'],
  hasMainMethod: true,
  isPackageExecution: false,
}
```

### 3. Test File Management

Upload and manage test files with automatic validation:

- Input files (`.txt`, `.in`) for program input
- Output files (`.txt`, `.out`) for expected results
- Automatic content validation and encoding detection
- Assignment-specific file isolation

### 4. Batch Operations

Process multiple submissions efficiently:

```dart
// Batch grading example
final requests = submissions.map((submission) => 
  GradingRequest(
    submissionId: submission.id,
    language: submission.primaryLanguage,
    files: submission.files,
    testInput: testFiles['inputContent'],
    expectedOutput: testFiles['outputContent'],
  )
).toList();

final results = await gradingProvider.gradeBatch(requests);
```

### 5. Real-time Feedback

Provide immediate feedback during code execution:

- Live execution status updates
- Real-time output streaming
- Error reporting with stack traces
- Performance metrics (execution time, memory usage)

## 📊 Data Models

### Core Models

```dart
// Course model
class Course {
  final String id;
  final String name;
  final String platform; // 'google', 'moodle', etc.
  final List<Assignment> assignments;
}

// Assignment model  
class Assignment {
  final String id;
  final String courseId;
  final String name;
  final String language;
  final List<TestCase> testCases;
  final List<Submission> submissions;
}

// Submission model
class Submission {
  final String id;
  final String studentId;
  final String studentName;
  final List<CodeFile> files;
  final Grade? grade;
}

// Execution result
class ExecutionResult {
  final bool success;
  final String output;
  final String error;
  final int executionTimeMs;
  final bool testPassed;
  final double outputSimilarity;
  final String usedStrategy;
}
```

## 🛠 Development & Customization

### Adding New Programming Languages

1. **Update supported languages:**
```dart
// In app_config.dart
static const Map<String, String> supportedLanguages = {
  'java': 'Java',
  'python': 'Python',
  'javascript': 'JavaScript', 
  'cpp': 'C++',
  'rust': 'Rust', // Add new language
};
```

2. **Add syntax highlighting:**
```dart
// In code_editor.dart
dynamic _getLanguageMode(String language) {
  switch (language.toLowerCase()) {
    case 'rust':
      return rust; // Import highlight language
    // ... other cases
  }
}
```

3. **Configure backend support:**
Ensure your backend supports the new language execution.

### Custom Grading Criteria

```dart
// Custom grading implementation
class CustomGradingCriteria extends GradingCriteria {
  @override
  double calculateScore(ExecutionResult result) {
    // Custom scoring logic
    if (result.testPassed) return 100.0;
    if (result.outputSimilarity >= 90) return 85.0;
    return result.outputSimilarity * 0.7;
  }
}
```

### UI Customization

The interface is built with responsive design principles:

- Collapsible sidebar for smaller screens
- Flexible panel sizing
- Theme customization support
- Accessibility compliance

## 🐛 Troubleshooting

### Common Integration Issues

**Backend Connection:**
```dart
// Test backend connectivity
final executionProvider = Provider.of<ExecutionProvider>(context);
final isHealthy = await executionProvider.checkHealth();
```

**Authentication Issues:**
- Ensure JWT tokens are properly formatted
- Check token expiration and refresh logic
- Verify required scopes for LMS integration

**File Upload Problems:**
- Check file size limits (10MB default)
- Verify supported file extensions
- Ensure proper encoding (UTF-8)

### Debug Features

**Detailed Logging:**
```dart
// Enable debug mode
flutter run --debug -d chrome --web-port 3000
```

**API Request Monitoring:**
Monitor network requests in browser dev tools to debug API communication.

**State Inspection:**
Use Flutter Inspector to examine Provider state and widget tree.

## 📈 Performance Considerations

### Optimization Features

- **Lazy Loading**: Submissions loaded on demand
- **Caching**: Frequent API responses cached locally  
- **Batch Processing**: Multiple operations combined efficiently
- **Memory Management**: Large files processed in streams

### Scalability

The frontend is designed to handle:
- 100+ students per course
- 50+ submissions per assignment
- Multiple concurrent grading operations
- Large code files (up to 10MB)

## 🔒 Security & Privacy

### Data Protection
- No sensitive data stored in browser localStorage
- All API communication over HTTPS
- JWT token secure handling
- File content sanitization

### Access Control
- Role-based access through JWT claims
- Platform-specific permission validation
- Secure file upload handling

## 📄 Dependencies

### Core Flutter Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0           # State management
  http: ^0.13.0              # HTTP client
  file_picker: ^5.0.0        # File selection
  code_text_field: ^1.0.0    # Code editor
  google_fonts: ^4.0.0       # Typography
  csv: ^5.0.0                # CSV export
```

### Development Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

## 🤝 Contributing

### Development Setup
1. Follow Flutter development best practices
2. Use Provider pattern for state management
3. Implement proper error handling and user feedback
4. Test across different browsers and screen sizes

### Code Style
- Follow Dart style guide
- Use meaningful variable names
- Add comprehensive documentation
- Implement unit tests for critical functionality

## 📞 Support

For integration support:
- Review the integration examples above
- Check backend API compatibility
- Test with sample data before production
- Monitor browser console for debugging information

---

**Integration Note**: This frontend is designed to be platform-agnostic. The parent application handles authentication and provides user context through JWT tokens and headers. The grading interface focuses purely on code execution and assessment workflow.