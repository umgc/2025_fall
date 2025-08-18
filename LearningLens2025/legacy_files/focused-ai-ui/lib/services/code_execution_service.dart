import '../apis/code_execution_api.dart';
import '../models/code_file.dart';

class CodeExecutionService {
  final CodeExecutionApi _api = CodeExecutionApi();

  Future<Map<String, dynamic>> executeCode({
    required List<CodeFile> codeFiles,
    required String mainClassName,
    required String language,
  }) async {
    try {
      // Validate input
      if (codeFiles.isEmpty) {
        return {
          'success': false,
          'output': '',
          'error': 'No code files provided',
        };
      }

      if (mainClassName.isEmpty) {
        return {
          'success': false,
          'output': '',
          'error': 'Main class name is required',
        };
      }

      // Check if any file has content
      bool hasContent = codeFiles.any((file) => file.content.trim().isNotEmpty);
      if (!hasContent) {
        return {
          'success': false,
          'output': '',
          'error': 'All files are empty. Please add some code.',
        };
      }

      // Call the API
      final result = await _api.executeCode(
        codeFiles: codeFiles,
        mainClassName: mainClassName,
        language: language,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'output': '',
        'error': 'Service error: $e',
      };
    }
  }
}