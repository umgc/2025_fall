import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/evv_service.dart';

class EvvOfflineSyncPage extends StatefulWidget {
  const EvvOfflineSyncPage({super.key});

  @override
  State<EvvOfflineSyncPage> createState() => _EvvOfflineSyncPageState();
}

class _EvvOfflineSyncPageState extends State<EvvOfflineSyncPage> {
  final EvvService _evvService = EvvService();
  bool _isLoading = true;
  bool _isSyncing = false;
  List<EvvOfflineQueue> _offlineQueue = [];
  List<EvvOfflineQueue> _syncStatus = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      final queue = await _evvService.getOfflineQueue();
      final status = await _evvService.getOfflineStatus();

      setState(() {
        _offlineQueue = queue;
        _syncStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading offline data: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    // Removed dash to keep it simple and avoid layout quirks
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  Future<void> _syncOfflineData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _evvService.syncOfflineData();
      await _loadOfflineData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline data sync completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing offline data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadOfflineData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOfflineData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final horizontalPadding = maxWidth < 600
                      ? 16.0
                      : maxWidth < 1024
                          ? 20.0
                          : 24.0;

                  final content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SyncOverview(
                              pending: _countWhere('PENDING'),
                              syncing: _countWhere('SYNCING'),
                              synced: _countWhere('SYNCED'),
                              failed: _countWhere('FAILED'),
                              isSyncing: _isSyncing,
                              onSyncAll: _isSyncing ? null : _syncOfflineData,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _offlineQueue.isEmpty
                                  ? _EmptyState()
                                  : _QueueList(
                                      items: _offlineQueue,
                                      statusColor: _statusColor,
                                      statusIcon: _statusIcon,
                                      priorityColor: _priorityColor,
                                      priorityText: _priorityText,
                                      onRetry: _retrySync,
                                      onDetails: _showItemDetails,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  return SafeArea(
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        overscroll: false,
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height:
                              MediaQuery.of(context).size.height - kToolbarHeight,
                          child: content,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  int _countWhere(String status) =>
      _offlineQueue.where((q) => q.syncStatus == status).length;

  void _retrySync(EvvOfflineQueue item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retry functionality would be implemented here'),
      ),
    );
  }

  void _showItemDetails(EvvOfflineQueue item) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Queue Item Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Record ID', value: item.recordId.toString()),
              _DetailRow(label: 'Operation', value: item.operationType),
              _DetailRow(
                label: 'Caregiver ID',
                value: item.caregiverId.toString(),
              ),
              _DetailRow(label: 'Device ID', value: item.deviceId ?? 'N/A'),
              _DetailRow(
                label: 'Queued At',
                value: _formatDateTime(item.queuedAt),
              ),
              _DetailRow(label: 'Sync Status', value: item.syncStatus),
              _DetailRow(
                label: 'Sync Attempts',
                value: item.syncAttempts.toString(),
              ),
              if (item.lastSyncAttempt != null)
                _DetailRow(
                  label: 'Last Sync Attempt',
                  value: _formatDateTime(item.lastSyncAttempt!),
                ),
              if (item.lastError != null)
                _DetailRow(label: 'Last Error', value: item.lastError!),
              _DetailRow(
                label: 'Priority',
                value: _priorityText(item.priority),
              ),
              const SizedBox(height: 16),
              const Text(
                'Record Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.recordData.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'PENDING':
        return scheme.tertiary;
      case 'SYNCING':
        return scheme.primary;
      case 'SYNCED':
        return scheme.secondary;
      case 'FAILED':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.pending;
      case 'SYNCING':
        return Icons.sync;
      case 'SYNCED':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _priorityColor(int priority) {
    final scheme = Theme.of(context).colorScheme;
    switch (priority) {
      case 1:
        return scheme.outline;
      case 2:
        return scheme.tertiary;
      case 3:
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  String _priorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Normal';
      case 2:
        return 'High';
      case 3:
        return 'Urgent';
      default:
        return 'Normal';
    }
  }

  @override
  void dispose() {
    _evvService.dispose();
    super.dispose();
  }
}

class _SyncOverview extends StatelessWidget {
  const _SyncOverview({
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
    required this.isSyncing,
    required this.onSyncAll,
  });

  final int pending;
  final int syncing;
  final int synced;
  final int failed;
  final bool isSyncing;
  final VoidCallback? onSyncAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final items = <_StatusItem>[
      _StatusItem(
        'Pending',
        pending,
        Icons.pending,
        Theme.of(context).colorScheme.tertiary,
      ),
      _StatusItem(
        'Syncing',
        syncing,
        Icons.sync,
        Theme.of(context).colorScheme.primary,
      ),
      _StatusItem(
        'Synced',
        synced,
        Icons.check_circle,
        Theme.of(context).colorScheme.secondary,
      ),
      _StatusItem(
        'Failed',
        failed,
        Icons.error,
        Theme.of(context).colorScheme.error,
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width < 480
                    ? 2
                    : width < 840
                        ? 4
                        : 4;

                // Increased tile height to avoid overflow on dense text/large fonts
                const tileHeight = 128.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: tileHeight,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) =>
                      _StatusCard(item: items[index]),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSyncAll,
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(isSyncing ? 'Syncing...' : 'Sync All Offline Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem(this.title, this.count, this.icon, this.color);
  final String title;
  final int count;
  final IconData icon;
  final Color color;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item});
  final _StatusItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // critical to avoid overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: item.color.withOpacity(0.15),
              foregroundColor: item.color,
              child: Icon(item.icon),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.count}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
            ),
            Text(item.title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({
    required this.items,
    required this.statusColor,
    required this.statusIcon,
    required this.priorityColor,
    required this.priorityText,
    required this.onRetry,
    required this.onDetails,
  });

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  final List<EvvOfflineQueue> items;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final Color Function(int) priorityColor;
  final String Function(int) priorityText;
  final void Function(EvvOfflineQueue) onRetry;
  final void Function(EvvOfflineQueue) onDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final stColor = statusColor(item.syncStatus);

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: stColor.withOpacity(0.15),
              foregroundColor: stColor,
              child: Icon(statusIcon(item.syncStatus)),
            ),
            title: Text(
              '${item.operationType} Record #${item.recordId}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caregiver ID: ${item.caregiverId}'),
                  Text('Queued: ${_formatDateTime(item.queuedAt)}'),
                  if (item.lastSyncAttempt != null)
                    Text(
                      'Last Attempt: ${_formatDateTime(item.lastSyncAttempt!)}',
                    ),
                  if (item.syncAttempts > 0)
                    Text('Attempts: ${item.syncAttempts}'),
                  if (item.lastError != null)
                    Text(
                      'Error: ${item.lastError}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _StatusChip(label: item.syncStatus, color: stColor),
                      _StatusChip(
                        label: priorityText(item.priority),
                        color: priorityColor(item.priority),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'retry' && item.syncStatus == 'FAILED') {
                  onRetry(item);
                } else if (value == 'details') {
                  onDetails(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 20),
                      SizedBox(width: 8),
                      Text('Details'),
                    ],
                  ),
                ),
                if (item.syncStatus == 'FAILED')
                  PopupMenuItem(
                    value: 'retry',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: scheme.primary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_done, size: 64, color: scheme.secondary),
            const SizedBox(height: 16),
            Text(
              'All data is synced',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No offline records to sync',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
