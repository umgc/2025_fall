class TestCase {
  final String id;
  final String name;
  final String input;
  final String expectedOutput;
  final double points;
  final bool isVisible;
  final String? description;
  final int? timeoutMs;

  TestCase({
    required this.id,
    required this.name,
    required this.input,
    required this.expectedOutput,
    required this.points,
    this.isVisible = true,
    this.description,
    this.timeoutMs,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      input: json['input'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '',
      points: (json['points'] ?? 1.0).toDouble(),
      isVisible: json['isVisible'] ?? true,
      description: json['description'],
      timeoutMs: json['timeoutMs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'input': input,
      'expectedOutput': expectedOutput,
      'points': points,
      'isVisible': isVisible,
      if (description != null) 'description': description,
      if (timeoutMs != null) 'timeoutMs': timeoutMs,
    };
  }

  TestCase copyWith({
    String? id,
    String? name,
    String? input,
    String? expectedOutput,
    double? points,
    bool? isVisible,
    String? description,
    int? timeoutMs,
  }) {
    return TestCase(
      id: id ?? this.id,
      name: name ?? this.name,
      input: input ?? this.input,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      points: points ?? this.points,
      isVisible: isVisible ?? this.isVisible,
      description: description ?? this.description,
      timeoutMs: timeoutMs ?? this.timeoutMs,
    );
  }
}