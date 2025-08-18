# Code Compiler Frontend

Flutter web application that provides an interactive code editor supporting Java, JavaScript, Python, and C++ through a **100% serverless AWS Lambda architecture**.

## 🎯 Features

- **Multi-language support**: Java, JavaScript, Python, C++ with serverless execution
- **Interactive code editor** with syntax highlighting and multi-file support
- **Real-time execution feedback**: Direct connection to AWS Lambda functions
- **File upload/download** functionality with drag-and-drop support
- **Dark/light theme** toggle with modern UI design
- **Multi-tab interface**: Organize and manage multiple files
- **Responsive design** optimized for desktop development workflow
- **Serverless architecture**: 100% cloud-native execution via AWS Lambda

## 🚀 Serverless Architecture

The frontend connects directly to a Spring Boot backend that routes requests to dedicated AWS Lambda functions:

```
Flutter Frontend → Spring Boot API → AWS Lambda Functions
                                   ↓
                    ┌─────────────────────────────────┐
                    │ 🐍 Python Lambda (Zip-based)    │
                    ├─────────────────────────────────┤
                    │ 📜 JavaScript Lambda (Zip-based)│
                    ├─────────────────────────────────┤
                    │ ☕ Java Lambda (Container)      │
                    ├─────────────────────────────────┤
                    │ ⚡ C++ Lambda (Container)       │
                    └─────────────────────────────────┘
```

### Lambda Function URLs (Active)

The system uses direct Lambda Function URLs for optimal performance:

- **Python**: `https://34pmcs4f3bhdaew4jvslmfpxbu0lgvlx.lambda-url.us-east-1.on.aws/`
- **JavaScript**: `https://b6lcdqvy2vuvioxdy4nxhmky6y0vifre.lambda-url.us-east-1.on.aws/`
- **Java**: `https://xwvunfec7yql2xxqpirpa5iq440bxsjs.lambda-url.us-east-1.on.aws/`
- **C++**: `https://jnjk22jq62wrrm3hll3n42swie0fxmun.lambda-url.us-east-1.on.aws/`

### Performance Characteristics

- **Python/JavaScript (Zip-based)**: Fast startup, 5-15 second execution
- **Java/C++ (Container-based)**: Cold start ~10-30s, warm execution ~5-10s
- **Cost**: Pay-per-execution model, no idle costs
- **Scalability**: Automatic scaling from 0 to thousands of concurrent executions

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.8+) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Chrome Browser** (latest version for optimal performance)
- **VS Code** with Flutter and Dart extensions (recommended)
- **Backend service running** - See [Backend README](../backend/README.md) for complete setup

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd summer2025/frontend/
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint:**
   
   The frontend is configured to connect to the Spring Boot backend at:
   ```dart
   // In lib/main.dart (line ~56)
   final String baseUrl = 'http://localhost:8080/api';
   ```

4. **Start the Spring Boot backend:**
   ```bash
   # In another terminal, start the Spring Boot backend
   cd ../backend/
   ./gradlew bootRun
   
   # Wait for: "Started CodeCompilerApplication in X.XXX seconds"
   ```

5. **Verify Lambda connectivity:**
   ```bash
   # Test backend health and Lambda status
   curl http://localhost:8080/lambda-status
   
   # Test all Lambda functions
   curl http://localhost:8080/lambda-test
   ```

6. **Run the Flutter application:**
   ```bash
   # Back in frontend directory
   flutter run -d chrome --web-port 3000
   ```

7. **Open and test the application:**
   - Navigate to `http://localhost:3000`
   - Try the test suite below to verify all languages work

## ⚡ Testing Guide

### Test All Languages

Once your app is running, test each language:

#### Test 1: Python (Zip-based Lambda)
```python
# Submit this Python code:
print("Hello from Python Lambda!")
print("This is a zip-based Lambda function")

# Expected: 5-15 second execution
# Status: "🐍 Zip-based Lambda"
```

