class ScheduledNotification {
  final int? id;
  final int? taskId;
  int receiverId;
  String title;
  String body;
  String? notificationType; // e.g., REMINDER, ALERT, EMERGENCY
  DateTime scheduledTime;
  DateTime? sentTime;
  String status; // PENDING, SENT, FAILED, CANCELLED
  String? messageId;
  String? errorMessage;

  ScheduledNotification({
    this.id,
    this.taskId,
    required this.receiverId,
    required this.title,
    required this.body,
    this.notificationType,
    required this.scheduledTime,
    this.sentTime,
    this.status = "PENDING",
    this.messageId,
    this.errorMessage,
  });

  // Factory constructor for JSON -> Dart object
  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'] ?? -1,
      taskId: json['taskId'],
      receiverId: json['receiverId'],
      title: json['title'],
      body: json['body'],
      notificationType: json['notificationType'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      sentTime: json['sentTime'] != null
          ? DateTime.parse(json['sentTime'])
          : null,
      status: json['status'] ?? "PENDING",
      messageId: json['messageId'],
      errorMessage: json['errorMessage'],
    );
  }

  // Dart object -> JSON (for POST requests)
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'receiverId': receiverId,
      'title': title,
      'body': body,
      'notificationType': notificationType,
      'scheduledTime': scheduledTime.toIso8601String(),
    };
  }
}
