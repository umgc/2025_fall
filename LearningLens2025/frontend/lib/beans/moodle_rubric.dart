import 'package:learninglens_app/beans/learning_lens_interface.dart';
import 'package:learninglens_app/beans/moodle_rubric_criteria.dart';
import 'package:learninglens_app/beans/level.dart';

class MoodleRubric implements LearningLensInterface {
  final String title;
  final List<MoodleRubricCriteria> criteria;

  MoodleRubric({required this.title, required this.criteria});

  // Empty constructor
  MoodleRubric.empty()
      : title = 'Rubric',
        criteria = [];

  @override
  MoodleRubric fromMoodleJson(Map<String, dynamic> json) {
    var criteriaList = (json['rubric_criteria'] as List)
        .map((c) => MoodleRubricCriteria.fromMoodleJson(c))
        .toList();

    return MoodleRubric(
      title: json['criteria_title'] ?? 'Rubric',
      criteria: criteriaList,
    );
  }

  @override
  MoodleRubric fromGoogleJson(Map<String, dynamic> json) {
    final criteriaJson = json['criteria'] as List<dynamic>? ?? const [];
    final criteria = <MoodleRubricCriteria>[];

    for (var i = 0; i < criteriaJson.length; i++) {
      final criterionJson = criteriaJson[i] as Map<String, dynamic>;
      final levelsJson = criterionJson['levels'] as List<dynamic>? ?? const [];

      final levels = <Level>[];
      for (var j = 0; j < levelsJson.length; j++) {
        final levelMap = levelsJson[j] as Map<String, dynamic>;
        levels.add(Level.empty().fromGoogleJson(levelMap));
      }

      final rawCriterionId = criterionJson['criterionId'];
      criteria.add(
        MoodleRubricCriteria(
          id: rawCriterionId is int
              ? rawCriterionId
              : rawCriterionId is String
                  ? rawCriterionId.hashCode
                  : i,
          description:
              (criterionJson['description'] as String?) ?? 'Criterion ${i + 1}',
          levels: levels,
        ),
      );
    }

    return MoodleRubric(
      title: json['title'] as String? ?? json['name'] as String? ?? 'Rubric',
      criteria: criteria,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'criteria': criteria.map((c) => c.toJson()).toList(),
    };
  }
}
