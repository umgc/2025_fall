class QuestionStats {
  final int id;
  final String questionType;
  final String questionText;
  final int numCorrect;
  final int numIncorrect;
  final int numPartial;
  final int totalAttempts;

  QuestionStats({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.numCorrect,
    required this.numIncorrect,
    required this.numPartial,
    required this.totalAttempts,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) => QuestionStats(
        id: json['id'],
        questionType: json['questionType'],
        questionText: json['questionText'],
        numCorrect: json['numCorrect'],
        numIncorrect: json['numIncorrect'],
        numPartial: json['numPartial'],
        totalAttempts: json['totalAttempts'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionType': questionType,
        'questionText': questionText,
        'numCorrect': numCorrect,
        'numIncorrect': numIncorrect,
        'numPartial': numPartial,
        'totalAttempts': totalAttempts,
      };
}