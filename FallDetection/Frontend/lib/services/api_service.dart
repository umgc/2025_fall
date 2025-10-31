import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/camera.dart';
import '../models/skeleton_stream_config.dart';
import '../models/alert.dart';
import '../models/skeleton_frame.dart';

class ApiService {
  final String baseUrl;

  // Constructor with default baseUrl
  ApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? _getDefaultBaseUrl();

  // Automatically detect the right base URL
  static String _getDefaultBaseUrl() {
    // For macOS development (you're on Mac)
    return 'http://localhost:8080';
    
    // For Android Emulator, use: 'http://10.0.2.2:8080'
    // For physical device, use: 'http://YOUR_MAC_IP:8080'
  }

  Future<List<Camera>> getCameras() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/cameras'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Camera.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cameras: ${response.statusCode}');
    }
  }

  Future<SkeletonStreamConfig> getStreamConfig(int cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/stream-config/$cameraId'),
    );

    if (response.statusCode == 200) {
      return SkeletonStreamConfig.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load stream config: ${response.statusCode}');
    }
  }

  Future<List<Alert>> getAlerts({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts?limit=$limit'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Alert.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load alerts: ${response.statusCode}');
    }
  }

  Future<Alert> getAlertById(String alertId) async {
    print('🔍 Fetching alert: $alertId from $baseUrl/api/skeleton/alerts/$alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId'),
    );

    print('📥 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Response body length: ${response.body.length}');
      final jsonData = jsonDecode(response.body);
      print('📝 Parsed JSON keys: ${jsonData.keys.toList()}');
      print('📝 Alert ID from response: ${jsonData['id']}');
      return Alert.fromJson(jsonData);
    } else {
      print('❌ Error response: ${response.body}');
      throw Exception('Failed to load alert: ${response.statusCode}');
    }
  }

  /// Get decoded skeleton data for an alert
  /// Returns the skeleton data in JSON format (already decoded from binary)
  Future<Map<String, dynamic>> getAlertSkeletonDecoded(String alertId) async {
    print('🦴 Fetching decoded skeleton for alert: $alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/skeleton-decoded'),
    );

    print('📥 Skeleton response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print('✅ Decoded skeleton data received');
      print('📝 JSON keys: ${jsonData.keys.toList()}');
      if (jsonData.containsKey('totalFrames')) {
        print('📊 Total frames in data: ${jsonData['totalFrames']}');
      }
      if (jsonData.containsKey('frames')) {
        print('📊 Frames array length: ${(jsonData['frames'] as List).length}');
      }
      return jsonData as Map<String, dynamic>;
    } else {
      print('❌ Error getting skeleton: ${response.body}');
      throw Exception('Failed to load skeleton data: ${response.statusCode}');
    }
  }

  /// Get fresh background image URL for an alert
  /// This fetches a new pre-signed S3 URL that won't be expired
  Future<String> getAlertBackgroundUrl(String alertId) async {
    print('🖼️ Fetching fresh background URL for alert: $alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/background-url'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final url = jsonData['background_url'] as String;
      print('✅ Fresh background URL received');
      return url;
    } else {
      print('❌ Error getting background URL: ${response.body}');
      throw Exception('Failed to load background URL: ${response.statusCode}');
    }
  }

  /// Get video clip URL for an alert
  Future<String> getAlertVideoUrl(String alertId) async {
    print('🎥 Fetching video URL for alert: $alertId');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/alerts/$alertId/video-url'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final url = jsonData['video_url'] as String;
      print('✅ Video URL received');
      return url;
    } else {
      print('❌ Error getting video URL: ${response.body}');
      throw Exception('Failed to load video URL: ${response.statusCode}');
    }
  }

  /// Get current view/snapshot from camera
  /// Returns the image as bytes
  Future<Uint8List> getCameraView(int cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/cameras/$cameraId/view'),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load camera view: ${response.statusCode}');
    }
  }

  /// Get background image from camera
  /// Returns the image as bytes
  Future<Uint8List> getCameraBackground(int cameraId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skeleton/cameras/$cameraId/background'),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load camera background: ${response.statusCode}');
    }
  }
  
  /// Parse decoded skeleton JSON data into SkeletonFrame objects
  /// Handles both single-frame and multi-frame formats
  List<SkeletonFrame> parseSkeletonFrames(Map<String, dynamic> skeletonData) {
    List<SkeletonFrame> frames = [];
    
    print('🔍 parseSkeletonFrames - Input keys: ${skeletonData.keys.toList()}');
    
    // Get global dimensions if available (for coordinate conversion)
    double globalWidth = (skeletonData['width'] ?? 1.0).toDouble();
    double globalHeight = (skeletonData['height'] ?? 1.0).toDouble();
    print('📐 Global dimensions: ${globalWidth}x${globalHeight}');
    
    // Check if this is multi-frame format
    if (skeletonData.containsKey('frames') && skeletonData['frames'] is List) {
      // Multi-frame format (alert skeleton files)
      List<dynamic> frameList = skeletonData['frames'];
      print('📦 Parsing ${frameList.length} frames from frames array');
      
      for (var frameData in frameList) {
        if (frameData is Map<String, dynamic>) {
          // Add global dimensions to frame data for coordinate conversion
          Map<String, dynamic> frameWithDimensions = Map.from(frameData);
          frameWithDimensions['width'] = globalWidth;
          frameWithDimensions['height'] = globalHeight;
          
          frames.add(_parseFrame(frameWithDimensions));
        }
      }
    } else if (skeletonData.containsKey('keypoints')) {
      // Single frame with new keypoints format
      print('📦 Parsing single frame from keypoints key');
      Map<String, dynamic> frameWithDimensions = Map.from(skeletonData);
      frameWithDimensions['width'] = globalWidth;
      frameWithDimensions['height'] = globalHeight;
      frames.add(_parseFrame(frameWithDimensions));
    } else if (skeletonData.containsKey('people')) {
      // Single frame format (backward compatibility)
      print('📦 Parsing single frame from people key');
      frames.add(_parseFrame(skeletonData));
    } else {
      print('❌ No frames, keypoints, or people key found in skeleton data!');
    }
    
    print('✅ Parsed ${frames.length} frames total');
    return frames;
  }
  
  /// Parse a single frame from JSON
  SkeletonFrame _parseFrame(Map<String, dynamic> frameData) {
    List<List<SkeletonKeypoint>> people = [];
    
    // Handle new keypoints format (from updated Java decoder)
    if (frameData.containsKey('keypoints') && frameData['keypoints'] is Map) {
      Map<String, dynamic> keypointsMap = frameData['keypoints'];
      print('📦 Parsing keypoints map format with ${keypointsMap.length} keypoints');
      
      // Create an array of 18 keypoints (OpenPose format)
      List<SkeletonKeypoint> keypoints = List.generate(18, (index) => SkeletonKeypoint(0.0, 0.0));
      
      // Get frame dimensions for coordinate conversion
      double width = (frameData['width'] ?? 1.0).toDouble();
      double height = (frameData['height'] ?? 1.0).toDouble();
      
      // Fill in the actual keypoints from the map
      for (var entry in keypointsMap.entries) {
        int index = int.tryParse(entry.key) ?? -1;
        if (index >= 0 && index < 18 && entry.value is Map) {
          Map<String, dynamic> point = entry.value;
          
          // Convert from raw coordinates to normalized (0-1) coordinates
          double x = ((point['x'] ?? 0) as num).toDouble() / width;
          double y = ((point['y'] ?? 0) as num).toDouble() / height;
          
          // Only add non-zero keypoints
          if (x > 0 && y > 0) {
            keypoints[index] = SkeletonKeypoint(x, y);
            print('  Keypoint $index: (${point['x']}, ${point['y']}) -> ($x, $y)');
          }
        }
      }
      
      // Add the person if we have any valid keypoints
      int validKeypoints = keypoints.where((kp) => kp.x > 0 || kp.y > 0).length;
      if (validKeypoints > 0) {
        people.add(keypoints);
        print('✅ Added person with $validKeypoints valid keypoints');
      }
    }
    // Handle old people format (backward compatibility)
    else if (frameData.containsKey('people') && frameData['people'] is List) {
      List<dynamic> peopleData = frameData['people'];
      print('📦 Parsing legacy people array format with ${peopleData.length} people');
      
      for (var personData in peopleData) {
        if (personData is List) {
          List<SkeletonKeypoint> keypoints = [];
          
          for (var keypointData in personData) {
            if (keypointData is List && keypointData.length >= 2) {
              double x = (keypointData[0] as num).toDouble();
              double y = (keypointData[1] as num).toDouble();
              
              // Skip invalid keypoints (0,0)
              if (x == 0.0 && y == 0.0) continue;
              
              keypoints.add(SkeletonKeypoint(x, y));
            }
          }
          
          if (keypoints.isNotEmpty) {
            people.add(keypoints);
          }
        }
      }
    }
    
    return SkeletonFrame(people);
  }
}