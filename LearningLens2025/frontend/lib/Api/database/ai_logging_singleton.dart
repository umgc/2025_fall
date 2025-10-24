import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class AILoggingSingleton {
  static final AILoggingSingleton _singleton = AILoggingSingleton._internal();
  factory AILoggingSingleton() {
    return _singleton;
  }
  AILoggingSingleton._internal();

  Future<void> createDb() async {
    final url =
        Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=createDb");
    await http.post(url);
  }

  Future<void> clearOldDatabaseEntries() async {
    final url =
        Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=clearDb");
    await http.post(url);
  }

  Future<List<AiLog>> getLogs(
      Course course,
      Assignment? assignment,
      Participant? student,
      int lmsType,
      DateTime startDate,
      DateTime endDate) async {
    List<AiLog> list = List.empty(growable: true);
    int courseId = course.id;
    int assignmentIdParam = assignment?.id ?? -1;
    int studentIdParam = student?.id ?? -1;
    final url = Uri.parse(
        "${LocalStorageService.getAILoggingUrl()}/?command=getLogs&courseId=$courseId&assignmentId=$assignmentIdParam&studentId=$studentIdParam&lmsType=$lmsType&startDate=${getDateString(startDate)}&endDate=${getDateString(endDate)}");
    final response = await http.get(url);
    final postResponse = response.body;
    final d = jsonDecode(postResponse);
    final participants = await LmsFactory.getLmsService()
        .getCourseParticipants(courseId.toString());
    for (Map m in d) {
      Assignment a = course.essays!
          .firstWhere((a) => a.id == int.parse(m["assignment_id"]));
      Participant p =
          participants.firstWhere((p) => p.id == int.parse(m["student_id"]));
      list.add(AiLog(
          course,
          a,
          p,
          m["prompt"],
          m["response"],
          LlmType.values.elementAt(m["ai_model"]),
          m["reflection"],
          m["log_id"],
          LocalStorageService.getSelectedClassroom(),
          DateTime.parse(m["time"])));
    }
    return list;
  }

  String getDateString(DateTime date) {
    return date.toUtc().toString();
  }

  Future<String> addLog(AiLog log) async {
    final url =
        Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=addLog");
    final header = {'content-type': 'application/json'};
    final body = jsonEncode(log.toJson());

    final response = await http.post(url, headers: header, body: body);
    final postResponse = response.body;
    return postResponse.toString();
  }
}
