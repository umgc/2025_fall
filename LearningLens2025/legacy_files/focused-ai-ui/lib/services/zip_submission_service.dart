import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/code_file.dart';
import '../models/submission.dart';

class ZipSubmissionHandler {
  static List<CodeFile> extractFilesFromZip(Uint8List zipData) {
    final List<CodeFile> extractedFiles = [];
    
    try {
      final archive = ZipDecoder().decodeBytes(zipData);
      
      for (final file in archive.files) {
        if (file.isFile && 
            !file.name.startsWith('.') && 
            !file.name.startsWith('__MACOSX') &&
            !file.name.contains('/.')) {
          
          try {
            final content = String.fromCharCodes(file.content);
            final language = _detectLanguageFromExtension(file.name);
            
            if (language != null) {
              final codeFile = CodeFile(
                filename: _getCleanFilename(file.name),
                content: content,
                language: language,
              );
              
              extractedFiles.add(codeFile);
            }
          } catch (e) {
            // Skip file if extraction fails
            print('Failed to extract file ${file.name}: $e');
          }
        }
      }
      
      // Sort files with main files first
      extractedFiles.sort((a, b) {
        if (a.filename.toLowerCase().contains('main.java')) return -1;
        if (b.filename.toLowerCase().contains('main.java')) return 1;
        if (a.filename.toLowerCase().endsWith('.java') && 
            !b.filename.toLowerCase().endsWith('.java')) {
          return -1;
        }
        if (!a.filename.toLowerCase().endsWith('.java') && 
            b.filename.toLowerCase().endsWith('.java')) {
          return 1;
        }
        return a.filename.compareTo(b.filename);
      });
      
    } catch (e) {
      throw Exception('Failed to extract zip file: $e');
    }
    
    return extractedFiles;
  }
  
  static String? _detectLanguageFromExtension(String filename) {
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
        return null;
    }
  }
  
  static String _getCleanFilename(String fullPath) {
    final parts = fullPath.split('/');
    return parts.last;
  }
  
  static JavaProjectAnalysis analyzeJavaProject(List<CodeFile> files) {
    String? packageName;
    String? mainClass;
    List<String> classNames = [];
    bool hasMainMethod = false;
    
    for (final file in files) {
      if (file.language == 'java') {
        final packageMatch = RegExp(r'package\s+([a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)*)\s*;')
            .firstMatch(file.content);
        if (packageMatch != null && packageName == null) {
          packageName = packageMatch.group(1);
        }
        
        final classMatch = RegExp(r'(?:public\s+)?class\s+([A-Za-z][A-Za-z0-9_]*)')
            .firstMatch(file.content);
        if (classMatch != null) {
          final className = classMatch.group(1)!;
          classNames.add(className);
          
          if (file.content.contains('public static void main(String[] args)') ||
              file.content.contains('public static void main(String args[])')) {
            mainClass = className;
            hasMainMethod = true;
          }
        }
      }
    }
    
    return JavaProjectAnalysis(
      packageName: packageName,
      mainClass: mainClass,
      classNames: classNames,
      hasMainMethod: hasMainMethod,
      fileCount: files.where((f) => f.language == 'java').length,
    );
  }
  
  static Submission createSubmissionFromZip({
    required String id,
    required String assignmentId,
    required String studentId,
    required String studentName,
    required Uint8List zipData,
    required DateTime submittedAt,
    String status = 'submitted',
    String platform = 'unknown',
  }) {
    final extractedFiles = extractFilesFromZip(zipData);
    
    if (extractedFiles.isEmpty) {
      throw Exception('No supported code files found in zip archive');
    }
    
    return Submission(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: studentName,
      files: extractedFiles,
      submittedAt: submittedAt,
      status: status,
      platform: platform,
    );
  }
  
  static ValidationResult validateZipFile(Uint8List zipData) {
    try {
      final archive = ZipDecoder().decodeBytes(zipData);
      
      if (archive.files.isEmpty) {
        return ValidationResult(
          isValid: false,
          error: 'Zip file is empty',
        );
      }
      
      final codeFiles = archive.files.where((file) => 
        file.isFile && 
        _detectLanguageFromExtension(file.name) != null
      ).toList();
      
      if (codeFiles.isEmpty) {
        return ValidationResult(
          isValid: false,
          error: 'No supported code files found in zip',
        );
      }
      
      const maxFileSize = 1024 * 1024; // 1MB per file
      for (final file in codeFiles) {
        if (file.content.length > maxFileSize) {
          return ValidationResult(
            isValid: false,
            error: 'File ${file.name} is too large (max 1MB per file)',
          );
        }
      }
      
      return ValidationResult(
        isValid: true,
        fileCount: codeFiles.length,
        supportedFiles: codeFiles.map((f) => f.name).toList(),
      );
      
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid zip file: $e',
      );
    }
  }
}

class JavaProjectAnalysis {
  final String? packageName;
  final String? mainClass;
  final List<String> classNames;
  final bool hasMainMethod;
  final int fileCount;

  JavaProjectAnalysis({
    this.packageName,
    this.mainClass,
    required this.classNames,
    required this.hasMainMethod,
    required this.fileCount,
  });

  @override
  String toString() {
    return 'JavaProjectAnalysis{package: $packageName, main: $mainClass, classes: $classNames, hasMain: $hasMainMethod, files: $fileCount}';
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final int? fileCount;
  final List<String>? supportedFiles;

  ValidationResult({
    required this.isValid,
    this.error,
    this.fileCount,
    this.supportedFiles,
  });

  @override
  String toString() {
    return 'ValidationResult{isValid: $isValid, error: $error, fileCount: $fileCount, supportedFiles: $supportedFiles}';
  }
}