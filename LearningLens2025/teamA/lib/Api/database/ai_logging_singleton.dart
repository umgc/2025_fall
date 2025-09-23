import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:postgres/postgres.dart';

class AILoggingSingleton {
 static final AILoggingSingleton _singleton = AILoggingSingleton._internal();
 factory AILoggingSingleton() {
  return _singleton;
 }
 AILoggingSingleton._internal();

 
  Future<void> createDb() async {
    final url = Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=createDb");
    final response = await http.post(url);
    print(response.body);
  }

  Future<List<AiLog>> getLogs(int courseId, int? assignmentId, int? studentId, int lmsType) async {
    List<AiLog> list = List.empty(growable: true);
    int assignmentIdParam = assignmentId ?? -1;
    int studentIdParam = studentId ?? -1;
    final url = Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=getLogs&courseId=$courseId&assignmentId=$assignmentIdParam&studentId=$studentIdParam&lmsType=$lmsType");
    final response = await http.get(url);
    final postResponse = response.body;
    JSArray d = jsonDecode(postResponse);
    List l = d.toDart;
    for (Map m in l) {
      print(m["course_id"].runtimeType);
      Course c = LmsFactory.getLmsService().courses!.firstWhere((c) => c.id == int.parse(m["course_id"]));
      Assignment a = c.essays!.firstWhere((a) => a.id == int.parse(m["assignment_id"]));
      Participant p = (await LmsFactory.getLmsService().getCourseParticipants(courseId.toString())).firstWhere((p) => p.id == int.parse(m["student_id"]));
      list.add(AiLog(c, a, p, m["prompt"], m["response"], LlmType.values.elementAt(m["ai_model"]), m["log_id"], m["reflection"], LmsType.values.elementAt(m["lms_service"]), DateTime.parse(m["time"])));
    }
    list.forEach(print);
    return list;
  }

  Future<String> addLog(AiLog log) async {
    final url = Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=addLog");
    final header = {'content-type': 'application/json'};
    final body = jsonEncode(log.toJson());

    final response = await http.post(url, headers : header, body: body);
    final postResponse = response.body;
    return postResponse.toString();
  }
}
