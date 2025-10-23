import 'package:learninglens_app/beans/level.dart';

class MoodleRubricCriteria {
  final int id;
  final String description;
  final int weight;
  final List<Level> levels;

  MoodleRubricCriteria(
      {required this.id, required this.description, required this.weight, required this.levels});

  factory MoodleRubricCriteria.fromMoodleJson(Map<String, dynamic> json) {
    var levelsList = (json['levels'] as List)
        .map((l) => Level.empty().fromMoodleJson(l))
        .toList();

    return MoodleRubricCriteria(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      weight: json['weight'] ?? 0,
      levels: levelsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'weight': weight,
      'levels': levels.map((l) => l.toJson()).toList(),
    };
  }
}
