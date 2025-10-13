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
  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case AlertType.important:
        return theme.colorScheme.errorContainer;
      case AlertType.reminder:
        return theme.colorScheme.secondaryContainer;
      case AlertType.success:
        return theme.colorScheme.surfaceContainerHighest;
      case AlertType.info:
        return theme.colorScheme.primaryContainer;
    }
  }

  /// Gets the border color based on the alert type
  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case AlertType.important:
        return theme.colorScheme.error.withValues(alpha: 0.3);
      case AlertType.reminder:
        return theme.colorScheme.secondary.withValues(alpha: 0.3);
      case AlertType.success:
        return theme.colorScheme.outline.withValues(alpha: 0.3);
      case AlertType.info:
        return theme.colorScheme.primary.withValues(alpha: 0.3);
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
  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case AlertType.important:
        return theme.colorScheme.onErrorContainer;
      case AlertType.reminder:
        return theme.colorScheme.onSecondaryContainer;
      case AlertType.success:
        return theme.colorScheme.onSurfaceVariant;
      case AlertType.info:
        return theme.colorScheme.onPrimaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: _getTextColor(context),
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
                      color: _getTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: _getTextColor(context).withValues(alpha: 0.8),
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
                color: _getTextColor(context),
                size: 20,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
