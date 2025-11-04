import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/skeleton_frame.dart';
import '../models/skeleton_stream_config.dart';

class MqttService {
  WebSocketChannel? _channel;
  
  final StreamController<SkeletonFrame> _skeletonController = 
      StreamController<SkeletonFrame>.broadcast();
  
  Stream<SkeletonFrame> get skeletonStream => _skeletonController.stream;
  
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool _isConnected = false;
  String? _currentCamera;
  
  Future<void> connect(SkeletonStreamConfig streamConfig) async {
    try {
      _currentCamera = streamConfig.serialNumber;
      
      // Connect to backend WebSocket proxy instead of MQTT directly
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080/ws/skeleton'),
      );
      
      // Send connect message
      _channel!.sink.add(jsonEncode({
        'action': 'connect',
        'cameraSerialNumber': streamConfig.serialNumber,
      }));
      
      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _connectionController.add(false);
        },
      );
      
      _isConnected = true;
      _connectionController.add(true);
      print('Connected to skeleton stream for camera: ${streamConfig.serialNumber}');
      
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }
  
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      
      if (data['type'] == 'skeleton_data') {
        // Decode base64 binary data
        final bytes = base64Decode(data['data']);
        _parseSkeletonData(Uint8List.fromList(bytes));
      } else if (data['type'] == 'connected') {
        print('Successfully connected to camera: ${data['camera']}');
      } else if (data['type'] == 'error') {
        print('Error from server: ${data['message']}');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }
  
  void _parseSkeletonData(Uint8List bytes) {
    try {
      final byteData = ByteData.sublistView(bytes);
      int offset = 0;
      
      // Parse frame number (4 bytes, int32, little-endian)
      final frameNum = byteData.getInt32(offset, Endian.little);
      offset += 4;
      
      // Parse number of people (4 bytes, int32, little-endian)
      final numPeople = byteData.getInt32(offset, Endian.little);
      offset += 4;
      
      // Validate
      if (numPeople < 0 || numPeople > 20) {
        print('Invalid number of people: $numPeople');
        return;
      }
      
      List<List<SkeletonKeypoint>> people = [];
      
      // Parse each person (152 bytes each)
      for (int i = 0; i < numPeople; i++) {
        if (offset + 152 > bytes.length) {
          print('Not enough data for person $i');
          break;
        }
        
        // Parse person ID (4 bytes, int32) - skip it
        offset += 4;
        
        // Parse X coordinates (18 floats, 72 bytes)
        List<double> xCoords = [];
        for (int j = 0; j < 18; j++) {
          xCoords.add(byteData.getFloat32(offset, Endian.little));
          offset += 4;
        }
        
        // Parse Y coordinates (18 floats, 72 bytes)
        List<double> yCoords = [];
        for (int j = 0; j < 18; j++) {
          yCoords.add(byteData.getFloat32(offset, Endian.little));
          offset += 4;
        }
        
        // Skip padding (4 bytes)
        offset += 4;
        
        // Create keypoints (already normalized 0-1 coordinates)
        List<SkeletonKeypoint> keypoints = [];
        for (int j = 0; j < 18; j++) {
          double x = xCoords[j];
          double y = yCoords[j];
          
          // Skip invalid points (0, 0)
          if (x == 0.0 && y == 0.0) {
            continue;
          }
          
          keypoints.add(SkeletonKeypoint(x, y));
        }
        
        if (keypoints.isNotEmpty) {
          people.add(keypoints);
        }
      }
      
      // Emit frame
      final frame = SkeletonFrame(people);
      _skeletonController.add(frame);
      
      if (people.isNotEmpty) {
        print('Frame $frameNum: ${people.length} people, ${people[0].length} keypoints');
      }
      
    } catch (e, stackTrace) {
      print('Error parsing skeleton data: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'action': 'disconnect'}));
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _connectionController.add(false);
    _currentCamera = null;
  }
  
  void dispose() {
    disconnect();
    _skeletonController.close();
    _connectionController.close();
  }
  
  bool get isConnected => _isConnected;
  String? get currentCamera => _currentCamera;
}
