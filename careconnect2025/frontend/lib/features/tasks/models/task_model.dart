import 'package:flutter/material.dart';

import '../../notifications/models/scheduled_notification_model.dart';

class Task {
  int? id;
  int? userId; // Optional, can be null if not assigned to a user
  String name;
  String description;
  DateTime date;
  TimeOfDay? timeOfDay; // Optional, can be null if not set
  bool isComplete;
  List<ScheduledNotification>? notifications;

  //Recurrence fields
  String? frequency; // e.g., daily, weekly, monthly, yearly
  int? interval; // number of days/weeks/months between recurrences
  int? count; // number of total occurrences
  List<bool>? daysOfWeek; // e.g., [false, true, false, true, ...] for Mon/Wed
  final String? taskType; // "General" | "Lab" | "Appointment" | "custom"
  bool applyToSeries;
  int? parentTaskId;

  Task({
    this.id,
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
    this.applyToSeries = false,
    this.parentTaskId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final parsedDays = json['daysOfWeek'] != null
        ? List<bool>.from(json['daysOfWeek'])
        : null;

    return Task(
      id: json['id'],
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
      userId: json['patientId'],
      isComplete: json['isComplete'] ?? false,
      notifications: json['notifications'] != null
          ? (json['notifications'] as List)
                .map((n) => ScheduledNotification.fromJson(n))
                .toList()
          : null,
      frequency: json['frequency'],
      interval: json['interval'] ?? json['taskInterval'],
      count: json['count'] ?? json['doCount'],
      daysOfWeek: parsedDays,
      taskType: json['taskType'],
      applyToSeries: json['applyToSeries'] ?? false,
      parentTaskId: json['parentTaskId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'timeOfDay': timeOfDay != null
          ? "${timeOfDay!.hour.toString().padLeft(2, '0')}:${timeOfDay!.minute.toString().padLeft(2, '0')}"
          : null,
      'isCompleted': isComplete,
      'notifications': notifications?.map((n) => n.toJson()).toList(),
      'frequency': frequency,
      'interval': interval,
      'count': count,
      'daysOfWeek': daysOfWeek,
      'taskType': taskType ?? "general",
      'patientId': userId,
      'applyToSeries': applyToSeries,
      'parentTaskId': parentTaskId,
    };
  }

  bool isValid() {
    return name.isNotEmpty && description.isNotEmpty;
  }
}
