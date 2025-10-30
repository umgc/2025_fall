// lib/screens/skeleton_viewer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/camera.dart';
import '../models/skeleton_frame.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart' if (dart.library.html) '../services/mqtt_service_web.dart';
import '../widgets/skeleton_painter.dart';

class SkeletonViewerScreen extends StatefulWidget {
  final String? initialCameraSerialNumber;
  
  const SkeletonViewerScreen({super.key, this.initialCameraSerialNumber});
  
  @override
  _SkeletonViewerScreenState createState() => _SkeletonViewerScreenState();
}

class _SkeletonViewerScreenState extends State<SkeletonViewerScreen> {
  final ApiService apiService = ApiService(baseUrl: 'http://localhost:8080');
  final MqttService mqttService = MqttService();
  
  List<Camera> cameras = [];
  Camera? selectedCamera;
  SkeletonFrame? currentFrame;
  bool isConnected = false;
  bool isLoading = false;
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<SkeletonFrame>? _skeletonSubscription;

  @override
  void initState() {
    super.initState();
    _loadCameras();
    
    // Listen to MQTT connection status
    _connectionSubscription = mqttService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          isConnected = connected;
        });
      }
    });
    
    // Listen to skeleton data
    _skeletonSubscription = mqttService.skeletonStream.listen((frame) {
      if (mounted) {
        setState(() {
          currentFrame = frame;
        });
      }
    });
  }

  Future<void> _loadCameras() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final cameraList = await apiService.getCameras();
      setState(() {
        cameras = cameraList;
        if (cameraList.isNotEmpty) {
          // If an initial camera serial number was provided, try to select it
          if (widget.initialCameraSerialNumber != null) {
            selectedCamera = cameraList.firstWhere(
              (camera) => camera.serialNumber == widget.initialCameraSerialNumber,
              orElse: () => cameraList[0],
            );
          } else {
            selectedCamera = cameraList[0];
          }
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Failed to load cameras: $e');
    }
  }

  Future<void> _connectToStream() async {
    if (selectedCamera == null) {
      _showError('Please select a camera');
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final config = await apiService.getStreamConfig(selectedCamera!.id);
      await mqttService.connect(config);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Failed to connect: $e');
    }
  }

  void _disconnect() {
    mqttService.disconnect();
    setState(() {
      currentFrame = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skeleton Viewer'),
        actions: [
          if (isConnected)
            Icon(Icons.circle, color: Colors.green, size: 16),
        ],
      ),
      body: Column(
        children: [
          // Camera selection
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<Camera>(
                    value: selectedCamera,
                    isExpanded: true,
                    hint: Text('Select Camera'),
                    items: cameras.map((camera) {
                      return DropdownMenuItem(
                        value: camera,
                        child: Text('${camera.friendlyName} (${camera.serialNumber})'),
                      );
                    }).toList(),
                    onChanged: (camera) {
                      setState(() {
                        selectedCamera = camera;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isConnected ? _disconnect : _connectToStream,
                  child: Text(isConnected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
          ),
          
          // Skeleton canvas
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CustomPaint(
                    painter: SkeletonPainter(currentFrame),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
          
          // Status
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              isConnected
                  ? 'Connected - ${currentFrame?.people.length ?? 0} person(s) detected'
                  : 'Disconnected',
              style: TextStyle(
                color: isConnected ? const Color.fromARGB(255, 175, 76, 76) : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _connectionSubscription?.cancel();
    _skeletonSubscription?.cancel();
    
    // Dispose MQTT service
    mqttService.dispose();
    
    super.dispose();
  }
}