#### Test 2: JavaScript (Zip-based Lambda)
```javascript
// Submit this JavaScript code:
console.log("Hello from JavaScript Lambda!");
console.log("Fast Node.js execution in AWS Lambda");

// Expected: 5-15 second execution
// Status: "📜 Zip-based Lambda"
```

#### Test 3: Java (Container Lambda)
```java
// Submit this Java code:
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello from Java Lambda Container!");
        System.out.println("Amazon Corretto JDK in container");
    }
}

// Expected: 10-30s (cold start) or 5-10s (warm)
// Status: "☕ Container-based Lambda with JDK"
```

#### Test 4: C++ (Container Lambda)
```cpp
// Submit this C++ code:
#include <iostream>
using namespace std;

int main() {
    cout << "Hello from C++ Lambda Container!" << endl;
    cout << "GCC compiler in AWS Lambda" << endl;
    return 0;
}

// Expected: 10-30s (cold start) or 5-10s (warm)  
// Status: "⚡ Container-based Lambda with g++"
```

## 📱 User Interface

### Code Editor Features

- **Multi-tab Interface**: Work with multiple files simultaneously
- **Language Detection**: Automatic syntax highlighting based on file extension
- **File Management**: Create, rename, and delete tabs easily
- **File Upload**: Drag and drop or browse to upload code files
- **File Download**: Save your code as files to your computer

### Execution Status

The UI shows real-time execution status:
- **Language Icon**: Visual indicator for selected language
- **Execution Type**: Shows which Lambda function is being used
- **Execution Time**: Real-time progress and completion time
- **Serverless Indicator**: Confirms 100% serverless execution

### Status Information

The status bar displays execution details:
```
🚀 Last: Java Container Lambda (28s) | Serverless: ✅ | Architecture: 100% Serverless
```

## 📁 Project Structure

```
frontend/
├── lib/
│   └── main.dart                     # Main application with Flutter code editor
├── web/
│   ├── index.html                    # Web entry point
│   └── manifest.json                 # PWA configuration
├── pubspec.yaml                      # Dependencies
└── README.md                         # This file
```

## 🔌 API Integration

### Request Format

The frontend sends code via JSON to the Spring Boot backend:

```dart
// Example request format
{
  "files": [
    {
      "filename": "HelloWorld.java",
      "content": "public class HelloWorld { ... }"
    }
  ],
  "mainClassName": "HelloWorld"
}
```

### Response Format

```dart
// Example response from Lambda
{
  "success": true,
  "output": "Hello from Java Lambda Container!\nAmazon Corretto JDK in container\n",
  "error": "",
  "executionType": "🚀 ☕ Container-based Lambda with JDK",
  "endpoint": "https://xwvunfec7yql2xxqpirpa5iq440bxsjs.lambda-url.us-east-1.on.aws",
  "serverless": true,
  "language": "JAVA",
  "architecture": "100% Serverless"
}
```

### Service Integration

The `CodeSubmissionService` handles all API communication:

```dart
class CodeSubmissionService {
  final String baseUrl = 'http://localhost:8080/api';

  Future<Map<String, dynamic>> executeCode({
    required List<http.MultipartFile> codeFiles,
    required String mainClassName, 
    required String language,
  }) async {
    // Converts files to JSON format
    // Sends to /api/compile/{language} endpoint
    // Returns execution results from Lambda
  }
}
```

## 🧪 Development & Testing

### Running Locally

```bash
# Start with verbose logging
flutter run -d chrome --web-port 3000 --verbose

# Monitor backend logs simultaneously
cd ../backend && ./gradlew bootRun
```

### Key Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.4.0                    # API requests
  file_picker: ^10.2.0           # File upload
  file_saver: ^0.2.6             # File download
  flutter_code_editor: ^0.3.3    # Code editor with syntax highlighting
  highlight: ^0.7.0              # Language highlighting
  http_parser: ^4.1.2            # Multipart requests
