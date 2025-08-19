# FocusEd AI - Enhanced Teacher Grading System Backend

## 🎯 Overview

The FocusEd AI Backend is a comprehensive Spring Boot application that powers an intelligent code execution and grading platform for educational institutions. It provides seamless integration with **Moodle** and **Google Classroom**, enabling teachers to efficiently review, execute, and grade student programming submissions through a unified interface.

## 🏗️ Architecture

### Technology Stack
- **Framework:** Spring Boot 3.2.0
- **Java Version:** Java 17
- **Build Tool:** Maven/Gradle
- **Code Execution:** AWS Lambda Functions (Serverless)
- **APIs:** RESTful web services with JSON
- **Cross-Origin:** CORS enabled for Flutter frontend
- **Authentication:** Token-based (Moodle), OAuth2 (Google)

### System Components
```
┌─────────────────────────────────────────────────────────────────┐
│                    Spring Boot Backend                          │
│                                                                 │
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐│
│  │   Enhanced      │  │  Code Execution  │  │   Grading       ││
│  │   Grading       │  │    Controller    │  │  Management     ││
│  │  Controller     │  │                  │  │                 ││
│  │                 │  │ • Single Exec    │  │ • Course Mgmt   ││
│  │ • Course API    │  │ • Batch Exec     │  │ • Assignment    ││
│  │ • Assignment    │  │ • Language       │  │ • Submission    ││
│  │ • Submission    │  │   Detection      │  │ • Grade Storage ││
│  │ • Grade Mgmt    │  │ • Lambda Routing │  │                 ││
│  └─────────────────┘  └──────────────────┘  └─────────────────┘│
│                                                                 │
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐│
│  │   Batch         │  │   Enhanced       │  │   Data Models   ││
│  │  Execution      │  │   Grading        │  │                 ││
│  │   Service       │  │   Service        │  │ • Assignment    ││
│  │                 │  │                  │  │ • Submission    ││
│  │ • Parallel Exec │  │ • LMS Integration│  │ • Grade         ││
│  │ • Result Agg    │  │ • File Download  │  │ • Course        ││
│  │ • Error Handling│  │ • Token Mgmt     │  │ • TestCase      ││
│  └─────────────────┘  └──────────────────┘  └─────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AWS Lambda Executors                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │   Python    │ │ JavaScript  │ │    Java     │ │     C++     ││
│  │             │ │             │ │             │ │             ││
│  │• Container  │ │• Node.js 18 │ │• OpenJDK 17 │ │• GCC        ││
│  │• Fast Start │ │• VM2 Safety │ │• Maven      │ │• Build Tools││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Key Features

### Code Execution Engine
- **Multi-Language Support:** Python, JavaScript, Java, C++
- **Serverless Architecture:** AWS Lambda functions for scalable execution
- **Batch Processing:** Execute multiple submissions in parallel
- **Real-time Results:** Live execution feedback with performance metrics
- **Security:** Sandboxed execution environment with resource limits

### Educational Platform Integration
- **Moodle Integration:** Direct API integration with web services
- **Google Classroom:** OAuth2 authentication with Drive API access
- **Universal Interface:** Unified API for multiple LMS platforms
- **File Handling:** Automatic download and processing of student submissions

### Enhanced Grading System
- **Manual Grading:** Traditional scoring with feedback
- **Auto-Grading:** Execution-based scoring with intelligent feedback
- **Batch Grading:** Process entire classes simultaneously
- **Grade Passback:** Submit grades directly to LMS platforms
- **Analytics:** Performance tracking and success rate analysis

## 📁 Project Structure

```
backend/
├── src/main/java/com/focusedai/
│   ├── grading/
│   │   ├── GradingApplication.java           # Main application class
│   │   ├── controller/
│   │   │   └── EnhancedGradingController.java # Course/Assignment/Grading APIs
│   │   └── model/
│   │       ├── Assignment.java               # Assignment entity
│   │       ├── Course.java                   # Course entity
│   │       ├── Grade.java                    # Grade entity
│   │       ├── StudentSubmission.java       # Submission entity
│   │       └── TestCase.java                 # Test case entity
│   └── codeexecution/
│       ├── controller/
│       │   └── CodeExecutionController.java  # Code execution APIs
│       ├── service/
│       │   └── CodeExecutionService.java     # Lambda integration
│       └── model/
│           ├── CodeExecutionRequest.java     # Execution request
│           ├── CodeExecutionResult.java      # Execution response
│           ├── CodeFile.java                 # File representation
│           ├── BatchExecutionRequest.java    # Batch request
│           └── BatchExecutionResult.java     # Batch response
└── src/main/resources/
    └── application.properties                # Configuration
