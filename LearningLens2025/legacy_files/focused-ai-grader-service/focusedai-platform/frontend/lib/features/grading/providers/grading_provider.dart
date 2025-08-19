// lib/features/grading/providers/grading_provider.dart - Fixed with isLoading getter
import 'package:flutter/foundation.dart';
import '../../../core/models/submission.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/app_config.dart';
import '../models/grading_request.dart';
import '../models/grading_result.dart';

class GradingProvider extends ChangeNotifier {
  final ApiService _apiService;
  final Function(Map<String, dynamic>)? onGradeSubmitted;
  
  List<Submission> _submissions = [];
  Submission? _selectedSubmission;
  GradingResult? _lastGradingResult;
  bool _isGrading = false;
  bool _isBatchGrading = false;
  bool _isLoading = false; // Added this field
  String? _error;
  final Map<String, GradingResult> _gradingCache = {};

  GradingProvider({
    String? backendUrl,
    Map<String, String>? authHeaders,
    this.onGradeSubmitted,
  }) : _apiService = ApiService(
          baseUrl: backendUrl,
          authHeaders: authHeaders,
        );

  // Getters
  List<Submission> get submissions => _submissions;
  Submission? get selectedSubmission => _selectedSubmission;
  GradingResult? get lastGradingResult => _lastGradingResult;
  bool get isGrading => _isGrading;
  bool get isBatchGrading => _isBatchGrading;
  bool get isLoading => _isLoading; // Added this getter
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasSubmissions => _submissions.isNotEmpty;
  int get submissionCount => _submissions.length;
  int get gradedSubmissionCount => _submissions.where((s) => s.grade != null).length;

  // Set submissions from parent application
  void setSubmissions(List<Submission> submissions) {
    _submissions = submissions;
    _clearError();
    notifyListeners();
  }

  // Add a single submission
  void addSubmission(Submission submission) {
    _submissions.add(submission);
    notifyListeners();
  }

  // Update a submission
  void updateSubmission(Submission updatedSubmission) {
    final index = _submissions.indexWhere((s) => s.id == updatedSubmission.id);
    if (index != -1) {
      _submissions[index] = updatedSubmission;
      if (_selectedSubmission?.id == updatedSubmission.id) {
        _selectedSubmission = updatedSubmission;
      }
      notifyListeners();
    }
  }

  // Select a submission for grading
  void selectSubmission(Submission submission) {
    _selectedSubmission = submission;
    
    // Load cached grading result if available
    if (_gradingCache.containsKey(submission.id)) {
      _lastGradingResult = _gradingCache[submission.id];
    } else {
      _lastGradingResult = null;
    }
    
    notifyListeners();
  }

