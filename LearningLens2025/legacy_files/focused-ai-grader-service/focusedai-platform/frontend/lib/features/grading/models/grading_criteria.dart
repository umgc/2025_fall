class GradingCriteria {
  final String language;
  final String? strategy;
  final double passingThreshold;
  final double similarityWeight;
  final double executionWeight;
  final double timeoutPenalty;
  final double memoryPenalty;
  final Map<String, double> customWeights;
  final Map<String, dynamic>? metadata;

  GradingCriteria({
    required this.language,
    this.strategy,
    this.passingThreshold = 60.0,
    this.similarityWeight = 0.8,
    this.executionWeight = 0.2,
    this.timeoutPenalty = 0.1,
    this.memoryPenalty = 0.05,
    this.customWeights = const {},
    this.metadata,
  });

  factory GradingCriteria.fromJson(Map<String, dynamic> json) {
    return GradingCriteria(
      language: json['language'] ?? '',
      strategy: json['strategy'],
      passingThreshold: (json['passingThreshold'] ?? 60.0).toDouble(),
      similarityWeight: (json['similarityWeight'] ?? 0.8).toDouble(),
      executionWeight: (json['executionWeight'] ?? 0.2).toDouble(),
      timeoutPenalty: (json['timeoutPenalty'] ?? 0.1).toDouble(),
      memoryPenalty: (json['memoryPenalty'] ?? 0.05).toDouble(),
      customWeights: Map<String, double>.from(json['customWeights'] ?? {}),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      if (strategy != null) 'strategy': strategy,
      'passingThreshold': passingThreshold,
      'similarityWeight': similarityWeight,
      'executionWeight': executionWeight,
      'timeoutPenalty': timeoutPenalty,
      'memoryPenalty': memoryPenalty,
      'customWeights': customWeights,
      if (metadata != null) 'metadata': metadata,
    };
  }

  GradingCriteria copyWith({
    String? language,
    String? strategy,
    double? passingThreshold,
    double? similarityWeight,
    double? executionWeight,
    double? timeoutPenalty,
    double? memoryPenalty,
    Map<String, double>? customWeights,
    Map<String, dynamic>? metadata,
  }) {
    return GradingCriteria(
      language: language ?? this.language,
      strategy: strategy ?? this.strategy,
      passingThreshold: passingThreshold ?? this.passingThreshold,
      similarityWeight: similarityWeight ?? this.similarityWeight,
      executionWeight: executionWeight ?? this.executionWeight,
      timeoutPenalty: timeoutPenalty ?? this.timeoutPenalty,
      memoryPenalty: memoryPenalty ?? this.memoryPenalty,
      customWeights: customWeights ?? this.customWeights,
      metadata: metadata ?? this.metadata,
    );
  }
}