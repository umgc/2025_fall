// lib/models/batch_execution_result.dart
// COMPLETE FIXED VERSION - Replace your entire file with this

import '../services/code_execution_service.dart';

class BatchExecutionResult {
  final String batchId;
  final String assignmentId;
  final Map<String, CodeExecutionResult> results;
  final int totalSubmissions;
  final int successfulExecutions;
  final int failedExecutions;
  final int executionTimeMs;
  final DateTime startTime;
  final DateTime endTime;
  final String platform;

  BatchExecutionResult({
    required this.batchId,
    required this.assignmentId,
    required this.results,
    required this.totalSubmissions,
    required this.successfulExecutions,
    required this.failedExecutions,
    required this.executionTimeMs,
    required this.startTime,
    required this.endTime,
    required this.platform,
  });

  // Factory constructor from JSON (for API responses)
  factory BatchExecutionResult.fromJson(Map<String, dynamic> json) {
    final resultsMap = <String, CodeExecutionResult>{};
    
    if (json['results'] != null) {
      final results = json['results'] as Map<String, dynamic>;
      results.forEach((key, value) {
        resultsMap[key] = CodeExecutionResult.fromJson(value);
      });
    }

    return BatchExecutionResult(
      batchId: json['batchId'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      results: resultsMap,
      totalSubmissions: json['totalSubmissions'] ?? 0,
      successfulExecutions: json['successfulExecutions'] ?? 0,
      failedExecutions: json['failedExecutions'] ?? 0,
      executionTimeMs: json['executionTimeMs'] ?? 0,
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : DateTime.now(),
      platform: json['platform'] ?? '',
    );
  }

  // Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    final resultsJson = <String, dynamic>{};
    results.forEach((key, value) {
      resultsJson[key] = value.toJson();
    });

    return {
      'batchId': batchId,
      'assignmentId': assignmentId,
      'results': resultsJson,
      'totalSubmissions': totalSubmissions,
      'successfulExecutions': successfulExecutions,
      'failedExecutions': failedExecutions,
      'executionTimeMs': executionTimeMs,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'platform': platform,
    };
  }

  // ✅ CRITICAL FIX: Add the missing getResultForSubmission method
  /// Get execution result for a specific submission ID
  CodeExecutionResult? getResultForSubmission(String submissionId) {
    return results[submissionId];
  }

  // ✅ Additional utility methods
  /// Get all successful execution results
  Map<String, CodeExecutionResult> get successfulResults {
    return Map.fromEntries(
      results.entries.where((entry) => entry.value.success),
    );
  }

  /// Get all failed execution results
  Map<String, CodeExecutionResult> get failedResults {
    return Map.fromEntries(
      results.entries.where((entry) => !entry.value.success),
    );
  }

  /// Get results grouped by programming language
  Map<String, List<MapEntry<String, CodeExecutionResult>>> get resultsByLanguage {
    final grouped = <String, List<MapEntry<String, CodeExecutionResult>>>{};
    
    for (final entry in results.entries) {
      final language = entry.value.language;
      if (!grouped.containsKey(language)) {
        grouped[language] = [];
      }
      grouped[language]!.add(entry);
    }
    
    return grouped;
  }

  // Utility methods (matching your existing implementation)
  double get successRate {
    if (totalSubmissions == 0) return 0.0;
    return (successfulExecutions / totalSubmissions) * 100.0;
  }

  String get executionTimeFormatted {
    if (executionTimeMs < 1000) {
      return '${executionTimeMs}ms';
    } else if (executionTimeMs < 60000) {
      return '${(executionTimeMs / 1000).toStringAsFixed(2)}s';
    } else {
      final minutes = executionTimeMs ~/ 60000;
      final seconds = (executionTimeMs % 60000) ~/ 1000;
      return '${minutes}m ${seconds}s';
    }
  }

  String get summary {
    final batchIdShort = batchId.length > 8 ? batchId.substring(0, 8) : batchId;
    return 'Batch $batchIdShort: $successfulExecutions/$totalSubmissions successful (${successRate.toStringAsFixed(1)}%) in $executionTimeFormatted';
  }

  bool get isSuccess {
    return failedExecutions == 0 && totalSubmissions > 0;
  }

  /// Check if batch has any errors
  bool get hasErrors {
    return failedExecutions > 0;
  }

  /// Check if batch is partially successful
  bool get isPartialSuccess {
    return successfulExecutions > 0 && failedExecutions > 0;
  }

  /// Check if batch is complete (no pending executions)
  bool get isComplete {
    return (successfulExecutions + failedExecutions) == totalSubmissions;
  }

  /// Get completion percentage
  double get completionPercentage {
    if (totalSubmissions == 0) return 0.0;
    return ((successfulExecutions + failedExecutions) / totalSubmissions) * 100.0;
  }

  /// Get language distribution
  Map<String, int> get languageDistribution {
    final distribution = <String, int>{};
    
    for (final result in results.values) {
      final language = result.language;
      distribution[language] = (distribution[language] ?? 0) + 1;
    }
    
    return distribution;
  }

  @override
  String toString() {
    return 'BatchExecutionResult{'
        'batchId: $batchId, '
        'assignmentId: $assignmentId, '
        'totalSubmissions: $totalSubmissions, '
        'successfulExecutions: $successfulExecutions, '
        'failedExecutions: $failedExecutions, '
        'executionTimeMs: $executionTimeMs, '
        'successRate: ${successRate.toStringAsFixed(1)}%'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchExecutionResult && other.batchId == batchId;
  }

  @override
  int get hashCode => batchId.hashCode;

  /// Create a copy with updated values
  BatchExecutionResult copyWith({
    String? batchId,
    String? assignmentId,
    Map<String, CodeExecutionResult>? results,
    int? totalSubmissions,
    int? successfulExecutions,
    int? failedExecutions,
    int? executionTimeMs,
    DateTime? startTime,
    DateTime? endTime,
    String? platform,
  }) {
    return BatchExecutionResult(
      batchId: batchId ?? this.batchId,
      assignmentId: assignmentId ?? this.assignmentId,
      results: results ?? this.results,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      successfulExecutions: successfulExecutions ?? this.successfulExecutions,
      failedExecutions: failedExecutions ?? this.failedExecutions,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      platform: platform ?? this.platform,
    );
  }
}