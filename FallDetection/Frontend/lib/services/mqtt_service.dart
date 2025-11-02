// lib/services/mqtt_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' show Uint8Buffer;
import '../models/skeleton_frame.dart';
import '../models/skeleton_stream_config.dart';

class MqttService {
  MqttServerClient? client;
  SkeletonStreamConfig? config;
  Timer? tokenPublishTimer;
  
  final StreamController<SkeletonFrame> _skeletonController = 
      StreamController<SkeletonFrame>.broadcast();
  
  Stream<SkeletonFrame> get skeletonStream => _skeletonController.stream;
  
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> connect(SkeletonStreamConfig streamConfig) async {
    config = streamConfig;
    
    // Parse WSS URL - extract just the host and port
    final uri = Uri.parse(streamConfig.wssUrl);
    final host = uri.host;
    final port = uri.port;
    
    print('Parsed WSS URL: ${streamConfig.wssUrl}');
    print('Host: $host, Port: $port, Scheme: ${uri.scheme}');
    
    // Create client with unique ID
    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient.withPort(host, clientId, port);
    
    // Configure WebSocket
    client!.useWebSocket = true;
    client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    
    // Enable logging to debug connection issues
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.autoReconnect = false;
    
    // Set secure flag based on the URL scheme
    client!.secure = uri.scheme == 'wss';
    
    // IMPORTANT: For desktop/macOS with WSS, we need a custom SecurityContext
    // to avoid "Unsupported operation: default SecurityContext getter" error
    if (client!.secure) {
      try {
        // Create a permissive SecurityContext that accepts all certificates
        final context = SecurityContext.defaultContext;
        context.setTrustedCertificatesBytes([]); // Empty list allows all certs
        client!.securityContext = context;
        
        // Also set the bad certificate callback as backup
        client!.onBadCertificate = (dynamic cert) {
          print('⚠️ Accepting certificate for secure WebSocket connection');
          return true;
        };
        
        print('✓ Configured secure WebSocket with custom SecurityContext');
      } catch (e) {
        print('⚠️ Could not set custom SecurityContext: $e');
        print('   Trying without SecurityContext...');
        
        // If SecurityContext fails, try just the callback
        client!.onBadCertificate = (dynamic cert) {
          return true;
        };
      }
    }
    
    // Callbacks
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    
    // Set up connection message
    final connMessage = MqttConnectMessage()
        .authenticateAs(streamConfig.mqttUsername, streamConfig.mqttPassword)
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    
    client!.connectionMessage = connMessage;
    
    try {
      print('🔄 Connecting to MQTT broker...');
      print('   Host: $host');
      print('   Port: $port');
      print('   Secure: ${client!.secure}');
      print('   Username: ${streamConfig.mqttUsername}');
      print('   Client ID: $clientId');
      
      final status = await client!.connect();
      
      if (status?.state == MqttConnectionState.connected) {
        print('✓ MQTT connection successful!');
      } else {
        print('✗ MQTT connection failed');
        print('   State: ${status?.state}');
        print('   Return code: ${status?.returnCode}');
        _connectionController.add(false);
      }
    } catch (e, stackTrace) {
      print('✗ MQTT Connection exception: $e');
      print('Stack trace: $stackTrace');
      client?.disconnect();
      _connectionController.add(false);
      rethrow;
    }
  }

  void _onConnected() {
    print('✓ Connected to MQTT');
    _connectionController.add(true);
    
    // Subscribe to skeleton topic
    client!.subscribe(config!.subscribeTopic, MqttQos.atMostOnce);
    print('✓ Subscribed to ${config!.subscribeTopic}');
    
    // Listen for messages
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final message = messages[0].payload as MqttPublishMessage;
      final payload = message.payload.message;
      _parseSkeletonData(payload);
    });
    
    // Publish stream token immediately
    _publishStreamToken();
    
    // Publish every 45 seconds
    tokenPublishTimer = Timer.periodic(Duration(seconds: 45), (_) {
      _publishStreamToken();
    });
  }

  void _onDisconnected() {
    print('✗ Disconnected from MQTT');
    _connectionController.add(false);
    tokenPublishTimer?.cancel();
  }

  void _publishStreamToken() {
    if (client != null && config != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(config!.streamToken.toString());
      client!.publishMessage(
        config!.publishTopic,
        MqttQos.atMostOnce,
        builder.payload!,
      );
      print('→ Published stream token');
    }
  }

  void _parseSkeletonData(Uint8Buffer payload) {
    try {
      // Convert Uint8Buffer to Uint8List
      final bytes = Uint8List.fromList(payload.toList());
      
      // Minimum size check: 8 bytes header + at least 152 bytes per person
      if (bytes.length < 8) {
        print('⚠️ Skeleton data too small: ${bytes.length} bytes');
        _skeletonController.add(SkeletonFrame([]));
        return;
      }
      
      final byteData = ByteData.sublistView(bytes);
      int offset = 0;
      
      // Read frame number (4 bytes, int32)
      final frameNum = byteData.getInt32(offset, Endian.little);
      offset += 4;
      
      // Read number of people (4 bytes, int32)
      final numPeople = byteData.getInt32(offset, Endian.little);
      offset += 4;
      
      print('📦 Frame $frameNum: $numPeople person(s), ${bytes.length} bytes');
      
      if (numPeople == 0 || numPeople > 10) {
        // Sanity check: more than 10 people is suspicious
        if (numPeople > 10) {
          print('⚠️ Suspicious numPeople: $numPeople (ignoring frame)');
        }
        _skeletonController.add(SkeletonFrame([]));
        return;
      }
      
      // Each person = 152 bytes (4 + 72 + 72 + 4)
      final expectedSize = 8 + (numPeople * 152);
      if (bytes.length < expectedSize) {
        print('⚠️ Data too small: ${bytes.length} bytes, expected $expectedSize');
        _skeletonController.add(SkeletonFrame([]));
        return;
      }
      
      List<List<SkeletonKeypoint>> people = [];
      
      for (int i = 0; i < numPeople; i++) {
        // Each person structure (152 bytes):
        // - personId: 4 bytes (int32)
        // - X coordinates: 18 floats (72 bytes)
        // - Y coordinates: 18 floats (72 bytes)  
        // - padding: 4 bytes
        
        // Read person ID (4 bytes)
        final personId = byteData.getInt32(offset, Endian.little);
        offset += 4;
        
        // Read X coordinates (18 × float32 = 72 bytes)
        List<double> xCoords = [];
        for (int j = 0; j < 18; j++) {
          xCoords.add(byteData.getFloat32(offset, Endian.little));
          offset += 4;
        }
        
        // Read Y coordinates (18 × float32 = 72 bytes)
        List<double> yCoords = [];
        for (int j = 0; j < 18; j++) {
          yCoords.add(byteData.getFloat32(offset, Endian.little));
          offset += 4;
        }
        
        // Skip padding (4 bytes)
        offset += 4;
        
        // Combine X and Y into keypoints
        List<SkeletonKeypoint> keypoints = [];
        for (int j = 0; j < 18; j++) {
          keypoints.add(SkeletonKeypoint(xCoords[j], yCoords[j]));
        }
        
        print('  Person $personId: ${keypoints.where((k) => k.x != 0 || k.y != 0).length}/18 keypoints visible');
        people.add(keypoints);
      }
      
      _skeletonController.add(SkeletonFrame(people));
    } catch (e, stackTrace) {
      print('❌ Error parsing skeleton data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void disconnect() {
    tokenPublishTimer?.cancel();
    client?.disconnect();
  }

  void dispose() {
    disconnect();
    _skeletonController.close();
    _connectionController.close();
  }
}