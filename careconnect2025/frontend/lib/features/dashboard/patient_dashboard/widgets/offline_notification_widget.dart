import 'package:flutter/material.dart';

/// Offline Notification Widget
class OfflineNotification extends StatelessWidget {
  final DateTime? lastSynced;

  const OfflineNotification({super.key, this.lastSynced});

  /// Formats the time since the last sync
  String _getTimeSinceSync() {
    if (lastSynced == null) return 'Never synced';

    final difference = DateTime.now().difference(lastSynced!);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last synced ${_getTimeSinceSync()}. Your data will sync when reconnected. The application will have limited functionality.',
                  style: TextStyle(
                    color: theme.colorScheme.onInverseSurface.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
