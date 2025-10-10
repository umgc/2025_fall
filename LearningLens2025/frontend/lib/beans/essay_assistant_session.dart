// enum for different buld setting/mode
import 'dart:convert';

import 'package:learninglens_app/beans/chatLog.dart';

enum EssayMode {
  brainstorm,
  Outline,
  revise,
}

// enum for different build helpers
enum EssayHelper {
  grammarCheck,
  spellCheck,
  generateIdeas,
  findSources
}

// class to represent an essay builder session
class EssaySession {

  final String assignmentId;
  final String courseId;
  final String studentId;
  EssayMode mode;
  Set<EssayHelper> helpers;
  List<ChatTurn> chatLog;
  String ? finalText;

  // constructor
  EssaySession({
    required this.assignmentId,
    required this.courseId,
    required this.studentId,
    this.mode = EssayMode.brainstorm,
    this.helpers = const {},
    this.chatLog = const [],
    this.finalText,
  });

  // method to convert the object to json for storage
  String toJson() => jsonEncode({
        'assignmentId': assignmentId,
        'courseId': courseId,
        'studentId': studentId,
        'mode': mode.name,
        'helpers': helpers.map((e) => e.name).toList(),
        'chatLog': chatLog,
        'finalText': finalText,
      });
    // factory constructor to rebuild session from JSON
  factory EssaySession.fromJson(Map<String, dynamic> json) {
    return EssaySession(
      assignmentId: json['assignmentId'],
      courseId: json['courseId'],
      studentId: json['studentId'],
      mode: EssayMode.values.firstWhere((e) => e.name == json['mode']),
      helpers: (json['helpers'] as List)
          .map((h) => EssayHelper.values.firstWhere((e) => e.name == h))
          .toSet(),
      chatLog: List<ChatTurn>.from(json['chatLog']),
      finalText: json['finalText'],
    );
  }
}
