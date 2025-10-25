import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

// A AI log entry.
class AiLog {
  final Assignment assignment;
  final Course course;
  final Participant student;
  final String prompt;
  final String response;
  final String reflection;
  final LlmType model;
  final String uuid;
  LmsType lms = LocalStorageService.getSelectedClassroom();
  DateTime created = DateTime.timestamp();

  // Simple constructor. Feedback param is optional.
  AiLog(this.course, this.assignment, this.student, this.prompt, this.response,
      this.model,
      [this.reflection = "", this.uuid = "", LmsType? lms, DateTime? created]) {
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
      'prompt': prompt,
      'response': response,
      'reflection': reflection,
      'model': model.index,
      'lms': lms.index
    };
  }

  Comparable getValueForColumn(int column) {
    switch (column) {
      case 0:
        return student.fullname;
      case 1:
        return assignment.name;
      case 2:
        return course.fullName;
      case 3:
        return prompt;
      case 4:
        return response;
      case 5:
        return reflection;
      case 6:
        return model.displayName;
      case 7:
        return created;
      default:
        return "";
    }
  }

  static bool isMarkdown(int column) {
    if (column == 4 || column == 5) {
      return true;
    }
    return false;
  }

  String getStringForColumn(int column) {
    if (column == 7) {
      return DateFormat.yMd().add_jms().format(created.toLocal());
    } else {
      return getValueForColumn(column).toString();
    }
  }

  @override
  String toString() {
    return toJson().toString();
  }

  static String getHeaderForColumn(int column) {
    switch (column) {
      case 0:
        return "Student";
      case 1:
        return "Assignment";
      case 2:
        return "Course";
      case 3:
        return "Prompt";
      case 4:
        return "Response";
      case 5:
        return "Reflection";
      case 6:
        return "AI Model";
      case 7:
        return "Created (Local)";
      default:
        return "";
    }
  }
}
