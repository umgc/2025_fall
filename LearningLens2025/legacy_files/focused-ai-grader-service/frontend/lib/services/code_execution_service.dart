// lib/services/code_execution_service.dart
// ENHANCED VERSION - Adds support for test input and improved execution

import 'dart:convert';
import 'package:http/http.dart' as http;

class CodeExecutionService {
  static const String baseUrl = 'http://localhost:8080';
  
  /// Execute code via Lambda functions
  static Future<CodeExecutionResult> executeCode({
    required String language,
    required String code,
    required String filename,
    String? mainClassName,
    String? platform,
    String? assignmentId,
    String? studentId,
  }) async {
    return executeCodeWithInput(
      language: language,
      code: code,
      filename: filename,
      input: null, // No input for regular execution
      mainClassName: mainClassName,
      platform: platform,
      assignmentId: assignmentId,
      studentId: studentId,
    );
  }

  /// Execute code with test input via Lambda functions
  static Future<CodeExecutionResult> executeCodeWithInput({
    required String language,
    required String code,
    required String filename,
    String? input,
    String? mainClassName,
    String? platform,
    String? assignmentId,
    String? studentId,
  }) async {
    try {
      // Determine main class name if not provided
      mainClassName ??= _getMainClassNameFromFilename(filename);
      
      final request = CodeExecutionRequest(
        files: [
          CodeFile(
            filename: filename,
            content: code,
          ),
        ],
        mainClassName: mainClassName,
        platform: platform ?? 'focusedai',
        assignmentId: assignmentId,
        studentId: studentId,
        input: input, // Include test input
      );

      final executionType = input != null ? 'with test input' : 'standard';
      print('🚀 Executing $language code ($executionType): $filename');
      if (input != null) {
        print('📥 Test input: ${input.substring(0, input.length > 50 ? 50 : input.length)}${input.length > 50 ? "..." : ""}');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/execute/$language'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 120), // Allow time for container cold starts
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = CodeExecutionResult.fromJson(data);
        
        if (input != null) {
          print('🧪 Test execution completed: ${result.success ? "SUCCESS" : "FAILED"}');
          if (result.hasOutput) {
            print('📤 Output: ${result.output.substring(0, result.output.length > 100 ? 100 : result.output.length)}${result.output.length > 100 ? "..." : ""}');
          }
        }
        
        return result;
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Code execution error: $e');
      return CodeExecutionResult(
        success: false,
        output: '',
        error: 'Execution failed: $e',
        language: language.toUpperCase(),
        serverless: true,
        architecture: '100% Serverless',
        filename: filename,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Test if the backend is available
  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Backend not available: $e');
      return false;
    }
  }

  /// Get Lambda status information
  static Future<Map<String, dynamic>?> getLambdaStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lambda-status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Failed to get Lambda status: $e');
      return null;
    }
  }

