import 'package:flutter/material.dart';
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
          SnackBar(content: Text('Error loading offline models: $e')),
        );
      }
    }
  }

  Future<void> _syncOfflineData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _evvService.syncOfflineData();
      
      // Reload models after sync
      await _loadOfflineData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline models sync completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing offline models: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOfflineData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sync Status Overview
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_sync, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Sync Status',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusCard(
                                'Pending',
                                '${_offlineQueue.where((item) => item.syncStatus == 'PENDING').length}',
                                Icons.pending,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatusCard(
                                'Syncing',
                                '${_offlineQueue.where((item) => item.syncStatus == 'SYNCING').length}',
                                Icons.sync,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatusCard(
                                'Synced',
                                '${_offlineQueue.where((item) => item.syncStatus == 'SYNCED').length}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatusCard(
                                'Failed',
                                '${_offlineQueue.where((item) => item.syncStatus == 'FAILED').length}',
                                Icons.error,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _syncOfflineData,
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync All Offline Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Offline Queue List
                Expanded(
                  child: _offlineQueue.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 64,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'All models is synced',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No offline records to sync',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _offlineQueue.length,
                          itemBuilder: (context, index) {
                            final item = _offlineQueue[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(item.syncStatus),
                                  child: Icon(
                                    _getStatusIcon(item.syncStatus),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  '${item.operationType} Record #${item.recordId}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Caregiver ID: ${item.caregiverId}'),
                                    Text('Queued: ${_formatDateTime(item.queuedAt)}'),
                                    if (item.lastSyncAttempt != null)
                                      Text('Last Attempt: ${_formatDateTime(item.lastSyncAttempt!)}'),
                                    if (item.syncAttempts > 0)
                                      Text('Attempts: ${item.syncAttempts}'),
                                    if (item.lastError != null)
                                      Text(
                                        'Error: ${item.lastError}',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(item.syncStatus).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.syncStatus,
                                            style: TextStyle(
                                              color: _getStatusColor(item.syncStatus),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(item.priority).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getPriorityText(item.priority),
                                            style: TextStyle(
                                              color: _getPriorityColor(item.priority),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'retry' && item.syncStatus == 'FAILED') {
                                      _retrySync(item);
                                    } else if (value == 'details') {
                                      _showItemDetails(item);
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
                                      const PopupMenuItem(
                                        value: 'retry',
                                        child: Row(
                                          children: [
                                            Icon(Icons.refresh, size: 20, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Retry', style: TextStyle(color: Colors.blue)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _retrySync(EvvOfflineQueue item) {
    // In a real implementation, you would retry the specific item
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retry functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showItemDetails(EvvOfflineQueue item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Queue Item Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Record ID', item.recordId.toString()),
              _buildDetailRow('Operation', item.operationType),
              _buildDetailRow('Caregiver ID', item.caregiverId.toString()),
              _buildDetailRow('Device ID', item.deviceId ?? 'N/A'),
              _buildDetailRow('Queued At', _formatDateTime(item.queuedAt)),
              _buildDetailRow('Sync Status', item.syncStatus),
              _buildDetailRow('Sync Attempts', item.syncAttempts.toString()),
              if (item.lastSyncAttempt != null)
                _buildDetailRow('Last Sync Attempt', _formatDateTime(item.lastSyncAttempt!)),
              if (item.lastError != null)
                _buildDetailRow('Last Error', item.lastError!),
              _buildDetailRow('Priority', _getPriorityText(item.priority)),
              const SizedBox(height: 16),
              const Text(
                'Record Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'SYNCING':
        return Colors.blue;
      case 'SYNCED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
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

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _evvService.dispose();
    super.dispose();
  }
}
