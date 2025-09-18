import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'info', 'warning', 'success', 'error'
  final IconData icon;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'info',
    this.icon = Icons.notifications,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  bool _showNotificationIcon = true;

  List<NotificationItem> get notifications => _notifications;
  bool get showNotificationIcon => _showNotificationIcon;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Demo notifications
  void _initializeDemoNotifications() {
    _notifications.addAll([
      NotificationItem(
        id: '1',
        title: 'Welcome to CareConnect!',
        message: 'Your health companion is here to help you stay on track',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'success',
        icon: Icons.celebration,
      ),
      NotificationItem(
        id: '2',
        title: 'Daily Check-in Reminder',
        message: 'Don\'t forget to complete your daily health check-in',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'info',
        icon: Icons.check_circle_outline,
      ),
      NotificationItem(
        id: '3',
        title: 'Medication Reminder',
        message: 'Time to take your morning medication',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: 'warning',
        icon: Icons.medication,
      ),
      NotificationItem(
        id: '4',
        title: 'Appointment Tomorrow',
        message: 'You have an appointment with Dr. Smith at 10:00 AM',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: 'info',
        icon: Icons.calendar_today,
      ),
    ]);
  }

  void initializeNotifications() {
    _initializeDemoNotifications();
    notifyListeners();
  }

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        type: _notifications[index].type,
        icon: _notifications[index].icon,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          timestamp: _notifications[i].timestamp,
          isRead: true,
          type: _notifications[i].type,
          icon: _notifications[i].icon,
        );
      }
    }
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void toggleNotificationIcon() {
    _showNotificationIcon = !_showNotificationIcon;
    notifyListeners();
  }

  // Demo method to add a new notification
  void addDemoNotification() {
    final demoNotifications = [
      {
        'title': 'New Message',
        'message': 'You have a new message from your care team',
        'type': 'info',
        'icon': Icons.message,
      },
      {
        'title': 'Health Tip',
        'message': 'Remember to stay hydrated throughout the day',
        'type': 'success',
        'icon': Icons.water_drop,
      },
      {
        'title': 'Appointment Reminder',
        'message': 'Your appointment is in 30 minutes',
        'type': 'warning',
        'icon': Icons.schedule,
      },
      {
        'title': 'Medication Alert',
        'message': 'Time for your evening medication',
        'type': 'warning',
        'icon': Icons.medication,
      },
    ];

    final randomNotification = demoNotifications[
        DateTime.now().millisecond % demoNotifications.length];

    addNotification(NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: randomNotification['title'] as String,
      message: randomNotification['message'] as String,
      timestamp: DateTime.now(),
      type: randomNotification['type'] as String,
      icon: randomNotification['icon'] as IconData,
    ));
  }
}
