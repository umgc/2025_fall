import '../../../core/models/code_file.dart';
import '../../../core/config/app_config.dart';

class ExecutionRequest {
  final String language;
  final List<CodeFile> files;
  final String testInput;
  final String expectedOutput;
  final String? submissionId;
  final String? assignmentId;
  final String? forceStrategy;
  final int timeoutMs;
  final int maxMemoryMb;
  final Map<String, dynamic>? metadata;

  ExecutionRequest({
    required this.language,
    required this.files,
    this.testInput = '',
    this.expectedOutput = '',
    this.submissionId,
    this.assignmentId,
    this.forceStrategy,
    int? timeoutMs,
    int? maxMemoryMb,
    this.metadata,
  }) : timeoutMs = timeoutMs ?? AppConfig.getDefaultTimeoutMs(),
       maxMemoryMb = maxMemoryMb ?? AppConfig.getDefaultMaxMemoryMb();

  factory ExecutionRequest.fromJson(Map<String, dynamic> json) {
    return ExecutionRequest(
      language: json['language'] ?? '',
      files: (json['files'] as List<dynamic>?)
          ?.map((f) => CodeFile.fromJson(f))
          .toList() ?? [],
      testInput: json['testInput'] ?? json['input'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '',
      submissionId: json['submissionId'],
      assignmentId: json['assignmentId'],
      forceStrategy: json['forceStrategy'],
      timeoutMs: json['timeoutMs'],
      maxMemoryMb: json['maxMemoryMb'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'files': files.map((f) => f.toJson()).toList(),
      'testInput': testInput,
      'input': testInput, // For backend compatibility
      'expectedOutput': expectedOutput,
      if (submissionId != null) 'submissionId': submissionId,
      if (assignmentId != null) 'assignmentId': assignmentId,
      if (forceStrategy != null) 'forceStrategy': forceStrategy,
      'timeoutMs': timeoutMs,
      'maxMemoryMb': maxMemoryMb,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Factory method for creating test requests
  factory ExecutionRequest.createTest(String language) {
    final testCode = _getTestCode(language);
    return ExecutionRequest(
      language: language,
      files: [testCode],
      testInput: '',
      expectedOutput: 'Hello, World!',
    );
  }

  static CodeFile _getTestCode(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return CodeFile(
          filename: 'HelloWorld.java',
          content: '''
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
''',
          language: 'java',
        );
      case 'python':
        return CodeFile(
          filename: 'main.py',
          content: 'print("Hello, World!")',
          language: 'python',
        );
      case 'javascript':
        return CodeFile(
          filename: 'main.js',
          content: 'console.log("Hello, World!");',
          language: 'javascript',
        );
      case 'cpp':
        return CodeFile(
          filename: 'main.cpp',
          content: '''
#include <iostream>
int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
''',
          language: 'cpp',
        );
      default:
        return CodeFile(
          filename: 'main.txt',
          content: 'Hello, World!',
          language: language,
        );
    }
  }

  ExecutionRequest copyWith({
    String? language,
    List<CodeFile>? files,
    String? testInput,
    String? expectedOutput,
    String? submissionId,
    String? assignmentId,
    String? forceStrategy,
    int? timeoutMs,
    int? maxMemoryMb,
    Map<String, dynamic>? metadata,
  }) {
    return ExecutionRequest(
      language: language ?? this.language,
      files: files ?? this.files,
      testInput: testInput ?? this.testInput,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      submissionId: submissionId ?? this.submissionId,
      assignmentId: assignmentId ?? this.assignmentId,
      forceStrategy: forceStrategy ?? this.forceStrategy,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      maxMemoryMb: maxMemoryMb ?? this.maxMemoryMb,
      metadata: metadata ?? this.metadata,
    );
  }
}