  /// Test all Lambda functions
  static Future<Map<String, dynamic>?> testAllLambdas() async {
    try {
      print('🧪 Testing all Lambda functions...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/lambda-test'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 180)); // Longer timeout for tests
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Failed to test Lambda functions: $e');
      return null;
    }
  }

  /// Test execution with sample inputs for different languages
  static Future<Map<String, CodeExecutionResult>> testLanguagesWithInput() async {
    final results = <String, CodeExecutionResult>{};
    
    // Test cases for different languages
    final testCases = {
      'python': {
        'code': '''
name = input("Enter your name: ")
age = int(input("Enter your age: "))
print(f"Hello {name}, you are {age} years old!")
        ''',
        'input': 'John\\n25',
        'filename': 'test.py',
      },
      'java': {
        'code': '''
import java.util.Scanner;
public class Test {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.print("Enter a number: ");
        int num = scanner.nextInt();
        System.out.println("You entered: " + num);
        scanner.close();
    }
}
        ''',
        'input': '42',
        'filename': 'Test.java',
      },
      'javascript': {
        'code': '''
const readline = require('readline');
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.question('Enter your name: ', (name) => {
    console.log('Hello ' + name + '!');
    rl.close();
});
        ''',
        'input': 'Alice',
        'filename': 'test.js',
      },
    };
    
    for (final entry in testCases.entries) {
      final language = entry.key;
      final testCase = entry.value;
      
      try {
        print('🧪 Testing $language with input...');
        
        final result = await executeCodeWithInput(
          language: language,
          code: testCase['code']!,
          filename: testCase['filename']!,
          input: testCase['input']!,
          platform: 'test-suite',
        );
        
        results[language] = result;
        print('✅ $language test completed: ${result.success ? "SUCCESS" : "FAILED"}');
        
      } catch (e) {
        print('❌ $language test failed: $e');
        results[language] = CodeExecutionResult(
          success: false,
          output: '',
          error: 'Test failed: $e',
          language: language.toUpperCase(),
          serverless: true,
          architecture: '100% Serverless',
        );
      }
    }
    
    return results;
  }

  /// Helper method to determine main class name from filename
  static String _getMainClassNameFromFilename(String filename) {
    final baseName = filename.split('.').first;
    
    // For Java, capitalize the first letter
    if (filename.toLowerCase().endsWith('.java')) {
      return baseName[0].toUpperCase() + baseName.substring(1);
    }
    
    return baseName;
  }

  /// Detect programming language from filename
  static String detectLanguageFromFilename(String filename) {
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
        return 'cpp'; // Use C++ compiler for C files
      default:
        return 'python'; // Default fallback
    }
  }

  /// Validate test input format for different languages
  static String validateAndFormatInput(String input, String language) {
    // Convert literal \n to actual newlines
    String formatted = input.replaceAll('\\n', '\n');
    
    // Language-specific input validation and formatting
    switch (language.toLowerCase()) {
      case 'java':
        // Java Scanner expects input separated by whitespace or newlines
        return formatted;
      case 'python':
        // Python input() expects newline-separated inputs
        return formatted;
      case 'javascript':
        // Node.js readline expects newline-separated inputs
        return formatted;
      case 'cpp':
        // C++ cin expects whitespace-separated inputs
        return formatted;
      default:
        return formatted;
    }
  }

  /// Generate sample test cases for common programming patterns
  static Map<String, String> generateSampleTestCases(String language, String codeContent) {
    final samples = <String, String>{};
    
    // Analyze code content to suggest appropriate test cases
    final codeLower = codeContent.toLowerCase();
    
    if (codeLower.contains('calculator') || codeLower.contains('math') || codeLower.contains('+') || codeLower.contains('-')) {
      samples['Basic Math'] = '2+2';
      samples['Complex Expression'] = '10*5+3';
      samples['Division'] = '15/3';
    }
    
    if (codeLower.contains('input') || codeLower.contains('scanner') || codeLower.contains('readline')) {
      switch (language.toLowerCase()) {
        case 'python':
          samples['Simple Input'] = 'Hello World';
          samples['Multiple Inputs'] = 'John\\n25\\nStudent';
          break;
        case 'java':
          samples['Single Number'] = '42';
          samples['String Input'] = 'Hello Java';
          samples['Multiple Values'] = '10 20 30';
          break;
        case 'javascript':
          samples['Name Input'] = 'Alice';
          samples['Number Input'] = '123';
          break;
        case 'cpp':
          samples['Integer Input'] = '100';
          samples['Multiple Numbers'] = '5 10 15';
          break;
      }
    }
    
    if (codeLower.contains('array') || codeLower.contains('list') || codeLower.contains('vector')) {
      samples['Array Size + Elements'] = '5\\n1 2 3 4 5';
      samples['List Processing'] = '3\\napple\\nbanana\\ncherry';
    }
    
    if (codeLower.contains('loop') || codeLower.contains('for') || codeLower.contains('while')) {
      samples['Loop Count'] = '5';
      samples['Range Input'] = '1 10';
    }
    
    // Default samples if no patterns detected
    if (samples.isEmpty) {
      samples['Simple Test'] = 'test';
      samples['Number Test'] = '42';
      samples['Multiple Lines'] = 'line1\\nline2\\nline3';
    }
    
    return samples;
  }
}

// ============================================
// Data Models
// ============================================

class CodeFile {
  final String filename;
  final String content;

  CodeFile({
    required this.filename,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'content': content,
  };

  factory CodeFile.fromJson(Map<String, dynamic> json) => CodeFile(
    filename: json['filename'],
    content: json['content'],
  );
}

class CodeExecutionRequest {
  final List<CodeFile> files;
  final String mainClassName;
  final String? platform;
  final String? assignmentId;
  final String? studentId;
  final String? input; // 🆕 NEW: Test input support

  CodeExecutionRequest({
    required this.files,
    required this.mainClassName,
    this.platform,
    this.assignmentId,
    this.studentId,
    this.input, // 🆕 NEW: Optional test input
  });

  Map<String, dynamic> toJson() => {
    'files': files.map((f) => f.toJson()).toList(),
    'mainClassName': mainClassName,
    if (platform != null) 'platform': platform,
    if (assignmentId != null) 'assignmentId': assignmentId,
    if (studentId != null) 'studentId': studentId,
    if (input != null) 'input': input, // 🆕 NEW: Include input in request
  };
}

class CodeExecutionResult {
  final bool success;
  final String output;
  final String error;
  final String language;
  final bool serverless;
  final String architecture;
  final String? endpoint;
  final String? executionType;
  final int? executionTimeMs;
  final String? filename;
  final DateTime? timestamp;

