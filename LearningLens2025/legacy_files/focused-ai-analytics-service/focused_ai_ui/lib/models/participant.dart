class Participant {
  final String name;
  final double score;

  Participant({
    required this.name,
    required this.score,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      name: json['name'] ?? 'Unknown', // default if null
      score: (json['score'] ?? 0).toDouble(), // default 0.0 if null
    );
  }
}