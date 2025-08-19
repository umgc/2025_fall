// lib/core/services/api_service.dart - Clean version for new architecture
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String? baseUrl;
  final Map<String, String>? authHeaders;
  
  // Default to localhost if no URL provided
  String get _baseUrl => baseUrl ?? 'http://localhost:8080';

  ApiService({
    this.baseUrl,
    this.authHeaders,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    ...?authHeaders,
  };

  // Generic HTTP methods
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Course-related methods
  Future<List<dynamic>> getCourses({String? platform}) async {
    String endpoint = '/api/courses';
    if (platform != null) {
      endpoint += '?platform=$platform';
    }
    
    final response = await get(endpoint);
    
    // Handle both wrapped and direct array responses
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic>) {
      return response['data'] ?? response['courses'] ?? [];
    } else {
      throw Exception('Unexpected response format for courses');
    }
  }

  Future<Map<String, dynamic>> getCourse(String courseId) async {
    final response = await get('/api/courses/$courseId');
    
    if (response is Map<String, dynamic>) {
      return response['data'] ?? response;
    } else {
      throw Exception('Unexpected response format for course');
    }
  }

  // Assignment-related methods
  Future<List<dynamic>> getAssignmentSubmissions(String assignmentId) async {
    final response = await get('/api/assignments/$assignmentId/submissions');
    
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic>) {
      return response['data'] ?? response['submissions'] ?? [];
    } else {
      throw Exception('Unexpected response format for submissions');
    }
  }

  // Code execution methods
  Future<Map<String, dynamic>> executeCode(String language, Map<String, dynamic> codeData) async {
    final response = await post('/api/execute/$language', codeData);
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  // Execute multiple code submissions in batch
  Future<Map<String, dynamic>> executeBatch(Map<String, dynamic> batchData) async {
    final response = await post('/api/execute/batch', batchData);
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  // Analyze code without executing
  Future<Map<String, dynamic>> analyzeCode(Map<String, dynamic> codeData) async {
    final response = await post('/api/analyze/code', codeData);
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  // Get available execution strategies
  Future<Map<String, dynamic>> getAvailableStrategies() async {
    final response = await get('/api/execute/strategies');
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  // Check execution health specifically
  Future<Map<String, dynamic>> checkExecutionHealth() async {
    try {
      final response = await get('/api/execute/health');
      return response is Map<String, dynamic> ? response : {'healthy': true, 'data': response};
    } catch (e) {
      return {
        'healthy': false, 
        'overallStatus': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  // Grading methods
  Future<Map<String, dynamic>> gradeSubmission(Map<String, dynamic> gradeData) async {
    final response = await post('/api/grade/submission', gradeData);
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  Future<Map<String, dynamic>> gradeBatch(Map<String, dynamic> batchData) async {
    final response = await post('/api/grade/batch', batchData);
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  // Get grading criteria for a language
  Future<Map<String, dynamic>> getGradingCriteria(String language, {String? strategy}) async {
    String endpoint = '/api/grading/criteria/$language';
    if (strategy != null) {
      endpoint += '?strategy=$strategy';
    }
    
    final response = await get(endpoint);
    return response is Map<String, dynamic> ? response : {'data': response};
  }

  // Health check
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await get('/api/health');
      return response is Map<String, dynamic> ? response : {'healthy': true, 'data': response};
    } catch (e) {
      return {'healthy': false, 'error': e.toString()};
    }
  }

  // Test file upload methods (for compatibility with test file widget)
  Future<Map<String, dynamic>> uploadTestFile(
    String assignmentId, 
    String fileType, 
    String filename, 
    List<int> fileBytes
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/assignments/$assignmentId/$fileType'),
      );
      
      request.headers.addAll(_headers);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final decoded = json.decode(responseData.body);
        return decoded is Map<String, dynamic> ? decoded : {'success': true, 'data': decoded};
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${responseData.body}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Response handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        // If response is not JSON, return as string
        return response.body;
      }
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}