  CodeExecutionResult({
    required this.success,
    required this.output,
    required this.error,
    required this.language,
    required this.serverless,
    required this.architecture,
    this.endpoint,
    this.executionType,
    this.executionTimeMs,
    this.filename,
    this.timestamp,
  });

  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) {
    return CodeExecutionResult(
      success: json['success'] ?? false,
      output: json['output'] ?? '',
      error: json['error'] ?? '',
      language: json['language'] ?? '',
      serverless: json['serverless'] ?? true,
      architecture: json['architecture'] ?? '',
      endpoint: json['endpoint'],
      executionType: json['executionType'],
      executionTimeMs: json['executionTimeMs'],
      filename: json['filename'],
      timestamp: json['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'output': output,
    'error': error,
    'language': language,
    'serverless': serverless,
    'architecture': architecture,
    if (endpoint != null) 'endpoint': endpoint,
    if (executionType != null) 'executionType': executionType,
    if (executionTimeMs != null) 'executionTimeMs': executionTimeMs,
    if (filename != null) 'filename': filename,
    if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch,
  };

  /// Check if there is output content
  bool get hasOutput => output.isNotEmpty;
  
  /// Check if there is error content
  bool get hasError => error.isNotEmpty;
  
  /// Get formatted execution time
  String get executionTimeFormatted {
    if (executionTimeMs == null) return 'Unknown';
    if (executionTimeMs! < 1000) {
      return '${executionTimeMs}ms';
    } else {
      return '${(executionTimeMs! / 1000).toStringAsFixed(2)}s';
    }
  }
  
  /// Get a status summary for display
  String get statusSummary {
    if (success) {
      return '✅ Execution successful';
    } else if (hasError) {
      return '❌ Execution failed: ${error.length > 50 ? error.substring(0, 50) + "..." : error}';
    } else {
      return '❌ Execution failed';
    }
  }

  /// Determine if this is a compilation error vs runtime error
  bool get isCompilationError {
    if (!hasError) return false;
    
    final errorLower = error.toLowerCase();
    return errorLower.contains('syntax') ||
           errorLower.contains('compilation') ||
           errorLower.contains('compile') ||
           errorLower.contains('syntaxerror') ||
           errorLower.contains('indentationerror') ||
           errorLower.contains('cannot find symbol') ||
           errorLower.contains('expected');
  }

  /// Determine if this is a runtime error
  bool get isRuntimeError {
    return hasError && !isCompilationError;
  }

  /// Get error category for grading purposes
  String get errorCategory {
    if (!hasError) return 'none';
    if (isCompilationError) return 'compilation';
    if (isRuntimeError) return 'runtime';
    return 'unknown';
  }

  /// Get a grade suggestion based on execution result
  double getGradeSuggestion(double maxScore) {
    if (success) {
      return maxScore; // Full points for successful execution
    } else if (isCompilationError) {
      return maxScore * 0.3; // 30% for compilation errors (syntax issues)
    } else if (isRuntimeError) {
      return maxScore * 0.5; // 50% for runtime errors (logic issues)
    } else {
      return 0.0; // No points for other failures
    }
  }

  /// Generate a detailed feedback message
  String generateFeedback(String studentName) {
    if (success) {
      return '''Great work, $studentName! 🎉

✅ Your code executed successfully!

Output:
$output

${executionTimeMs != null ? "Execution time: $executionTimeFormatted\n" : ""}
Keep up the excellent programming!''';
    } else {
      final category = errorCategory;
      String suggestions = '';
      
      if (category == 'compilation') {
        suggestions = '''
💡 Compilation Error Suggestions:
• Check your syntax carefully (parentheses, brackets, semicolons)
• Verify variable names and spelling
• Ensure proper indentation (especially in Python)
• Look for missing imports or declarations''';
      } else if (category == 'runtime') {
        suggestions = '''
💡 Runtime Error Suggestions:
• Check for division by zero
• Verify array/list bounds
• Ensure variables are initialized before use
• Test with different input values''';
      } else {
        suggestions = '''
💡 General Suggestions:
• Review the error message carefully
• Test your code with simple inputs first
• Break down complex problems into smaller parts
• Ask for help if you're stuck!''';
      }
      
      return '''Hi $studentName,

❌ Your code encountered a ${category == 'compilation' ? 'compilation' : 'runtime'} issue.

Error Details:
$error

$suggestions

Don't give up - debugging is part of learning! 🚀''';
    }
  }

  @override
  String toString() {
    return 'CodeExecutionResult{'
        'success: $success, '
        'language: $language, '
        'output: ${output.length} chars, '
        'error: ${error.length} chars, '
        'executionTime: $executionTimeFormatted, '
        'category: $errorCategory'
        '}';
  }
}