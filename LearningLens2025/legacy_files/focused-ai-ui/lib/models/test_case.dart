class TestCase {
  final String id;
  final String name;
  final String input;
  final String expectedOutput;
  final double points;
  final bool isVisible;

  TestCase({
    required this.id,
    required this.name,
    required this.input,
    required this.expectedOutput,
    required this.points,
    this.isVisible = true,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      input: json['input'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '',
      points: (json['points'] ?? 1.0).toDouble(),
      isVisible: json['isVisible'] ?? true,
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
    };
  }
}
