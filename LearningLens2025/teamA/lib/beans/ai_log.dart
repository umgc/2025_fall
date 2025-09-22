import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:xml/xml.dart';
import 'package:learninglens_app/beans/xml_consts.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

// A AI log entry.
class AiLog {
  final Assignment assignment; // Multiple choice text - required
  final Course course; // Point value from 0 (incorrect) to 100 (correct) - required
  final Participant student; // Feedback for the choice - optional
  final String prompt;
  final String response;
  final String reflection;
  final LlmType model;
  LmsType lms = LocalStorageService.getSelectedClassroom();
  DateTime created = DateTime.timestamp();

  // Simple constructor. Feedback param is optional.
  AiLog(this.course, this.assignment, this.student, this.prompt, this.response, this.model, [this.reflection = "", LmsType? lms, DateTime? created]) {
    if (lms != null) {
      this.lms = lms;
    }
    if (created != null) {
      this.created = created;
    }
  }

  //AiLog(Map<String, dynamic>)

  Map<String, dynamic> toJson() {
    return {
      'courseId': course.id,
      'assignmentId': assignment.id,
      'studentId': student.id,
      'prompt' : prompt,
      'response' : response,
      'reflection' : reflection,
      'model' : model.index,
      'lms' : lms.index
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}