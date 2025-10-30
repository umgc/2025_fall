import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

enum GameType {
  FLASHCARD,
  MATCHING,
  QUIZ
}

/// Represents a program assessment job
/// Check the handleGET method in code_eval/index.mjs for properties
// AssignedGame model
class AssignedGame {
  final String? uuid;
  final int studentId;
  final int courseId;
  final GameType gameType;
  final String title;
  final String gameData;
  final int assignedBy;
  final DateTime assignedDate;
  final String? studentName;
  double? score;

  AssignedGame({
    required this.studentId,
    required this.courseId,
    required this.gameType,
    required this.title,
    required this.gameData,
    required this.assignedDate,
    required this.assignedBy,
    this.studentName,
    this.score,
    this.uuid
  });
}

class GamificationService {
  final gameUrl = LocalStorageService.getGameUrl();

  static Future<void> createDb() async {
    final url =
        Uri.parse("${LocalStorageService.getGameUrl()}/?command=createDb");
    await http.post(url);
  }

  /// Starts a program assessment
  Future<http.Response> createGame(AssignedGame game) async {
    return await ApiService().httpPost(Uri.parse("$gameUrl/?command=createGame"),
        body: jsonEncode({
          'courseId': game.courseId,
          'studentId': game.studentId,
          'gameType': game.gameType.index,
          'title': game.title,
          'data' : game.gameData,
          'assignedBy' : game.assignedBy,
          'assignedDate': game.assignedDate.toString(),
        }));
  }

  /// Starts a program assessment
  Future<http.Response> completeGame(String uuid, double score) async {
    return await ApiService().httpPost(Uri.parse("$gameUrl/?command=completeGame"),
        body: jsonEncode({
          'gameId': uuid,
          'score': score,
        }));
  }

  /// Gets code evaluations for all assignments in a course
  Future<List<AssignedGame>> getGamesForTeacher(int createdBy) async {
    final response = await ApiService().httpGet(
      Uri.parse('$gameUrl/?command=getForTeacher&createdBy=$createdBy'),
    );

    if (response.statusCode != 200) return [];

    return parseResponse(response.body);
  }

  /// Gets code evaluations for all assignments in a course
  Future<List<AssignedGame>> getGamesForStudent(int assignedTo) async {
    final response = await ApiService().httpGet(
      Uri.parse('$gameUrl/?command=getForStudent&assignedTo=$assignedTo'),
    );

    if (response.statusCode != 200) return [];

    return parseResponse(response.body);
  }

  List<AssignedGame> parseResponse(String responseBody) {
    final evaluations = jsonDecode(responseBody) as List<dynamic>;
    return evaluations.map((eval) => AssignedGame(uuid: eval['game_id'], courseId: int.parse(eval['course_id']), studentId: int.parse(eval['student_id']), gameType: GameType.values[eval['game_type']], title: eval['title'], gameData: eval['data'], assignedBy: int.parse(eval['assigned_by']), assignedDate: DateTime.parse(eval['assigned_date']), score: eval['score'] is String ? double.tryParse(eval['score']) : null)).toList();
  }

  Future<bool> deleteGame(String uuid) async {
    try {
      final response = await http.delete(Uri.parse("$gameUrl/?command=deleteGame"),
          body: jsonEncode({
            'gameId': uuid,
          }));

      return response.statusCode == 200;
    } catch (ex) {
      return false;
    }
  }
}
