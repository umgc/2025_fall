// lib/features/code_execution/providers/execution_provider.dart - Updated with better error handling
import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/app_config.dart';
import '../models/execution_request.dart';
import '../models/execution_result.dart';
import '../models/code_analysis.dart';

class ExecutionProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  ExecutionResult? _lastResult;
  bool _isExecuting = false;
  String? _error;
  Map<String, dynamic>? _strategies;
  Map<String, dynamic>? _healthStatus;

  ExecutionProvider({
    String? backendUrl,
    Map<String, String>? authHeaders,
  }) : _apiService = ApiService(
          baseUrl: backendUrl,
          authHeaders: authHeaders,
        );

  // Getters
  ExecutionResult? get lastResult => _lastResult;
  bool get isExecuting => _isExecuting;
  String? get error => _error;
  Map<String, dynamic>? get availableStrategies => _strategies;
  Map<String, dynamic>? get healthStatus => _healthStatus;
  bool get hasError => _error != null;
  bool get hasResult => _lastResult != null;

  // Execute single code submission
  Future<ExecutionResult> executeCode(ExecutionRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final requestData = request.toJson();
      final response = await _apiService.executeCode(request.language, requestData);
      
      final result = ExecutionResult.fromJson(response);
      _lastResult = result;
      
      notifyListeners();
      return result;
    } catch (e) {
      _setError('Code execution failed: $e');
      final errorResult = ExecutionResult.error(e.toString());
      _lastResult = errorResult;
      notifyListeners();
      return errorResult;
    } finally {
      _setLoading(false);
    }
  }

  // Execute multiple submissions in batch
  Future<List<ExecutionResult>> executeBatch(List<ExecutionRequest> requests) async {
    _setLoading(true);
    _clearError();

    try {
      final batchData = {
        'submissions': {
          for (int i = 0; i < requests.length; i++)
            requests[i].submissionId ?? 'submission_$i': requests[i].toJson()
        }
      };

      final response = await _apiService.executeBatch(batchData);
      
      List<ExecutionResult> results = [];
      if (response['results'] is List) {
        results = (response['results'] as List)
            .map((resultData) => ExecutionResult.fromJson(resultData))
            .toList();
      } else if (response['data'] is List) {
        results = (response['data'] as List)
            .map((resultData) => ExecutionResult.fromJson(resultData))
            .toList();
      }
      
      // Store the last result for UI
      if (results.isNotEmpty) {
        _lastResult = results.last;
      }
      
      notifyListeners();
      return results;
    } catch (e) {
      _setError('Batch execution failed: $e');
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Analyze code without executing
  Future<CodeAnalysis?> analyzeCode(ExecutionRequest request) async {
    try {
      final requestData = request.toJson();
      final response = await _apiService.analyzeCode(requestData);
      
      if (response['success'] == true && response['analysis'] != null) {
        return CodeAnalysis.fromJson(response['analysis']);
      } else if (response['data'] != null) {
        return CodeAnalysis.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      _setError('Code analysis failed: $e');
      return null;
    }
  }

  // Get available execution strategies
  Future<void> loadAvailableStrategies() async {
    try {
      final response = await _apiService.getAvailableStrategies();
      _strategies = response;
      notifyListeners();
    } catch (e) {
      // If strategies endpoint doesn't exist, create default strategies
      _strategies = {
        'available': ['automatic', 'direct', 'containerized'],
        'default': 'automatic',
        'error': 'Could not load from backend: $e'
      };
      notifyListeners();
    }
  }

  // Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await _apiService.checkExecutionHealth();
      _healthStatus = response;
      notifyListeners();
      
      // Check various possible health indicators
      if (response['overallStatus'] == 'healthy') return true;
      if (response['healthy'] == true) return true;
      if (response['status'] == 'ok') return true;
      
      return false;
    } catch (e) {
      // Fallback: try basic health check
      try {
        final basicHealth = await _apiService.checkHealth();
        _healthStatus = basicHealth;
        notifyListeners();
        return basicHealth['healthy'] == true;
      } catch (basicError) {
        _setError('Health check failed: $e');
        _healthStatus = {
          'overallStatus': 'unhealthy',
          'healthy': false,
          'error': e.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        notifyListeners();
        return false;
      }
    }
  }

  // Test specific language execution
  Future<ExecutionResult> testLanguageExecution(String language) async {
    final testRequest = ExecutionRequest.createTest(language);
    return await executeCode(testRequest);
  }

  // Clear previous results
  void clearResults() {
    _lastResult = null;
    _clearError();
    notifyListeners();
  }

  // Get execution statistics
  Map<String, dynamic> getExecutionStats() {
    if (_lastResult == null) {
      return {'hasData': false};
    }

    return {
      'hasData': true,
      'success': _lastResult!.success,
      'executionTime': _lastResult!.executionTimeMs,
      'memoryUsed': _lastResult!.memoryUsedMb ?? 0,
      'testPassed': _lastResult!.testPassed,
      'outputSimilarity': _lastResult!.outputSimilarity ?? 0,
      'usedStrategy': _lastResult!.usedStrategy ?? 'unknown',
      'detectedStrategy': _lastResult!.detectedStrategy ?? 'unknown',
    };
  }

  // Check if a language is supported
  bool isLanguageSupported(String language) {
    return AppConfig.supportedLanguages.containsKey(language.toLowerCase());
  }

  // Get supported languages
  List<String> getSupportedLanguages() {
    return AppConfig.supportedLanguages.keys.toList();
  }

  // Get language display name
  String getLanguageDisplayName(String language) {
    return AppConfig.getLanguageDisplayName(language);
  }

  // Test if backend is responsive
  Future<bool> testBackendConnection() async {
    try {
      // Try a simple health check first
      await _apiService.checkHealth();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reset provider state
  void reset() {
    _lastResult = null;
    _strategies = null;
    _healthStatus = null;
    _isExecuting = false;
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isExecuting = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    // Clean up resources
    _lastResult = null;
    _strategies = null;
    _healthStatus = null;
    super.dispose();
  }
}