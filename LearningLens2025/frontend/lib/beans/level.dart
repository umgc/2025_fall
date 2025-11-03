import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Level implements LearningLensInterface {
  final int id;
  final String description;
  final int score;

  Level({required this.id, required this.description, required this.score});

  // Empty constructor
  Level.empty()
      : id = 0,
        description = '',
        score = 0;

  @override
  Level fromMoodleJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] ?? 0,
      description: json['definition'] ?? '',
      score: json['score'] ?? 0,
    );
  }

  @override
  Level fromGoogleJson(Map<String, dynamic> json) {
    final rawId = json['levelId'];
    final rawPoints = json['points'];

    return Level(
      id: rawId is int
          ? rawId
          : rawId is String
              ? rawId.hashCode
              : 0,
      description: (json['description'] as String?)?.trim().isNotEmpty == true
          ? (json['description'] as String).trim()
          : ((json['title'] as String?) ?? '').trim(),
      score: rawPoints is num ? rawPoints.round() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'score': score,
    };
  }
}
