import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/services/api_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

enum GameType { FLASHCARD, MATCHING, QUIZ }

/// Represents a program assessment job
/// Check the handleGET method in code_eval/index.mjs for properties
// AssignedGame model
class AssignedGame {
  final String? uuid;
  final int courseId;
  final GameType gameType;
  final String title;
  final String gameData;
  final int assignedBy;
  final DateTime assignedDate;
  LmsType lms = LocalStorageService.getSelectedClassroom();
  AssignedGameScore? score;

  AssignedGame(
      {required this.courseId,
      required this.gameType,
      required this.title,
      required this.gameData,
      required this.assignedDate,
      required this.assignedBy,
      this.uuid,
      this.score});
}

class AssignedGameScore {
  final String? uuid;
  final int studentId;
  final String? studentName;
  final int? rawCorrect;
  final int? maxScore;
  double? score;
  final String game;

  AssignedGameScore(
      {required this.studentId,
      required this.game,
      this.studentName,
      this.rawCorrect,
      this.maxScore,
      this.score,
      this.uuid});
}

class GamificationService {
  final gameUrl = LocalStorageService.getGameUrl();

  static Uri? _buildCommandUri(
    String baseUrl,
    String command, {
    Map<String, String>? params,
  }) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || parsed.scheme.isEmpty) {
      return null;
    }

    final query = <String, String>{'command': command};
    if (params != null) {
      query.addAll(params);
    }

    final path = parsed.path.isEmpty ? '/' : parsed.path;
    return parsed.replace(path: path, queryParameters: query);
  }

  Uri _requireUri(
    String command, {
    Map<String, String>? params,
  }) {
    final uri = _buildCommandUri(gameUrl, command, params: params);
    if (uri == null) {
      throw StateError(
        'Game service URL not configured. Please verify the GAME_URL setting.',
      );
    }
    return uri;
  }

  static Future<void> createDb() async {
    final baseUrl = LocalStorageService.getGameUrl();
    final uri = _buildCommandUri(baseUrl, 'createDb');

    if (uri == null) {
      developer.log(
        'Skipping gamification database init; GAME_URL is not set or invalid.',
        name: 'GamificationService',
      );
      return;
    }

    try {
      await http.post(uri);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to initialize gamification database.',
        name: 'GamificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Starts a program assessment
  Future<http.Response> createGame(AssignedGame game) async {
    final uri = _requireUri('createGame');
    return await ApiService().httpPost(uri,
        body: jsonEncode({
          'courseId': game.courseId,
          'gameType': game.gameType.index,
          'title': game.title,
          'data': game.gameData,
          'assignedBy': game.assignedBy,
          'assignedDate': game.assignedDate.toString(),
          'lmsType': game.lms.index,
        }));
  }

  Future<http.Response> assignGame(AssignedGameScore score) async {
    final uri = _requireUri('assignGame');
    return await ApiService().httpPost(uri,
        body: jsonEncode({'studentId': score.studentId, 'game': score.game}));
  }

  /// Starts a program assessment
  Future<http.Response> completeGame(
    String uuid,
    int studentId,
    double score, {
    int? rawCorrect,
    int? maxScore,
  }) async {
    final uri = _requireUri('completeGame');
    return await ApiService().httpPost(uri,
        body: jsonEncode({
          'gameId': uuid,
          'studentId': studentId,
          'score': score,
          'rawCorrect': rawCorrect,
          'maxScore': maxScore,
        }));
  }

  /// Gets code evaluations for all assignments in a course
  Future<List<AssignedGame>> getGamesForTeacher(int createdBy) async {
    final uri = _requireUri(
      'getForTeacher',
      params: {
        'createdBy': '$createdBy',
        'lmsType': '${LocalStorageService.getSelectedClassroom().index}'
      },
    );
    final response = await ApiService().httpGet(uri);

    if (response.statusCode != 200) return [];

    return parseResponse(response.body);
  }

  /// Gets code evaluations for all assignments in a course
  Future<List<AssignedGame>> getGamesForStudent(int assignedTo) async {
    final uri = _requireUri(
      'getForStudent',
      params: {
        'assignedTo': '$assignedTo',
        'lmsType': '${LocalStorageService.getSelectedClassroom().index}'
      },
    );
    final response = await ApiService().httpGet(uri);

    if (response.statusCode != 200) return [];

    return parseResponse(response.body);
  }

  List<AssignedGame> parseResponse(String responseBody) {
    final evaluations = jsonDecode(responseBody) as List<dynamic>;
    return evaluations.map((eval) {
      final rawScore = eval['score'];
      double? parsedScore;
      if (rawScore != null) {
        if (rawScore is num) {
          parsedScore = rawScore.toDouble();
        } else if (rawScore is String && rawScore.isNotEmpty) {
          parsedScore = double.tryParse(rawScore);
        }
      }

      final rawData = eval['data'];
      final gameData = rawData is String ? rawData : jsonEncode(rawData);

      final rawType = eval['game_type'];
      GameType type;
      if (rawType is int && rawType >= 0 && rawType < GameType.values.length) {
        type = GameType.values[rawType];
      } else {
        type = GameType.QUIZ;
      }

      return AssignedGame(
          uuid: eval['game_id'],
          courseId: int.parse(eval['course_id']),
          gameType: type,
          title: eval['title'],
          gameData: gameData,
          assignedBy: int.parse(eval['assigned_by']),
          assignedDate: DateTime.parse(eval['assigned_date']),
          score: AssignedGameScore(
              studentId: int.parse(eval['student_id']),
              studentName: eval['student_name'],
              rawCorrect: eval['raw_correct'] == null
                  ? null
                  : int.tryParse(eval['raw_correct'].toString()),
              game: eval['game_id'],
              maxScore: eval['max_score'] == null
                  ? null
                  : int.tryParse(eval['max_score'].toString()),
              score: parsedScore));
    }).toList();
  }

  Future<bool> deleteGame(String uuid) async {
    try {
      final uri = _requireUri('deleteGame');
      final response = await http.delete(uri,
          body: jsonEncode({
            'gameId': uuid,
          }));

      return response.statusCode == 200;
    } catch (ex) {
      return false;
    }
  }
}
