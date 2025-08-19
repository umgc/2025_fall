import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../models/submission.dart';
import '../models/assignment.dart';

class FileProcessingService {
  
  /// Process uploaded ZIP file and extract student submissions
  Future<List<StudentSubmission>> processSubmissionsFile(
    PlatformFile file, 
    Assignment assignment
  ) async {
    if (file.bytes == null) {
      throw Exception('File bytes are null');
    }

    final List<StudentSubmission> submissions = [];
    
    try {
      if (file.extension?.toLowerCase() == 'zip') {
        // Process ZIP file
        submissions.addAll(await _processZipFile(file.bytes!, assignment));
      } else if (_isValidCodeFile(file.name, assignment.language)) {
        // Process single file
        final submission = await _processSingleFile(file, assignment);
        submissions.add(submission);
      } else {
        throw Exception('Unsupported file type. Please upload a ZIP file or a single ${assignment.language} file.');
      }

      if (submissions.isEmpty) {
        throw Exception('No valid submissions found in the uploaded file.');
      }

      return submissions;
    } catch (e) {
      throw Exception('Error processing file: $e');
    }
  }

  /// Process ZIP file containing multiple student submissions
  Future<List<StudentSubmission>> _processZipFile(
    Uint8List zipBytes, 
    Assignment assignment
  ) async {
    final List<StudentSubmission> submissions = [];
    
    try {
      // Decode the ZIP archive - Fixed import issue
      final archive = ZipDecoder().decodeBytes(zipBytes);
      
      print('📁 Processing ZIP file with ${archive.files.length} entries');
      
      for (final file in archive.files) {
        // Skip directories and system files
        if (file.isFile && !_isSystemFile(file.name)) {
          print('📄 Processing file: ${file.name}');
          
          // Check if file matches the assignment language
          if (_isValidCodeFile(file.name, assignment.language)) {
            try {
              // Extract file content
              final content = utf8.decode(file.content as List<int>);
              
              // Extract student information from path/filename
              final studentInfo = _extractStudentInfo(file.name);
              
              final submission = StudentSubmission(
                studentId: studentInfo.id,
                studentName: studentInfo.name,
                filename: studentInfo.filename,
                code: content,
                assignmentId: assignment.id,
                submittedAt: DateTime.now(),
                fileSize: file.size,
                fileExtension: _getFileExtension(file.name),
              );
              
              submissions.add(submission);
              print('✅ Added submission for ${studentInfo.name}');
            } catch (e) {
              print('⚠️ Error processing file ${file.name}: $e');
              // Continue processing other files
            }
          } else {
            print('⚠️ Skipping file (wrong language): ${file.name}');
          }
        }
      }
      
      print('📊 Successfully processed ${submissions.length} submissions');
      return submissions;
    } catch (e) {
      throw Exception('Failed to process ZIP file: $e');
    }
  }

  /// Process single code file
  Future<StudentSubmission> _processSingleFile(
    PlatformFile file, 
    Assignment assignment
  ) async {
    final content = utf8.decode(file.bytes!);
    final studentInfo = _extractStudentInfo(file.name);
    
    return StudentSubmission(
      studentId: studentInfo.id,
      studentName: studentInfo.name,
      filename: studentInfo.filename,
      code: content,
      assignmentId: assignment.id,
      submittedAt: DateTime.now(),
      fileSize: file.size,
      fileExtension: file.extension,
    );
  }

  /// Check if file is valid for the given programming language
  bool _isValidCodeFile(String filename, String language) {
    final extension = _getFileExtension(filename).toLowerCase();
    
    switch (language.toLowerCase()) {
      case 'java':
        return extension == 'java';
      case 'python':
        return extension == 'py';
      case 'javascript':
        return extension == 'js';
      case 'cpp':
        return ['cpp', 'c++', 'cxx', 'cc'].contains(extension);
      default:
        return false;
    }
  }

