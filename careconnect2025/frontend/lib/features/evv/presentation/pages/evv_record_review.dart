import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../services/evv_service.dart';

class EvvRecordReviewPage extends StatefulWidget {
  const EvvRecordReviewPage({super.key});

  @override
  State<EvvRecordReviewPage> createState() => _EvvRecordReviewPageState();
}

class _EvvRecordReviewPageState extends State<EvvRecordReviewPage> {
  final EvvService _evvService = EvvService();
  bool _isLoading = true;
  List<EvvRecord> _pendingRecords = [];
  String _selectedStatus = 'PENDING_REVIEW';

  @override
  void initState() {
    super.initState();
    _loadPendingRecords();
  }

  Future<void> _loadPendingRecords() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null) return;

      // Call the simpler backend API to get records by status
      final records = await _evvService.getRecordsByStatus(_selectedStatus);
      
      setState(() {
        _pendingRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
      }
    }
  }

  Future<void> _reviewRecord(EvvRecord record, bool approve, String? comment) async {
    try {
      await _evvService.reviewRecord(
        recordId: record.id,
        approve: approve,
        comment: comment,
      );

      setState(() {
        _pendingRecords.remove(record);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Record approved' : 'Record returned for review'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reviewing record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReviewDialog(EvvRecord record) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review EVV Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecordDetails(record),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Review Comment (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewRecord(record, false, commentController.text.trim());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Return for Review'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reviewRecord(record, true, commentController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordDetails(EvvRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Service Type', record.serviceType),
            _buildDetailRow('Individual', record.individualName),
            _buildDetailRow('Date', _formatDate(record.dateOfService)),
            _buildDetailRow('Time In', _formatTime(record.timeIn)),
            _buildDetailRow('Time Out', _formatTime(record.timeOut)),
            _buildDetailRow('Location', '${record.locationLat?.toStringAsFixed(4)}, ${record.locationLng?.toStringAsFixed(4)}'),
            _buildDetailRow('State', record.stateCode),
            _buildDetailRow('Status', record.status),
            if (record.isOffline)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review EVV Records'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter by Status:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PENDING_REVIEW', child: Text('Pending Review')),
                      DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                      _loadPendingRecords();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Records List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No records to review',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'All records have been reviewed',
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
                        itemCount: _pendingRecords.length,
                        itemBuilder: (context, index) {
                          final record = _pendingRecords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(record.status),
                                child: Icon(
                                  _getStatusIcon(record.status),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                record.individualName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${record.serviceType} - ${_formatDate(record.dateOfService)}'),
                                  Text('${_formatTime(record.timeIn)} - ${_formatTime(record.timeOut)}'),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(record.status).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          record.status,
                                          style: TextStyle(
                                            color: _getStatusColor(record.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (record.isOffline) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'OFFLINE',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showReviewDialog(record),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING_REVIEW':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'SUBMITTED':
        return Colors.green;
      case 'FAILED_SUBMISSION':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING_REVIEW':
        return Icons.pending;
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'SUBMITTED':
        return Icons.send;
      case 'FAILED_SUBMISSION':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _evvService.dispose();
    super.dispose();
  }
}
