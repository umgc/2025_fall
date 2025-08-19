class Assignment {
  final String id;
  final String name;
  String description;
  String language;
  int timeoutSeconds;
  int maxScore;
  List<TestCase> testCases;
  DateTime? createdAt;
  String? createdBy;
  String? courseId; // 🆕 New field for course relationship
  Map<String, String>? testFiles; // 🆕 New field for test input/output files

  Assignment({
    required this.id,
    required this.name,
    this.description = '',
    required this.language,
    this.timeoutSeconds = 30,
    this.maxScore = 0,
    this.testCases = const [],
    this.createdAt,
    this.createdBy,
    this.courseId, // 🆕 Added courseId parameter
    this.testFiles, // 🆕 Added testFiles parameter
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      language: json['language'],
      timeoutSeconds: json['timeoutSeconds'] ?? 30,
      maxScore: json['maxScore'] ?? 0,
      testCases: (json['testCases'] as List<dynamic>?)
          ?.map((tc) => TestCase.fromJson(tc))
          .toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      createdBy: json['createdBy'],
      courseId: json['courseId'], // 🆕 Parse courseId from JSON
      testFiles: json['testFiles'] != null 
          ? Map<String, String>.from(json['testFiles']) 
          : null, // 🆕 Parse testFiles from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'language': language,
      'timeoutSeconds': timeoutSeconds,
      'maxScore': maxScore,
      'testCases': testCases.map((tc) => tc.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'courseId': courseId, // 🆕 Include courseId in JSON
      'testFiles': testFiles, // 🆕 Include testFiles in JSON
    };
  }

  // 🆕 Helper methods
  bool get hasTestFiles => testFiles != null && testFiles!.isNotEmpty;
  
  String? get inputFileName => testFiles?['inputFile'];
  
  String? get outputFileName => testFiles?['outputFile'];
  
  // 🆕 Create a copy with updated course
  Assignment copyWithCourse(String courseId) {
    return Assignment(
      id: id,
      name: name,
      description: description,
      language: language,
      timeoutSeconds: timeoutSeconds,
      maxScore: maxScore,
      testCases: testCases,
      createdAt: createdAt,
      createdBy: createdBy,
      courseId: courseId,
      testFiles: testFiles,
    );
  }
}

class TestCase {
  String? id;
  String name;
  String description;
  String input;
  String expectedOutput;
  int points;
  bool isVisible;
  int timeoutSeconds;

  TestCase({
    this.id,
    required this.name,
    this.description = '',
    required this.input,
    required this.expectedOutput,
    this.points = 1,
    this.isVisible = true,
    this.timeoutSeconds = 10,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      input: json['input'],
      expectedOutput: json['expectedOutput'],
      points: json['points'] ?? 1,
      isVisible: json['isVisible'] ?? true,
      timeoutSeconds: json['timeoutSeconds'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'input': input,
      'expectedOutput': expectedOutput,
      'points': points,
      'isVisible': isVisible,
      'timeoutSeconds': timeoutSeconds,
    };
  }

  // 🆕 Helper method to create a copy
  TestCase copyWith({
    String? id,
    String? name,
    String? description,
    String? input,
    String? expectedOutput,
    int? points,
    bool? isVisible,
    int? timeoutSeconds,
  }) {
    return TestCase(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      input: input ?? this.input,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      points: points ?? this.points,
      isVisible: isVisible ?? this.isVisible,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}