  // Load submissions from API (added this method)
  Future<void> loadSubmissions(String assignmentId) async {
    _setLoading(true);
    _clearError();

    try {
      final submissionsData = await _apiService.getAssignmentSubmissions(assignmentId);
      _submissions = submissionsData.map((data) => Submission.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load submissions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Grade a single submission
  Future<GradingResult> gradeSubmission(GradingRequest request) async {
    _setGrading(true);
    _clearError();

    try {
      final requestData = request.toJson();
      final response = await _apiService.gradeSubmission(requestData);
      
      final result = GradingResult.fromJson(response);
      _lastGradingResult = result;
      
      // Cache the result
      _gradingCache[request.submissionId] = result;
      
      // Update the submission with the grade
      _updateSubmissionWithGrade(request.submissionId, result);
      
      // Notify parent application
      if (onGradeSubmitted != null) {
        onGradeSubmitted!({
          'submissionId': request.submissionId,
          'result': result.toJson(),
          'request': request.toJson(),
        });
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _setError('Grading failed: $e');
      final errorResult = GradingResult.error(e.toString());
      _lastGradingResult = errorResult;
      notifyListeners();
      return errorResult;
    } finally {
      _setGrading(false);
    }
  }

  // Grade multiple submissions in batch
  Future<List<GradingResult>> gradeBatch(List<GradingRequest> requests) async {
    _setBatchGrading(true);
    _clearError();

    try {
      final batchData = {
        'submissions': {
          for (var request in requests)
            request.submissionId: request.toJson()
        }
      };

      final response = await _apiService.gradeBatch(batchData);
      
      List<GradingResult> results = [];
      if (response['grades'] is List) {
        results = (response['grades'] as List)
            .map((gradeData) => GradingResult.fromJson(gradeData))
            .toList();
      }
      
      // Cache all results and update submissions
      for (final result in results) {
        if (result.submissionId != null) {
          _gradingCache[result.submissionId!] = result;
          _updateSubmissionWithGrade(result.submissionId!, result);
        }
      }
      
      // Store the last result for UI
      if (results.isNotEmpty) {
        _lastGradingResult = results.last;
      }
      
      // Notify parent application about batch completion
      if (onGradeSubmitted != null) {
        onGradeSubmitted!({
          'type': 'batch',
          'results': results.map((r) => r.toJson()).toList(),
          'successful': results.where((r) => r.success).length,
          'failed': results.where((r) => !r.success).length,
        });
      }
      
      notifyListeners();
      return results;
    } catch (e) {
      _setError('Batch grading failed: $e');
      notifyListeners();
      return [];
    } finally {
      _setBatchGrading(false);
    }
  }

  // Get grading result for a specific submission
  GradingResult? getGradingResult(String submissionId) {
    return _gradingCache[submissionId];
  }

  // Check if a submission has been graded
  bool isSubmissionGraded(String submissionId) {
    return _gradingCache.containsKey(submissionId);
  }

  // Get grading statistics
  Map<String, dynamic> getGradingStatistics() {
    if (_submissions.isEmpty) {
      return {'hasData': false};
    }

    final gradedCount = gradedSubmissionCount;
    final grades = _submissions
        .where((s) => s.grade != null)
        .map((s) => s.grade!.percentage)
        .toList();

    double averageGrade = 0.0;
    if (grades.isNotEmpty) {
      averageGrade = grades.reduce((a, b) => a + b) / grades.length;
    }

    // Grade distribution
    final distribution = <String, int>{
      'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0,
    };
    
    for (final grade in grades) {
      final letterGrade = AppConfig.calculateLetterGrade(grade);
      distribution[letterGrade] = (distribution[letterGrade] ?? 0) + 1;
    }

    return {
      'hasData': true,
      'totalSubmissions': _submissions.length,
      'gradedSubmissions': gradedCount,
      'ungradedSubmissions': _submissions.length - gradedCount,
      'averageGrade': averageGrade,
      'gradeDistribution': distribution,
      'passingCount': grades.where((g) => AppConfig.isPassingGrade(g)).length,
      'failingCount': grades.where((g) => !AppConfig.isPassingGrade(g)).length,
    };
  }

  // Clear all grading data
  void clearGradingData() {
    _lastGradingResult = null;
    _gradingCache.clear();
    _clearError();
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _submissions = [];
    _selectedSubmission = null;
    _lastGradingResult = null;
    _gradingCache.clear();
    _isGrading = false;
    _isBatchGrading = false;
    _isLoading = false; // Reset loading state
    _clearError();
    notifyListeners();
  }

  // Remove a submission
  void removeSubmission(String submissionId) {
    _submissions.removeWhere((s) => s.id == submissionId);
    _gradingCache.remove(submissionId);
    
    if (_selectedSubmission?.id == submissionId) {
      _selectedSubmission = null;
      _lastGradingResult = null;
    }
    
    notifyListeners();
  }

  // Get submissions by status
  List<Submission> getSubmissionsByStatus(String status) {
    return _submissions.where((s) => s.status == status).toList();
  }

  // Get submissions by language
  List<Submission> getSubmissionsByLanguage(String language) {
    return _submissions.where((s) => s.primaryLanguage == language).toList();
  }

  // Check grading criteria for a language
  Future<Map<String, dynamic>?> getGradingCriteria(String language, {String? strategy}) async {
    try {
      final response = await _apiService.getGradingCriteria(language, strategy: strategy);
      return response;
    } catch (e) {
      _setError('Failed to load grading criteria: $e');
      return null;
    }
  }

  // Private helper methods
  void _setGrading(bool grading) {
    _isGrading = grading;
    notifyListeners();
  }

  void _setBatchGrading(bool grading) {
    _isBatchGrading = grading;
    notifyListeners();
  }

  void _setLoading(bool loading) { // Added this method
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _updateSubmissionWithGrade(String submissionId, GradingResult result) {
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index != -1) {
      final submission = _submissions[index];
      final updatedSubmission = submission.copyWithGrade(result.toGrade());
      _submissions[index] = updatedSubmission;
      
      if (_selectedSubmission?.id == submissionId) {
        _selectedSubmission = updatedSubmission;
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _submissions = [];
    _gradingCache.clear();
    _lastGradingResult = null;
    super.dispose();
  }
}