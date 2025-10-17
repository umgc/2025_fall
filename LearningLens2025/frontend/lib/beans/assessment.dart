import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/quiz.dart';

class Assessment {
  final dynamic assessment; // Either an Assignment (essay) or a Quiz.
  final String type; // "essay" or "quiz"

  Assessment({required this.assessment, required this.type});

  String get name {
    if (type == "essay") {
      return (assessment as Assignment).name;
    } else {
      return (assessment as Quiz).name ?? 'Unknown Quiz';
    }
  }

  int get id {
    if (type == "essay") {
      return (assessment as Assignment).id;
    } else {
      return (assessment as Quiz).id ?? 0;
    }
  }

  DateTime? get dueDate {
    if (type == "essay") {
      return (assessment as Assignment).dueDate;
    } else {
      return (assessment as Quiz).timeClose;
    }
  }

  String get description {
    if (type == "essay") {
      return (assessment as Assignment).description;
    } else {
      return (assessment as Quiz).description ?? "";
    }
  }
}
