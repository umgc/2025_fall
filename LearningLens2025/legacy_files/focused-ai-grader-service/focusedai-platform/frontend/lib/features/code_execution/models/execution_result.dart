class ExecutionResult {
  final bool success;
  final String output;
  final String error;
  final int executionTimeMs;
  final int memoryUsedMb;
  final int exitCode;
  final bool testPassed;
  final double outputSimilarity;
  final String? usedStrategy;
  final String? detectedStrategy;
  final Map<String, dynamic>? codeAnalysis;
  final Map<String, dynamic>? strategyResults;
  final String? submissionId;
  final DateTime timestamp;

  ExecutionResult({
    required this.success,
    required this.output,
    required this.error,
    required this.executionTimeMs,
    required this.memoryUsedMb,
    required this.exitCode,
    required this.testPassed,
    required this.outputSimilarity,
    this.usedStrategy,
    this.detectedStrategy,
    this.codeAnalysis,
    this.strategyResults,
    this.submissionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      success: json['success'] ?? false,
      output: json['output'] ?? '',
      error: json['error'] ?? '',
      executionTimeMs: json['executionTimeMs'] ?? json['executionTime'] ?? 0,
      memoryUsedMb: json['memoryUsedMb'] ?? 0,
      exitCode: json['exitCode'] ?? 0,
      testPassed: json['testPassed'] ?? false,
      outputSimilarity: (json['outputSimilarity'] ?? 0).toDouble(),
      usedStrategy: json['usedStrategy'],
      detectedStrategy: json['detectedStrategy'],
      codeAnalysis: json['codeAnalysis'],
      strategyResults: json['strategyResults'],
      submissionId: json['submissionId'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'output': output,
      'error': error,
      'executionTimeMs': executionTimeMs,
      'memoryUsedMb': memoryUsedMb,
      'exitCode': exitCode,
      'testPassed': testPassed,
      'outputSimilarity': outputSimilarity,
      if (usedStrategy != null) 'usedStrategy': usedStrategy,
      if (detectedStrategy != null) 'detectedStrategy': detectedStrategy,
      if (codeAnalysis != null) 'codeAnalysis': codeAnalysis,
      if (strategyResults != null) 'strategyResults': strategyResults,
      if (submissionId != null) 'submissionId': submissionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ExecutionResult.error(String errorMessage) {
    return ExecutionResult(
      success: false,
      output: '',
      error: errorMessage,
      executionTimeMs: 0,
      memoryUsedMb: 0,
      exitCode: -1,
      testPassed: false,
      outputSimilarity: 0.0,
    );
  }

  factory ExecutionResult.success(String output, int executionTime) {
    return ExecutionResult(
      success: true,
      output: output,
      error: '',
      executionTimeMs: executionTime,
      memoryUsedMb: 0,
      exitCode: 0,
      testPassed: true,
      outputSimilarity: 100.0,
    );
  }

  ExecutionResult copyWith({
    bool? success,
    String? output,
    String? error,
    int? executionTimeMs,
    int? memoryUsedMb,
    int? exitCode,
    bool? testPassed,
    double? outputSimilarity,
    String? usedStrategy,
    String? detectedStrategy,
    Map<String, dynamic>? codeAnalysis,
    Map<String, dynamic>? strategyResults,
    String? submissionId,
    DateTime? timestamp,
  }) {
    return ExecutionResult(
      success: success ?? this.success,
      output: output ?? this.output,
      error: error ?? this.error,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      memoryUsedMb: memoryUsedMb ?? this.memoryUsedMb,
      exitCode: exitCode ?? this.exitCode,
      testPassed: testPassed ?? this.testPassed,
      outputSimilarity: outputSimilarity ?? this.outputSimilarity,
      usedStrategy: usedStrategy ?? this.usedStrategy,
      detectedStrategy: detectedStrategy ?? this.detectedStrategy,
      codeAnalysis: codeAnalysis ?? this.codeAnalysis,
      strategyResults: strategyResults ?? this.strategyResults,
      submissionId: submissionId ?? this.submissionId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Helper properties
  bool get hasOutput => output.isNotEmpty;
  bool get hasError => error.isNotEmpty;
  bool get isValidTest => testPassed && outputSimilarity >= 95.0;
  String get statusMessage {
    if (!success) return 'Execution Failed';
    if (testPassed) return 'Test Passed';
    if (outputSimilarity >= 90) return 'Close Match';
    if (outputSimilarity >= 70) return 'Partial Match';
    return 'Test Failed';
  }
}