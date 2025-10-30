import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/skeleton_frame.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_video_player.dart';
import 'skeleton_viewer_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  List<Alert> _alerts = [];
  bool _isLoading = true;
  String? _error;
  Alert? _selectedAlert;
  List<SkeletonFrame> _skeletonFrames = []; // Changed to list for video playback
  Map<String, dynamic>? _skeletonTiming; // Store timing data for video playback

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alerts = await _apiService.getAlerts(limit: 50);
      
      // DEBUG: If no alerts found, try loading a test alert by ID
      if (alerts.isEmpty) {
        print('No alerts from API, attempting to load test alert...');
        try {
          final testAlert = await _apiService.getAlertById('68f166168eeae9e50d48e58a');
          print('Successfully loaded test alert: ${testAlert.id}');
          setState(() {
            _alerts = [testAlert];
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('Failed to load test alert: $e');
        }
      }
      
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlertDetails(Alert alert) async {
    setState(() {
      _selectedAlert = alert;
      _skeletonFrames = []; // Clear previous frames
    });

    try {
      print('Loading details for alert: ${alert.id}');
      
      // Fetch full alert details with skeleton file
      final fullAlert = await _apiService.getAlertById(alert.id);
      
      print('Background URL available: ${fullAlert.backgroundUrl != null}');
      if (fullAlert.backgroundUrl != null) {
        print('Background URL: ${fullAlert.backgroundUrl!.substring(0, 80)}...');
      }
      
      setState(() {
        _selectedAlert = fullAlert;
      });
      
      print('Alert details loaded, has skeleton file: ${fullAlert.skeletonFile != null}');
      
      if (fullAlert.skeletonFile != null && fullAlert.skeletonFile!.isNotEmpty) {
        print('Skeleton file length: ${fullAlert.skeletonFile!.length}');
        
        try {
          // Get decoded skeleton data from backend (now returns multiple frames)
          final skeletonJson = await _apiService.getAlertSkeletonDecoded(alert.id);
          print('✓ Skeleton data decoded successfully');
          
          // Parse ALL frames using the new helper method
          final frames = _apiService.parseSkeletonFrames(skeletonJson);
          print('Parsed ${frames.length} frames');
          
          // Extract timing data for proper playback
          int? totalEpochTime = skeletonJson['epochTime'];
          int? numFrames = skeletonJson['numFrames'];
          print('Timing data: epochTime=$totalEpochTime, numFrames=$numFrames');
          
          if (frames.isNotEmpty) {
            final totalPeople = frames.fold<int>(0, (sum, frame) => sum + frame.people.length);
            final totalKeypoints = frames.fold<int>(0, (sum, frame) => 
              sum + frame.people.fold<int>(0, (s, person) => s + person.length));
            print('Total: $totalPeople people across ${frames.length} frames, $totalKeypoints total keypoints');
          }
          
          setState(() {
            _skeletonFrames = frames;
            _skeletonTiming = {'epochTime': totalEpochTime, 'numFrames': numFrames};
          });
        } catch (e) {
          print('Error parsing skeleton data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error parsing skeleton data: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('No skeleton file in alert');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This alert does not have skeleton data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error loading alert details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading skeleton data: $e')),
      );
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Detection Alerts'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _alerts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('No alerts found', style: TextStyle(fontSize: 18)),
                          SizedBox(height: 8),
                          Text('System is operating normally', 
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        // Left panel - Alert list
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  color: Colors.grey.shade100,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_alerts.length} Alerts',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _alerts.length,
                                    itemBuilder: (context, index) {
                                      final alert = _alerts[index];
                                      final isSelected = _selectedAlert?.id == alert.id;
                                      
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: Colors.blue.shade50,
                                        leading: Icon(
                                          _getAlertIcon(alert.alertType),
                                          color: _getAlertColor(alert.alertType),
                                          size: 32,
                                        ),
                                        title: Text(
                                          _formatAlertType(alert.alertType),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Camera: ${alert.cameraSerialNumber}'),
                                            Text(
                                              _formatTimestamp(alert.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => _loadAlertDetails(alert),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Right panel - Alert details
                        Expanded(
                          flex: 2,
                          child: _selectedAlert == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Select an alert to view details',
                                        style: TextStyle(fontSize: 18, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildAlertDetails(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildAlertDetails() {
    if (_selectedAlert == null) return const SizedBox();

    return Column(
      children: [
        // Alert header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getAlertColor(_selectedAlert!.alertType).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAlertIcon(_selectedAlert!.alertType),
                    size: 48,
                    color: _getAlertColor(_selectedAlert!.alertType),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatAlertType(_selectedAlert!.alertType),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(_selectedAlert!.createdAt),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Alert ID:', _selectedAlert!.id),
              _buildInfoRow('Camera:', _selectedAlert!.cameraSerialNumber ?? 'Unknown'),
              _buildInfoRow('Type:', _selectedAlert!.alertType),
              const SizedBox(height: 16),
              if (_selectedAlert!.cameraSerialNumber != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SkeletonViewerScreen(
                          initialCameraSerialNumber: _selectedAlert!.cameraSerialNumber,
                        ),
                      ),
                  );
                },
                icon: const Icon(Icons.videocam),
                label: const Text('View Live Skeleton'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.videocam_off),
                label: const Text('Live View Unavailable'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Alert visualization (skeleton video player with background)
        Expanded(
          child: _skeletonFrames.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading alert data...'),
                    ],
                  ),
                )
              : Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image layer
                        if (_selectedAlert?.id != null)
                          Positioned.fill(
                            child: Image.network(
                              'http://localhost:8080/api/skeleton/alerts/${_selectedAlert!.id}/background-image',
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade800,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.white54,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        // Skeleton video player overlay
                        SkeletonVideoPlayer(
                          frames: _skeletonFrames,
                          frameRate: 25.0, // Fallback frame rate
                          autoPlay: true,
                          totalEpochTime: _skeletonTiming?['epochTime'],
                          numFrames: _skeletonTiming?['numFrames'],
                        ),
                        
                        // Info badge
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_skeletonFrames.length} frames • ${(_skeletonFrames.length / 25).toStringAsFixed(1)}s',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'fall':
        return Icons.person_off;
      case 'loitering':
        return Icons.access_time;
      case 'intrusion':
        return Icons.warning;
      default:
        return Icons.notification_important;
    }
  }

  Color _getAlertColor(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'fall':
        return Colors.red;
      case 'loitering':
        return Colors.orange;
      case 'intrusion':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatAlertType(String alertType) {
    return alertType.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
