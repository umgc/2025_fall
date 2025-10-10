// enum for different buld setting/mode
import 'dart:convert';

import 'package:learninglens_app/beans/assignment.dart';
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

  Assignment essay;
  EssayMode mode;
  Set<EssayHelper> helpers;
  List<ChatTurn> chatLog;
  String ? finalText;

  // constructor
  EssaySession({
    required this.essay,
    this.mode = EssayMode.brainstorm,
    this.helpers = const {},
    this.chatLog = const [],
    this.finalText,
  });

  // method to convert the object to json for storage
  String toJson() => jsonEncode({
        'assignmentId': essay.id,
        'name': essay.name,
        'description': essay.description,
        'dueDate': essay.dueDate?.toIso8601String(),
        'cutoffDate': essay.cutoffDate?.toIso8601String(),
        'isDraft': essay.isDraft,
        'maxAttempts': essay.maxAttempts,
        'gradingStatus': essay.gradingStatus,
        'courseId': essay.courseId,
        'mode': mode.name,
        'helpers': helpers.map((e) => e.name).toList(),
        'chatLog': chatLog,
        'finalText': finalText,
      });
    // factory constructor to rebuild session from JSON
  factory EssaySession.fromJson(Map<String, dynamic> json) {
    return EssaySession(
      essay: Assignment(
        id: json['assignmentId'],
        name: json['name'],
        description: json['description'],
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'])
            : null,
        cutoffDate: json['cutoffDate'] != null
            ? DateTime.parse(json['cutoffDate'])
            : null,
        isDraft: json['isDraft'] ?? false,
        maxAttempts: json['maxAttempts'] ?? 0,
        gradingStatus: json['gradingStatus'] ?? 0,
        courseId: json['courseId'] ?? 0,
      ),
      mode: EssayMode.values.firstWhere((e) => e.name == json['mode']),
      helpers: (json['helpers'] as List)
          .map((h) => EssayHelper.values.firstWhere((e) => e.name == h))
          .toSet(),
      chatLog: List<ChatTurn>.from(json['chatLog']),
      finalText: json['finalText'],
    );
  }
}