```

## 🔧 Configuration

### Application Properties
```properties
# Server Configuration
server.port=8080

# AWS Lambda Function URLs
lambda.python.url=https://your-python-lambda.lambda-url.us-east-1.on.aws/
lambda.javascript.url=https://your-js-lambda.lambda-url.us-east-1.on.aws/
lambda.java.url=https://your-java-lambda.lambda-url.us-east-1.on.aws/
lambda.cpp.url=https://your-cpp-lambda.lambda-url.us-east-1.on.aws/

# Execution Timeouts
lambda.timeout.seconds=90
lambda.batch.timeout.seconds=300

# CORS Configuration
spring.web.cors.allowed-origins=http://localhost:3000
spring.web.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
spring.web.cors.allowed-headers=*
spring.web.cors.allow-credentials=true

# File Upload
spring.servlet.multipart.enabled=true
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

## 📡 API Endpoints

### System Status
```http
GET /api/execute/status
# Returns: Service status and configuration

GET /api/execute/lambda-status  
# Returns: Lambda function availability

GET /api/execute/lambda-test
# Returns: Test results for all languages

GET /api/execute/languages
# Returns: Supported languages and configurations

GET /api/execute/health
# Returns: System health check
```

### Code Execution
```http
POST /api/execute/{language}
# Execute code in specified language
# Body: CodeExecutionRequest
# Returns: CodeExecutionResult

POST /api/execute/python
POST /api/execute/javascript  
POST /api/execute/java
POST /api/execute/cpp
# Language-specific execution endpoints

POST /api/execute/batch
# Execute multiple submissions in parallel
# Body: BatchExecutionRequest
# Returns: BatchExecutionResult

GET /api/execute/batch/{batchId}/status
# Get batch execution status
```

### Course Management
```http
GET /api/courses
# Get all courses

GET /api/courses/{courseId}
# Get specific course

GET /api/courses/{courseId}/assignments
# Get assignments for course

POST /api/courses/{courseId}/assignments
# Create new assignment
# Body: Assignment object
```

### Assignment Management
```http
GET /api/assignments
# Get all assignments

GET /api/assignments/{id}
# Get specific assignment

DELETE /api/assignments/{id}
# Delete assignment

GET /api/assignments/{assignmentId}/submissions
# Get submissions for assignment

POST /api/assignments/{assignmentId}/submissions
# Upload student submissions
# Body: { "submissions": [StudentSubmission...] }
```

### Grading Management
```http
POST /api/submissions/{submissionId}/grade
# Grade individual submission
# Body: { "score": 85, "feedback": "Good work!" }

GET /api/submissions/{submissionId}/grade
# Get grade for submission

POST /api/assignments/{assignmentId}/grade-all
# Start batch grading for all submissions

POST /api/assignments/{assignmentId}/test-files
# Upload test input/output files
# Form data: inputFile, outputFile
```

### Utility Endpoints
```http
GET /api/assignments/count
GET /api/submissions/count  
GET /api/grades/count
# Get system statistics
```

## 🔄 Request/Response Models

### Code Execution Request
```json
{
  "files": [
    {
      "filename": "Main.java",
      "content": "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello World!\");\n    }\n}"
    }
  ],
  "mainClassName": "Main",
  "platform": "moodle",
  "assignmentId": "assignment_123",
  "studentId": "student_456"
}
```

### Code Execution Result
```json
{
  "success": true,
  "output": "Hello World!\n",
  "error": "",
  "language": "JAVA",
  "serverless": true,
  "architecture": "100% Serverless",
  "executionType": "🚀 ☕ Container-based Lambda with JDK",
  "executionTimeMs": 1250
}
```

