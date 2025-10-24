import 'dart:convert';

import 'package:learninglens_app/Views/essay_assistant.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/chatLog.dart';

// class to represent an essay builder session
class EssaySession {
  Assignment essay;
  String id;
  AiMode mode;
  final List<ChatTurn> chatLog;
  String? finalText;
  String? notesText;
  List<dynamic>? draftDeltaOps; // Quill delta for essay draft
  List<dynamic>? notesDeltaOps; // Quill delta for notes

  // constructor
  EssaySession({
    required this.essay,
    String? id,
    this.mode = AiMode.brainstorm,
    List<ChatTurn>? chatLog,
    String? finalText,
    String? notesText,
    this.draftDeltaOps,
    this.notesDeltaOps,
  })  : id = id ?? essay.id.toString(),
        chatLog = List<ChatTurn>.from(chatLog ?? const []);

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
        'chatLog': chatLog.map((turn) => turn.toJson()).toList(),
        'status': EssayStatus.notStarted,
        'finalText': finalText,
        'notesText': notesText,
        'draftDeltaOps': draftDeltaOps,
        'notesDeltaOps': notesDeltaOps,
      });
  // factory constructor to rebuild session from JSON
  factory EssaySession.fromJson(Map<String, dynamic> json) {
    return EssaySession(
      essay: Assignment(
        id: json['assignmentId'],
        name: json['name'],
        description: json['description'],
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        cutoffDate: json['cutoffDate'] != null
            ? DateTime.parse(json['cutoffDate'])
            : null,
        isDraft: json['isDraft'] ?? false,
        maxAttempts: json['maxAttempts'] ?? 0,
        gradingStatus: json['gradingStatus'] ?? 0,
        courseId: json['courseId'] ?? 0,
      ),
      mode: AiMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => AiMode.brainstorm,
      ),
      chatLog: (json['chatLog'] as List?)
              ?.map((e) => ChatTurn.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      draftDeltaOps: json['draftDeltaOps'],
      notesDeltaOps: json['notesDeltaOps'],
    );
  }
}
