class CodeAnalysis {
  final String language;
  final int fileCount;
  final bool hasMainMethod;
  final bool hasScanner;
  final bool hasFileIO;
  final bool hasTestAnnotations;
  final bool hasSystemOut;
  final bool isPackageExecution;
  final String? packageName;
  final String? mainClassName;
  final String recommendedStrategy;
  final String? targetMethod;
  final List<String> classNames;
  final List<String> publicMethods;
  final List<String> detectedFeatures;
  final double confidence;

  CodeAnalysis({
    required this.language,
    required this.fileCount,
    required this.hasMainMethod,
    required this.hasScanner,
    required this.hasFileIO,
    required this.hasTestAnnotations,
    required this.hasSystemOut,
    required this.isPackageExecution,
    this.packageName,
    this.mainClassName,
    required this.recommendedStrategy,
    this.targetMethod,
    this.classNames = const [],
    this.publicMethods = const [],
    this.detectedFeatures = const [],
    required this.confidence,
  });

  factory CodeAnalysis.fromJson(Map<String, dynamic> json) {
    return CodeAnalysis(
      language: json['language'] ?? '',
      fileCount: json['fileCount'] ?? 0,
      hasMainMethod: json['hasMainMethod'] ?? false,
      hasScanner: json['hasScanner'] ?? false,
      hasFileIO: json['hasFileIO'] ?? false,
      hasTestAnnotations: json['hasTestAnnotations'] ?? false,
      hasSystemOut: json['hasSystemOut'] ?? false,
      isPackageExecution: json['isPackageExecution'] ?? false,
      packageName: json['packageName'],
      mainClassName: json['mainClassName'],
      recommendedStrategy: json['recommendedStrategy'] ?? 'STDIN_STDOUT',
      targetMethod: json['targetMethod'],
      classNames: List<String>.from(json['classNames'] ?? []),
      publicMethods: List<String>.from(json['publicMethods'] ?? []),
      detectedFeatures: List<String>.from(json['detectedFeatures'] ?? []),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'fileCount': fileCount,
      'hasMainMethod': hasMainMethod,
      'hasScanner': hasScanner,
      'hasFileIO': hasFileIO,
      'hasTestAnnotations': hasTestAnnotations,
      'hasSystemOut': hasSystemOut,
      'isPackageExecution': isPackageExecution,
      if (packageName != null) 'packageName': packageName,
      if (mainClassName != null) 'mainClassName': mainClassName,
      'recommendedStrategy': recommendedStrategy,
      if (targetMethod != null) 'targetMethod': targetMethod,
      'classNames': classNames,
      'publicMethods': publicMethods,
      'detectedFeatures': detectedFeatures,
      'confidence': confidence,
    };
  }

  CodeAnalysis copyWith({
    String? language,
    int? fileCount,
    bool? hasMainMethod,
    bool? hasScanner,
    bool? hasFileIO,
    bool? hasTestAnnotations,
    bool? hasSystemOut,
    bool? isPackageExecution,
    String? packageName,
    String? mainClassName,
    String? recommendedStrategy,
    String? targetMethod,
    List<String>? classNames,
    List<String>? publicMethods,
    List<String>? detectedFeatures,
    double? confidence,
  }) {
    return CodeAnalysis(
      language: language ?? this.language,
      fileCount: fileCount ?? this.fileCount,
      hasMainMethod: hasMainMethod ?? this.hasMainMethod,
      hasScanner: hasScanner ?? this.hasScanner,
      hasFileIO: hasFileIO ?? this.hasFileIO,
      hasTestAnnotations: hasTestAnnotations ?? this.hasTestAnnotations,
      hasSystemOut: hasSystemOut ?? this.hasSystemOut,
      isPackageExecution: isPackageExecution ?? this.isPackageExecution,
      packageName: packageName ?? this.packageName,
      mainClassName: mainClassName ?? this.mainClassName,
      recommendedStrategy: recommendedStrategy ?? this.recommendedStrategy,
      targetMethod: targetMethod ?? this.targetMethod,
      classNames: classNames ?? this.classNames,
      publicMethods: publicMethods ?? this.publicMethods,
      detectedFeatures: detectedFeatures ?? this.detectedFeatures,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'CodeAnalysis(language: $language, strategy: $recommendedStrategy, confidence: ${confidence.toStringAsFixed(1)}%, features: $detectedFeatures)';
  }
}