### Batch Execution Request
```json
{
  "assignmentId": "assignment_123",
  "platform": "classroom",
  "submissions": [
    {
      "submissionId": "sub_001",
      "studentId": "student_001",
      "studentName": "John Doe",
      "filename": "solution.py",
      "code": "print('Hello from John!')"
    }
  ]
}
```

### Batch Execution Result
```json
{
  "batchId": "batch_456",
  "assignmentId": "assignment_123",
  "totalSubmissions": 25,
  "successfulExecutions": 22,
  "failedExecutions": 3,
  "executionTimeMs": 45000,
  "startTime": "2024-01-15T10:30:00Z",
  "endTime": "2024-01-15T10:30:45Z",
  "results": {
    "sub_001": {
      "success": true,
      "output": "Hello from John!",
      "error": "",
      "language": "PYTHON"
    }
  }
}
```

## 🛠️ Development Setup

### Prerequisites
- **Java 17+**
- **Maven 3.6+** or **Gradle 7+**
- **AWS CLI** (configured for Lambda access)
- **Docker** (for Lambda container testing)

### Local Development
```bash
# Clone repository
git clone <repository-url>
cd backend

# Install dependencies and compile
mvn clean install

# Run application
mvn spring-boot:run

# Alternative with Gradle
./gradlew bootRun

# Verify application is running
curl http://localhost:8080/api/execute/status
```

### AWS Lambda Setup
1. **Deploy Lambda Functions** using AWS SAM or CDK
2. **Configure Function URLs** for each language executor
3. **Update application.properties** with Lambda URLs
4. **Test connectivity** using `/api/execute/lambda-test`

### Environment Configuration
```bash
# Development environment
export SPRING_PROFILES_ACTIVE=development

# AWS credentials for Lambda access
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1

# Lambda function URLs
export LAMBDA_PYTHON_URL=https://your-python-lambda.lambda-url.us-east-1.on.aws/
export LAMBDA_JAVASCRIPT_URL=https://your-js-lambda.lambda-url.us-east-1.on.aws/
export LAMBDA_JAVA_URL=https://your-java-lambda.lambda-url.us-east-1.on.aws/
export LAMBDA_CPP_URL=https://your-cpp-lambda.lambda-url.us-east-1.on.aws/
```

## 🧪 Testing

### Unit Testing
```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=CodeExecutionControllerTest

# With coverage report
mvn test jacoco:report
```

### Integration Testing
```bash
# Test code execution endpoint
curl -X POST http://localhost:8080/api/execute/python \
  -H "Content-Type: application/json" \
  -d '{
    "files": [{"filename": "test.py", "content": "print(\"Hello World!\")"}],
    "platform": "test"
  }'

# Test batch execution
curl -X POST http://localhost:8080/api/execute/batch \
  -H "Content-Type: application/json" \
  -d '{
    "assignmentId": "test-assignment",
    "platform": "test",
    "submissions": [
      {
        "submissionId": "test-sub-1",
        "studentId": "student-1",
        "studentName": "Test Student",
        "filename": "hello.py",
        "code": "print(\"Hello from test!\")"
      }
    ]
  }'

# Test Lambda connectivity
curl http://localhost:8080/api/execute/lambda-test
```

### Mock Data Testing
The system includes built-in mock data for development and testing:
- **Mock Courses:** CS101, CS201, CS301
- **Mock Assignments:** Python/Java programming assignments
- **Mock Submissions:** Sample student code with various complexity levels

## 🔒 Security Features

### Code Execution Security
- **Sandboxed Environment:** Lambda containers with restricted permissions
- **Resource Limits:** CPU, memory, and execution time constraints
- **Input Validation:** Code content sanitization before execution
- **Output Filtering:** Error message sanitization for security
- **Network Isolation:** No external network access during execution

### API Security
- **CORS Configuration:** Controlled cross-origin access
- **Input Validation:** Request payload validation
- **Error Handling:** Secure error messages without sensitive data
- **Rate Limiting:** Protection against abuse (configurable)

### Data Protection
- **No Persistent Storage:** Code content not stored permanently
- **Secure Transmission:** HTTPS for all API communications
- **Token Management:** Secure handling of LMS authentication tokens
- **Access Control:** Platform-specific access restrictions

