# FocusedAI Code Execution & Grading Service

A high-performance Spring Boot backend service for automated code compilation, execution, and grading that integrates seamlessly with Learning Management Systems (LMS) including Moodle and Google Classroom.

## 🚀 Project Overview

FocusedAI Backend is an intelligent code grading platform designed for educators to automatically grade programming assignments. The system supports multiple programming languages, integrates with popular LMS platforms, and provides sophisticated code execution strategies with automated feedback generation.

### Key Features

- **Multi-Language Support**: Java, Python, JavaScript, and C++
- **LMS Integration**: Seamless integration with external authentication systems
- **Intelligent Execution Strategies**: Automatic detection of code patterns for optimal execution
- **Enhanced Grading**: Strategy-aware grading with detailed feedback
- **Batch Processing**: Grade multiple submissions simultaneously
- **Real-time Execution**: AWS Lambda-powered code execution
- **RESTful API**: Clean API design for easy integration
- **JWT Authentication**: Secure token-based authentication

## 📋 Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Integration Guide](#integration-guide)
- [API Documentation](#api-documentation)
- [Code Execution System](#code-execution-system)
- [Grading System](#grading-system)
- [Development Guide](#development-guide)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Your LMS      │    │   FocusedAI     │    │   AWS Lambda    │
│   Frontend      │◄──►│   Backend       │◄──►│   Executors     │
│   (Auth Handler)│    │   (This Service)│    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │ Token Validation│
                       │ & User Context  │
                       └─────────────────┘
```

### Core Services

- **ExecutionService**: Manages code execution with intelligent strategy detection
- **GradingService**: Automated grading with detailed feedback generation
- **LambdaClient**: AWS Lambda integration for secure code execution
- **StrategyDetector**: Intelligent code pattern analysis
- **FeedbackGenerator**: Automated feedback generation
- **UserContextExtractor**: JWT token processing and user context extraction

## 📦 Prerequisites

### Required Software

- **Java 17+** - The application runs on Java 17
- **Gradle 8.14.2** - Build tool (wrapper included)
- **Spring Boot 3.2.0** - Framework version

### External Services

- **AWS Lambda Functions** - For code execution (URLs configured in properties)
- **JWT Secret** - For token validation (must match parent application)
- **Encryption Key** - For secure data handling (32 characters for AES-256)

### Development Tools (Recommended)

- IntelliJ IDEA or VS Code
- Postman for API testing
- Git for version control

## 🔧 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd focusedai-backend
```

### 2. Build the Project

```bash
# Using the Gradle wrapper (recommended)
./gradlew build

# On Windows
gradlew.bat build
```

### 3. Run the Application

```bash
# Development mode with auto-reload
./gradlew bootRun

# Or run the JAR file
./gradlew bootJar
java -jar build/libs/focusedai-backend-1.0.0.jar
```

### 4. Verify Installation

The application will start on `http://localhost:8080`. You should see:

```
🚀 FocusedAI Code Execution & Grading Service started successfully!
📡 API available at: http://localhost:8080
🔍 Health check: http://localhost:8080/api/execute/health
📊 Available endpoints:
   POST /api/execute/{language} - Execute code
   POST /api/execute/batch - Batch execute
   POST /api/grade/submission - Grade submission
   POST /api/grade/batch - Batch grade
```

## ⚙️ Configuration

### Application Properties

Edit `src/main/resources/application.properties`:

```properties
# Server Configuration
server.port=8080

# JWT Configuration (MUST match your parent application)
jwt.secret=your-jwt-secret-key-must-be-same-as-parent-app
encryption.key=your-32-character-encryption-key!!

# AWS Lambda URLs (Code Execution)
lambda.java.url=https://your-java-lambda-url.lambda-url.us-east-1.on.aws/
lambda.python.url=https://your-python-lambda-url.lambda-url.us-east-1.on.aws/
lambda.javascript.url=https://your-js-lambda-url.lambda-url.us-east-1.on.aws/
lambda.cpp.url=https://your-cpp-lambda-url.lambda-url.us-east-1.on.aws/

# Execution Configuration
lambda.timeout.seconds=90
lambda.batch.timeout.seconds=300

# File Upload Configuration
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB

# CORS Configuration (adjust for your frontend domain)
cors.allowed-origins=http://localhost:3000,https://your-frontend-domain.com
```

### Environment Variables (Optional)

```bash
export JWT_SECRET=your-jwt-secret-key
export ENCRYPTION_KEY=your-32-character-encryption-key
export LAMBDA_JAVA_URL=https://your-java-lambda-url.lambda-url.us-east-1.on.aws/
```

## 🔗 Integration Guide

### Parent Application Requirements

Your parent application (the one handling LMS authentication) must:

1. **Handle LMS Authentication** (Google Classroom, Moodle, etc.)
2. **Generate JWT Tokens** with required claims
3. **Send HTTP Requests** to this service with proper Authorization headers

### JWT Token Format

The FocusedAI Backend expects JWT tokens with these claims:

```json
{
  "sub": "user_id",
  "lms": "googleClassroom|moodle",
  "identifier": "encrypted_user_identifier",
  "role": "teacher|student|admin",
  "exp": 1640995200,
  
  // For Google Classroom users
  "googleAccessToken": "encrypted_access_token",
  "googleRefreshToken": "encrypted_refresh_token", 
  "googleTokenExpiry": 1640995200000,
  
  // For Moodle users
  "moodleDomain": "encrypted_moodle_domain",
  "webServiceToken": "encrypted_web_service_token"
}
```

### Integration Steps

#### 1. **Set Up JWT Signing**
Ensure your parent application uses the same JWT secret:

```java
// Your parent application
String jwtSecret = "your-shared-secret-key";
String token = Jwts.builder()
    .setSubject(userId)
    .claim("lms", "googleClassroom")
    .claim("role", "teacher")
    .claim("googleAccessToken", encryptToken(accessToken))
    .setExpiration(new Date(System.currentTimeMillis() + 86400000))
    .signWith(SignatureAlgorithm.HS256, jwtSecret)
    .compact();
```

#### 2. **Make API Calls**
Send requests with Authorization header:

```javascript
// Your frontend application
const response = await fetch('http://localhost:8080/api/execute/java', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${jwtToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    files: [{
      filename: 'HelloWorld.java',
      content: 'public class HelloWorld { ... }',
      language: 'java'
    }],
    testInput: 'sample input',
    expectedOutput: 'expected output'
  })
});
```

#### 3. **Handle Course/Assignment Data**
The service can work with or without LMS integration:

```javascript
// Option A: Pass course/assignment data directly
const submissionsData = await fetch('/api/assignments/assign123/submissions', {
  headers: { 'Authorization': `Bearer ${token}` }
});

// Option B: Service creates fallback data when LMS unavailable
// No additional setup needed - service handles gracefully
```

### Integration Examples

#### React Integration
```jsx
import { FocusedAIClient } from './focusedai-client';

const client = new FocusedAIClient({
  baseUrl: 'http://localhost:8080',
  getToken: () => localStorage.getItem('jwt_token')
});

// Execute code
const result = await client.executeCode('java', {
  files: codeFiles,
  testInput: 'input data',
  expectedOutput: 'expected output'
});

// Grade submission
const grade = await client.gradeSubmission({
  submissionId: 'sub123',
  assignmentId: 'assign123',
  language: 'java',
  files: codeFiles
});
```

#### Flutter Integration
```dart
// Use the included Flutter UI components
import 'package:focusedai_teacher/app/app.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CodeGradingInterface(
        backendUrl: 'http://localhost:8080',
        authHeaders: {'Authorization': 'Bearer $token'},
        courses: yourCoursesList,
        onGradeSubmitted: (gradeData) {
          // Handle grade submission
        },
      ),
    );
  }
}
```

## 📚 API Documentation

### Core Endpoints

#### Execute Code
```http
POST /api/execute/{language}
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "files": [
    {
      "filename": "Main.java",
      "content": "public class Main {...}",
      "language": "java"
    }
  ],
  "testInput": "sample input",
  "expectedOutput": "expected output",
  "submissionId": "optional-submission-id",
  "timeoutMs": 30000
}
```

**Response:**
```json
{
  "success": true,
  "output": "program output",
  "error": null,
  "executionTimeMs": 1250,
  "memoryUsedMb": 64,
  "testPassed": true,
  "outputSimilarity": 100.0,
  "usedStrategy": "STDIN_STDOUT",
  "detectedStrategy": "STDIN_STDOUT",
  "codeAnalysis": {
    "language": "java",
    "recommendedStrategy": "STDIN_STDOUT",
    "confidence": 95.0
  }
}
```

#### Grade Submission
```http
POST /api/grade/submission
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "submissionId": "sub123",
  "assignmentId": "assign123",
  "language": "java",
  "files": [...],
  "testInput": "test input",
  "expectedOutput": "expected output",
  "maxScore": 100.0
}
```

**Response:**
```json
{
  "success": true,
  "gradeId": "grade456",
  "score": 85.0,
  "maxScore": 100.0,
  "percentage": 85.0,
  "letterGrade": "B",
  "feedback": "Great work! Your code passes all tests...",
  "passed": true,
  "gradingStrategy": "STDIN_STDOUT",
  "executionDetails": {...}
}
```

#### Batch Operations
```http
POST /api/execute/batch
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "submissions": {
    "sub1": {
      "language": "java",
      "files": [...],
      "input": "test input"
    },
    "sub2": {...}
  }
}
```

#### Health Check
```http
GET /api/execute/health
```

**Response:**
```json
{
  "overallStatus": "healthy",
  "endpoints": {
    "java": {"status": "healthy", "responseTime": 250},
    "python": {"status": "healthy", "responseTime": 180}
  },
  "timestamp": 1640995200000
}
```

### Authentication

All API endpoints (except health checks) require a valid JWT token in the Authorization header:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

The service will:
1. Validate the JWT signature
2. Extract user information
3. Check token expiration
4. Decrypt sensitive LMS credentials if needed

## 🔧 Code Execution System

### Execution Strategies

The system automatically detects the best execution strategy for code:

#### 1. STDIN_STDOUT (Default)
- **Use Case**: Programs with main method that read from stdin and write to stdout
- **Detection**: Has main method + Scanner usage or System.out
- **Example**: Console applications with user input

#### 2. METHOD_CALL
- **Use Case**: Classes with public methods for direct testing
- **Detection**: Public methods without main method, or simple main with method calls
- **Example**: Calculator class with add(), subtract() methods

#### 3. UNIT_TEST
- **Use Case**: JUnit-style test methods
- **Detection**: @Test annotations or test method patterns
- **Example**: Test classes with assertion methods

#### 4. INTERACTIVE
- **Use Case**: Programs with loops and multiple user interactions
- **Detection**: Loops + multiple input operations + menu patterns
- **Example**: Menu-driven applications

#### 5. FILE_IO
- **Use Case**: Programs that read from and write to files
- **Detection**: FileReader, FileWriter, Files API usage
- **Example**: File processing applications

### Lambda Architecture

Code execution happens on AWS Lambda functions for security and scalability:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Spring Boot   │    │   Lambda Java   │    │  Lambda Python  │
│   Backend       │───►│   Executor      │    │  Executor       │
│                 │    └─────────────────┘    └─────────────────┘
│                 │    ┌─────────────────┐    ┌─────────────────┐
│                 │───►│ Lambda JavaScript│    │  Lambda C++     │
│                 │    │ Executor        │    │  Executor       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📊 Grading System

### Enhanced Grading Features

#### Strategy-Aware Scoring

Different strategies use different scoring algorithms:

- **STDIN_STDOUT**: Based on output similarity and test pass/fail
- **METHOD_CALL**: Aggregate score from multiple method tests
- **UNIT_TEST**: Percentage of passing tests
- **INTERACTIVE**: Similarity with tolerance for interactive variations
- **FILE_IO**: File output verification + console output

#### Automatic Feedback Generation

The system generates detailed feedback based on execution results:

```
✅ Excellent! Your code passes all tests.
Your program produces the correct output.

⏱️ Execution time: 1250ms
🔧 Execution Strategy: Standard Input/Output
Your code was tested with standard console input/output.
```

#### Letter Grade Calculation

```java
private String calculateLetterGrade(double percentage) {
    if (percentage >= 90) return "A";
    if (percentage >= 80) return "B";
    if (percentage >= 70) return "C";
    if (percentage >= 60) return "D";
    return "F";
}
```

### Batch Grading

Grade multiple submissions efficiently:

```http
POST /api/grade/batch
{
  "submissions": {
    "sub1": {...},
    "sub2": {...}
  }
}
```

The system:
1. Executes all submissions in parallel (configurable concurrency)
2. Applies strategy detection to each submission
3. Generates grades and feedback
4. Returns comprehensive results with statistics

## 🛠️ Development Guide

### Project Structure

```
src/main/java/com/focusedai/
├── FocusedAiApplication.java        # Main Spring Boot application
├── config/                         # Configuration classes
│   ├── CorsConfig.java             # CORS configuration
│   └── ExecutionConfig.java        # Lambda execution configuration
├── controller/                     # REST controllers
│   ├── ExecutionController.java    # Code execution endpoints
│   ├── GradingController.java      # Grading endpoints
│   ├── AssignmentController.java   # Assignment management
│   ├── CourseController.java       # Course management
│   └── TestCaseController.java     # Test case management
├── dto/                           # Data Transfer Objects
│   ├── ExecutionRequestDto.java
│   ├── ExecutionResultDto.java
│   ├── GradingRequestDto.java
│   └── BatchExecutionResultDto.java
├── model/                         # Data models
│   ├── execution/                 # Execution-related models
│   ├── grading/                   # Grading-related models
│   └── testcase/                  # Test case models
├── service/                       # Business logic services
│   ├── execution/                 # Execution services
│   │   ├── ExecutionService.java  # Main execution logic
│   │   ├── LambdaClient.java      # AWS Lambda integration
│   │   └── StrategyDetector.java  # Code analysis
│   ├── grading/                   # Grading services
│   │   ├── GradingService.java    # Main grading logic
│   │   └── FeedbackGenerator.java # Feedback generation
│   ├── lms/                       # LMS integration services
│   │   ├── AssignmentService.java
│   │   ├── CourseService.java
│   │   └── client/                # LMS client implementations
│   └── testcase/                  # Test case management
├── utils/                         # Utility classes
│   ├── JwtUtil.java              # JWT token processing
│   └── UserContextExtractor.java # User context extraction
└── exception/                     # Exception handling
    ├── ExecutionException.java
    ├── GradingException.java
    └── GlobalExceptionHandler.java
```

### Adding New Features

#### 1. Adding a New Programming Language

1. **Create Lambda Function** for the new language
2. **Add Lambda URL** to `application.properties`:
   ```properties
   lambda.ruby.url=https://your-ruby-lambda-url.lambda-url.us-east-1.on.aws/
   ```
3. **Update LambdaClient**:
   ```java
   private String getLambdaUrl(String language) {
       switch (language.toLowerCase()) {
           case "ruby":
               return rubyLambdaUrl;
           // ... other cases
       }
   }
   ```

#### 2. Adding Custom Grading Criteria

```java
@PostMapping("/api/grade/criteria/{language}")
public ResponseEntity<Map<String, Object>> updateGradingCriteria(
        @PathVariable String language,
        @RequestBody Map<String, Object> criteria,
        @RequestHeader("Authorization") String token) {
    
    gradingService.updateGradingCriteria(language, criteria, token);
    return ResponseEntity.ok(Map.of("success", true));
}
```

#### 3. Adding New Execution Strategies

1. **Define Pattern Detection** in `StrategyDetector`:
   ```java
   private static final Pattern NEW_STRATEGY_PATTERN = 
       Pattern.compile("your_pattern_here");
   ```
2. **Add Strategy Detection** in `determineExecutionStrategy()`
3. **Implement Strategy Handling** in Lambda functions
4. **Add Scoring Logic** in `GradingService`

### Testing

#### Unit Tests

```bash
./gradlew test
```

#### Integration Tests

```bash
# Test health endpoints
curl -X GET http://localhost:8080/api/execute/health

# Test code execution
curl -X POST http://localhost:8080/api/execute/java \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"files":[{"filename":"Hello.java","content":"...","language":"java"}]}'
```

#### Lambda Testing

```bash
# Test individual language Lambda functions
curl -X GET http://localhost:8080/api/test/lambda/java \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🚨 Troubleshooting

### Common Issues

#### 1. JWT Authentication Errors

**Problem**: 403 Forbidden or "Invalid token" errors
**Solution**: 
- Verify JWT secret matches between parent app and this service
- Check token expiration
- Ensure proper Authorization header format: `Bearer {token}`
- Validate encryption key is exactly 32 characters

#### 2. Lambda Function Timeouts

**Problem**: Code execution takes too long
**Solution**: 
- Increase timeout in `application.properties`
- Check Lambda function configuration
- Optimize student code or increase memory limits

#### 3. CORS Errors

**Problem**: Frontend cannot connect to backend
**Solution**:
- Update `cors.allowed-origins` in `application.properties`
- Verify preflight requests are handled correctly
- Check that credentials are allowed if needed

#### 4. Strategy Detection Issues

**Problem**: Wrong execution strategy detected
**Solution**:
- Review `StrategyDetector` patterns
- Force specific strategy using `forceStrategy` parameter
- Add logging to understand detection logic

### Debug Configuration

```properties
# Enable debug logging
logging.level.com.focusedai=DEBUG
logging.level.org.springframework.web=DEBUG
logging.level.org.springframework.security=DEBUG

# Enable web request logging
logging.level.org.apache.http=DEBUG
```

### Health Checks

#### System Health
```http
GET /api/execute/health
```

#### Strategy Information
```http
GET /api/execute/strategies
```

#### Lambda Connectivity
```bash
# Test each language endpoint
curl -X GET http://localhost:8080/api/test/lambda/java
curl -X GET http://localhost:8080/api/test/lambda/python
```

## 🚀 Deployment

### Production Configuration

```properties
# Production settings
server.port=8080
spring.profiles.active=production

# Security
jwt.secret=${JWT_SECRET}
encryption.key=${ENCRYPTION_KEY}

# Lambda URLs
lambda.java.url=${LAMBDA_JAVA_URL}
lambda.python.url=${LAMBDA_PYTHON_URL}
lambda.javascript.url=${LAMBDA_JAVASCRIPT_URL}
lambda.cpp.url=${LAMBDA_CPP_URL}

# Performance
lambda.timeout.seconds=60
lambda.batch.timeout.seconds=180

# CORS for production
cors.allowed-origins=${ALLOWED_ORIGINS}
```

### Docker Deployment

```dockerfile
FROM openjdk:17-jdk-slim

COPY build/libs/focusedai-backend-*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app.jar"]
```

### Environment Variables

```bash
# Required
export JWT_SECRET="your-shared-secret-key"
export ENCRYPTION_KEY="your-32-character-encryption-key"

# AWS Lambda URLs
export LAMBDA_JAVA_URL="https://..."
export LAMBDA_PYTHON_URL="https://..."

# Optional
export ALLOWED_ORIGINS="https://your-frontend.com"
export SERVER_PORT="8080"
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/new-feature`
3. **Make changes** and add tests
4. **Run tests**: `./gradlew test`
5. **Update documentation** as needed
6. **Commit changes**: `git commit -am 'Add new feature'`
7. **Push to branch**: `git push origin feature/new-feature`
8. **Create Pull Request**

### Code Style

- Follow Java naming conventions
- Use meaningful variable and method names
- Add comprehensive JavaDoc comments
- Include error handling and logging
- Write unit tests for new features

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

1. **Check the troubleshooting section** above
2. **Verify JWT token format** and encryption
3. **Test Lambda connectivity** using health endpoints
4. **Review logs** for detailed error information

---

**Ready to integrate! 🎓💻**

This service is designed to work seamlessly with your existing LMS authentication system. Simply generate JWT tokens in your parent application and start making API calls for code execution and grading.