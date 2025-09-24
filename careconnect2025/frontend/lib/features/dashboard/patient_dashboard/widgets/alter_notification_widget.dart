import 'package:flutter/material.dart';

/// Alert Notification enum
enum AlertType { important, reminder, success, info }

/// Alert Notification Widget
class AlertNotification extends StatelessWidget {
  final AlertType type;
  final String message;
  final VoidCallback? onDismiss;

  const AlertNotification({
    super.key,
    required this.type,
    required this.message,
    this.onDismiss,
  });

  /// Gets the background color based on the alert type
  Color _getBackgroundColor() {
    switch (type) {
      case AlertType.important:
        return Colors.red.shade50;
      case AlertType.reminder:
        return Colors.orange.shade50;
      case AlertType.success:
        return Colors.green.shade50;
      case AlertType.info:
        return Colors.blue.shade50;
    }
  }

  /// Gets the border color based on the alert type
  Color _getBorderColor() {
    switch (type) {
      case AlertType.important:
        return Colors.red.shade200;
      case AlertType.reminder:
        return Colors.orange.shade200;
      case AlertType.success:
        return Colors.green.shade200;
      case AlertType.info:
        return Colors.blue.shade200;
    }
  }

  /// Gets the title based on the alert type
  String _getTitle() {
    switch (type) {
      case AlertType.important:
        return 'Important:';
      case AlertType.reminder:
        return 'Reminder:';
      case AlertType.success:
        return 'Success:';
      case AlertType.info:
        return 'Info:';
    }
  }

  /// Gets the text color based on the alert type
  Color _getTextColor() {
    switch (type) {
      case AlertType.important:
        return Colors.red.shade900;
      case AlertType.reminder:
        return Colors.orange.shade900;
      case AlertType.success:
        return Colors.green.shade900;
      case AlertType.info:
        return Colors.blue.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: _getTextColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${_getTitle()} ',
                    style: TextStyle(
                      color: _getTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: _getTextColor().withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: _getTextColor(),
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