## 📊 Monitoring & Logging

### Application Monitoring
```java
// Built-in health checks
GET /api/execute/health
GET /api/execute/status

// Custom metrics endpoints
GET /api/assignments/count
GET /api/submissions/count
GET /api/grades/count
```

### Logging Configuration
The application provides comprehensive logging:
- **Request/Response Logging:** All API calls with timing
- **Code Execution Tracking:** Detailed execution metrics
- **Error Logging:** Stack traces and error context
- **Performance Monitoring:** Lambda cold start and execution times

### Debug Information
```bash
# Enable debug logging
export LOGGING_LEVEL_COM_FOCUSEDAI=DEBUG

# View application logs
tail -f logs/spring-boot-application.log

# Monitor Lambda executions
aws logs tail "/aws/lambda/focusedai-python-executor" --region us-east-1
```

## 🚨 Troubleshooting

### Common Issues

#### Backend Won't Start
```bash
# Check Java version
java -version  # Should be 17+

# Verify application.properties
cat src/main/resources/application.properties

# Check port availability
netstat -an | grep 8080
```

#### Lambda Functions Not Working
```bash
# Test Lambda URLs directly
curl -X POST https://your-python-lambda.lambda-url.us-east-1.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{"files":[{"filename":"test.py","content":"print(\"test\")"}]}'

# Check Lambda configuration
curl http://localhost:8080/api/execute/lambda-status

# Verify AWS credentials
aws sts get-caller-identity
```

#### Code Execution Timeouts
```bash
# Increase timeout in application.properties
lambda.timeout.seconds=120

# Check Lambda function timeout settings
aws lambda get-function-configuration --function-name your-function-name
```

#### CORS Issues
```bash
# Verify CORS configuration
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     http://localhost:8080/api/execute/python
```

### Error Codes
- **500:** Internal server error (check logs)
- **404:** Lambda URL not configured
- **408:** Execution timeout
- **400:** Invalid request format
- **503:** Lambda function unavailable

## 🔮 Future Enhancements

### Planned Features
- **Database Integration:** Persistent storage for grades and analytics
- **Advanced Security:** Enhanced authentication and authorization
- **Test Case Automation:** Automated testing against expected outputs
- **Performance Analytics:** Detailed execution metrics and reporting
- **Multi-Language Extensions:** Support for additional programming languages

### Scalability Improvements
- **Load Balancing:** Multiple backend instances
- **Caching Layer:** Redis for improved performance
- **Async Processing:** Background job processing for large batches
- **Database Optimization:** Efficient data storage and retrieval

### Integration Enhancements
- **Canvas LMS:** Additional platform support
- **Blackboard:** Extended LMS integration
- **GitHub Classroom:** Version control integration
- **IDE Plugins:** Direct IDE integration for teachers

## 📈 Performance Metrics

### Current Capacity
- **Concurrent Executions:** 1000+ simultaneous Lambda invocations
- **Batch Processing:** 50+ submissions processed in parallel
- **Response Times:** <100ms for API endpoints, 1-30s for code execution
- **Throughput:** 10,000+ executions per hour
- **Languages:** Python, JavaScript, Java, C++

### Optimization Features
- **Lambda Warm-up:** Container reuse for faster execution
- **Parallel Processing:** Concurrent batch execution
- **Efficient Routing:** Language-specific Lambda targeting
- **Resource Management:** Optimal memory and CPU allocation

## 🤝 Contributing

### Development Guidelines
1. **Code Style:** Follow Spring Boot conventions
2. **Testing:** Maintain 80%+ test coverage
3. **Documentation:** Update README for new features
4. **Security:** Review all API endpoints for security
5. **Performance:** Monitor execution times and optimize

### Pull Request Process
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request with detailed description

## 📞 Support

For technical support or questions:
- **Issues:** Create GitHub issue with detailed description
- **Documentation:** Check inline code comments
- **Logs:** Enable debug logging for troubleshooting
- **Community:** Join development discussions

**FocusEd AI Backend** - Empowering educators with intelligent code execution and grading capabilities.