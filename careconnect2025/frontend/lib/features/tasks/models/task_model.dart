import 'dart:convert';

import 'package:flutter/material.dart';

import '../../notifications/models/notification_model.dart';

class Task {
  int id;
  int? userId; // Optional, can be null if not assigned to a user
  String name;
  String description;
  DateTime date;
  TimeOfDay? timeOfDay; // Optional, can be null if not set
  bool isComplete;
  List<Notification_dto>? notifications;

  //Recurrence fields
  String? frequency; // e.g., daily, weekly, monthly, yearly
  int? interval; // number of days/weeks/months between recurrences
  int? count; // number of total occurrences
  List<bool>? daysOfWeek; // e.g., [false, true, false, true, ...] for Mon/Wed
  final String? taskType; // "General" | "Lab" | "Appointment" | "custom"

  Task({
    required this.id,
    required this.name,
    this.description = "",
    required this.date,
    this.timeOfDay,
    this.userId,
    this.isComplete = false,
    this.notifications,
    this.frequency,
    this.interval,
    this.count,
    this.daysOfWeek,
    this.taskType,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final parsedDays = json['daysOfWeek'] != null
        ? (json['daysOfWeek'] is String
              ? List<bool>.from(jsonDecode(json['daysOfWeek']))
              : List<bool>.from(json['daysOfWeek']))
        : null;

    print("📅 Parsed daysOfWeek for ${json['name']}: $parsedDays");

    return Task(
      id: json['id'] != null ? json['id'] as int : -1,
      name: json['name'],
      description: json['description'] ?? "",
      date: DateTime.parse(json['date']),
      timeOfDay: json['timeOfDay'] != null
          ? TimeOfDay(
              hour: json['timeOfDay'] is String
                  ? int.parse(json['timeOfDay'].split(':')[0])
                  : json['timeOfDay']['hour'],
              minute: json['timeOfDay'] is String
                  ? int.parse(json['timeOfDay'].split(':')[1])
                  : json['timeOfDay']['minute'],
            )
          : null,
      userId: json['patient']?['id'],
      isComplete: json['isComplete'] ?? false,
      frequency: json['frequency'],
      interval: json['interval'] ?? json['taskInterval'],
      count: json['count'] ?? json['doCount'],
      daysOfWeek: parsedDays,
      taskType: json['taskType'],
    );
  }

  Map<String, dynamic> toJson() {
    String resolvedTaskType = taskType ?? "custom"; // Default task type
    if (daysOfWeek != null && daysOfWeek!.contains(true)) {
      resolvedTaskType = "dayOfWeek";
    } else if (frequency != null && interval != null) {
      resolvedTaskType = "frequency";
    }

    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'timeOfDay': timeOfDay != null
          ? "${timeOfDay!.hour}:${timeOfDay!.minute}"
          : null,
      'isCompleted': isComplete,
      'notifications': null,
      'frequency': frequency,
      'interval': interval,
      'count': count,
      'daysOfWeek': daysOfWeek != null ? jsonEncode(daysOfWeek) : null,
      'taskType': resolvedTaskType,
      'patientId': userId,
    };
  }

  bool isValid() {
    return name.isNotEmpty && description.isNotEmpty;
  }

  List<Task> expandOccurrences() {
    print(
      "🔍 expandOccurrences -> freq=$frequency interval=$interval count=$count",
    );
    // If not recurring, return the single task
    if (frequency == null) {
      return [this];
    }

    int safeInterval;
    switch (frequency!.toLowerCase()) {
      case "daily":
        safeInterval = (interval ?? 1).clamp(1, 365);
        break;
      case "weekly":
        safeInterval = (interval ?? 1).clamp(1, 52);
        break;
      case "monthly":
        safeInterval = (interval ?? 1).clamp(1, 12);
        break;
      case "yearly":
        safeInterval = (interval ?? 1).clamp(1, 100);
        break;
      default:
        safeInterval = 1;
    }

    int effectiveCount = (count == null || count! <= 0) ? 0 : count!;

    // Fallbacks if count not set
    if (effectiveCount <= 0) {
      switch (frequency!.toLowerCase()) {
        case "daily":
          effectiveCount = 30;
          break;
        case "weekly":
          if (daysOfWeek != null && daysOfWeek!.contains(true)) {
            effectiveCount = 12 * daysOfWeek!.where((d) => d).length;
          } else {
            effectiveCount = 12;
          }
          break;
        case "monthly":
          effectiveCount = 12;
          break;
        case "yearly":
          effectiveCount = 5;
          break;
        default:
          effectiveCount = 1;
      }
    }

    final List<Task> occurrences = [];
    DateTime current = DateTime(date.year, date.month, date.day);

    for (int i = 0; i < effectiveCount; i++) {
      occurrences.add(
        Task(
          id: id,
          name: name,
          description: description,
          date: current,
          timeOfDay: timeOfDay,
          userId: userId,
          isComplete: isComplete,
          notifications: notifications,
          frequency: frequency,
          interval: safeInterval,
          count: effectiveCount,
          daysOfWeek: daysOfWeek,
          taskType: taskType,
        ),
      );

      switch (frequency!.toLowerCase()) {
        case "daily":
          current = current.add(Duration(days: safeInterval));
          break;

        case "weekly":
          if (daysOfWeek != null && daysOfWeek!.contains(true)) {
            DateTime next = current.add(const Duration(days: 1));
            while (!daysOfWeek![next.weekday % 7]) {
              next = next.add(const Duration(days: 1));
            }
            current = next;
          } else {
            current = current.add(Duration(days: safeInterval));
          }
          break;

        case "monthly":
          final startDay = date.day; // always use original start day
          current = DateTime(current.year, current.month + 1, startDay);
          break;

        case "yearly":
          current = DateTime(current.year + 1, current.month, current.day);
          break;
      }
    }

    return occurrences;
  }
}
