import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/careconnect_theme.dart';
import '../providers/notification_provider.dart';
import 'notification_icon.dart';

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        final latestNotification = notificationProvider.notifications.first;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: CareConnectTheme.spacingM),
          child: InkWell(
            onTap: () => _showNotificationPanel(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(CareConnectTheme.spacingM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getNotificationColor(latestNotification.type),
                    _getNotificationColor(latestNotification.type).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getNotificationColor(latestNotification.type).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    latestNotification.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: CareConnectTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestNotification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: CareConnectTheme.spacingXS),
                        Text(
                          latestNotification.message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (notificationProvider.unreadCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${notificationProvider.unreadCount - 1} more',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'success':
        return CareConnectTheme.successColor;
      case 'warning':
        return CareConnectTheme.warningColor;
      case 'error':
        return CareConnectTheme.errorColor;
      default:
        return CareConnectTheme.primaryColor;
    }
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationPanel(),
    );
  }
}