  /// Check if file is a system file that should be ignored
  bool _isSystemFile(String filename) {
    return filename.startsWith('__MACOSX') ||
           filename.startsWith('.DS_Store') ||
           filename.contains('Thumbs.db') ||
           filename.startsWith('.');
  }

  /// Extract file extension from filename
  String _getFileExtension(String filename) {
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < filename.length - 1) {
      return filename.substring(lastDotIndex + 1);
    }
    return '';
  }

  /// Extract student information from file path/name
  StudentInfo _extractStudentInfo(String filePath) {
    // Remove directory separators and get clean filename
    final filename = filePath.split('/').last.split('\\').last;
    final filenameWithoutExt = filename.contains('.') 
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    
    String studentName = '';
    String studentId = '';
    
    // Try to extract student info from directory structure
    final pathParts = filePath.split(RegExp(r'[/\\]'));
    if (pathParts.length > 1) {
      // Look for student folder names
      for (int i = 0; i < pathParts.length - 1; i++) {
        final part = pathParts[i];
        if (part.isNotEmpty && !part.startsWith('.') && part != 'src' && part != 'main') {
          studentName = part;
          break;
        }
      }
    }
    
    // If no student name from path, try filename
    if (studentName.isEmpty) {
      // Handle different naming conventions:
      // "StudentName_Assignment.java"
      // "Assignment_StudentName.java"
      // "LastFirst_Assignment.java"
      if (filenameWithoutExt.contains('_')) {
        final parts = filenameWithoutExt.split('_');
        if (parts.length >= 2) {
          // Try both orderings
          final possibleName1 = parts[0];
          final possibleName2 = parts[1];
          
          // Use the part that looks more like a name (has letters)
          if (RegExp(r'^[A-Za-z]+').hasMatch(possibleName1)) {
            studentName = possibleName1;
          } else if (RegExp(r'^[A-Za-z]+').hasMatch(possibleName2)) {
            studentName = possibleName2;
          } else {
            studentName = possibleName1; // Fallback to first part
          }
        }
      } else {
        studentName = filenameWithoutExt;
      }
    }
    
    // Generate student ID from name
    if (studentName.isNotEmpty) {
      studentId = _generateStudentId(studentName);
    } else {
      studentName = 'Unknown_${DateTime.now().millisecondsSinceEpoch}';
      studentId = _generateStudentId(studentName);
    }
    
    return StudentInfo(
      id: studentId,
      name: _cleanStudentName(studentName),
      filename: filename,
    );
  }

  /// Generate a student ID from the student name
  String _generateStudentId(String name) {
    final cleanName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final hash = cleanName.hashCode.abs() % 10000;
    return '${cleanName}_$hash';
  }

  /// Clean student name for display
  String _cleanStudentName(String name) {
    // Remove common suffixes and clean up
    String cleaned = name
        .replaceAll(RegExp(r'[_\-\.]'), ' ')
        .trim();
    
    // Capitalize words
    return cleaned.split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Validate submissions against assignment requirements
  List<String> validateSubmissions(
    List<StudentSubmission> submissions, 
    Assignment assignment
  ) {
    final List<String> warnings = [];
    
    // Check for duplicate student names/IDs
    final seenStudents = <String>{};
    for (final submission in submissions) {
      if (seenStudents.contains(submission.studentId)) {
        warnings.add('Duplicate submission found for student: ${submission.studentName}');
      }
      seenStudents.add(submission.studentId);
    }
    
    // Check file sizes
    for (final submission in submissions) {
      if (submission.fileSize != null && submission.fileSize! > 1024 * 1024) { // 1MB
        warnings.add('Large file detected for ${submission.studentName}: ${(submission.fileSize! / 1024).round()}KB');
      }
    }
    
    // Check for empty files
    for (final submission in submissions) {
      if (submission.code.trim().isEmpty) {
        warnings.add('Empty or whitespace-only file for ${submission.studentName}');
      }
    }
    
    return warnings;
  }
}

class StudentInfo {
  final String id;
  final String name;
  final String filename;
  
  StudentInfo({
    required this.id,
    required this.name,
    required this.filename,
  });
}