```

## 🎯 Usage Workflow

### Basic Usage

1. **Select Language**: Choose from Java, JavaScript, Python, or C++
2. **Write/Upload Code**: Use the editor or upload existing files
3. **Set Main Class**: Enter the main class/file name (auto-detected)
4. **Execute**: Click "Run" to send to appropriate Lambda function
5. **View Results**: See output, errors, and execution details

### File Management

- **New File**: Create additional tabs for multi-file projects
- **Upload**: Support for .java, .js, .py, .cpp files
- **Rename**: Click filename to rename files
- **Save**: Download files to your computer
- **Multi-tab**: Work with multiple files in organized tabs

### Language-Specific Features

- **Java**: Automatic main class detection from filename
- **JavaScript**: Node.js runtime with console.log support
- **Python**: Python 3.11 with full standard library
- **C++**: GCC compiler with C++17 standard support

## 🔍 Troubleshooting

### Common Issues

**Backend not responding:**
```bash
# Verify backend is running
curl http://localhost:8080/

# Check Lambda connectivity  
curl http://localhost:8080/lambda-status
```

**Lambda function errors:**
```bash
# Test specific language
curl http://localhost:8080/lambda-test

# Check individual Lambda status
curl -X GET "http://localhost:8080/lambda-status"
```

**Code execution timeouts:**
- Container-based Lambdas (Java/C++) may take 10-30s on cold start
- This is normal for serverless architecture
- Subsequent executions will be faster (warm start)

**File upload issues:**
- Ensure files have correct extensions (.java, .js, .py, .cpp)
- Check file size limits (reasonable for code files)
- Verify file encoding is UTF-8

### Performance Expectations

| Language   | Type      | Cold Start | Warm Start | Notes |
|------------|-----------|------------|------------|-------|
| Python     | Zip       | 5-10s      | 2-5s       | Fast startup |
| JavaScript | Zip       | 5-10s      | 2-5s       | Node.js runtime |
| Java       | Container | 15-30s     | 5-10s      | JDK compilation |
| C++        | Container | 15-30s     | 5-10s      | GCC compilation |

## 🚀 Production Deployment

### Build for Production

```bash
# Build optimized web app
flutter build web --release

# Output will be in build/web/
```

### Environment Configuration

```dart
// For production deployment
class Config {
  static const String baseUrl = 'https://your-backend-domain.com/api';
  static const bool enableLogging = false;
  static const int requestTimeout = 60; // seconds
}
```

### Hosting Options

- **Firebase Hosting**: Easy deployment for Flutter web apps
- **AWS S3 + CloudFront**: Static hosting with CDN
- **Netlify/Vercel**: Simple deployment with CI/CD
- **GitHub Pages**: Free hosting for open source projects

## 📊 Serverless Benefits

### Cost Optimization
- **No idle costs**: Only pay for actual execution time
- **Automatic scaling**: Handles 1 to 1000+ concurrent users
- **Infrastructure-free**: No servers to manage or maintain

### Performance Advantages
- **Global availability**: AWS Lambda regions worldwide
- **Automatic updates**: AWS manages runtime updates
- **High availability**: Built-in redundancy and failover

### Development Benefits
- **Language isolation**: Each language in optimized environment
- **Version control**: Lambda functions are versioned and reproducible
- **Monitoring**: Built-in CloudWatch logging and metrics

## 🤝 Contributing

### Adding New Languages

1. **Create Lambda function** for the new language
2. **Add to backend routing** in `LambdaExecutionService`
3. **Update frontend language list** in `main.dart`
4. **Add syntax highlighting** for the new language
5. **Test execution pipeline** end-to-end

### Improving Performance

1. **Optimize Lambda cold starts** with provisioned concurrency
2. **Implement client-side caching** for repeated requests
3. **Add request batching** for multiple file executions
4. **Enhance error handling** and retry logic

## 📚 Resources

- [Flutter Web Documentation](https://flutter.dev/web)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Flutter Code Editor Package](https://pub.dev/packages/flutter_code_editor)
- [Backend API Documentation](../backend/README.md)
- [Project Architecture Overview](../PROJECT_STRUCTURE.md)

---

**🎯 Serverless Achievement**: This frontend provides a seamless coding experience powered by 100% serverless architecture, delivering automatic scaling, cost optimization, and zero infrastructure management while supporting four major programming languages.