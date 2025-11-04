class Alert {
  final String id;
  final String alertType;
  final String? cameraSerialNumber;  // Made nullable to handle null from API
  final int createdAt;
  final String? skeletonFile;
  final String? backgroundUrl;

  Alert({
    required this.id,
    required this.alertType,
    this.cameraSerialNumber,  // Now optional
    required this.createdAt,
    this.skeletonFile,
    this.backgroundUrl,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    try {
      print('🔧 Parsing Alert from JSON');
      print('   - id: ${json['id']}');
      print('   - alert_type: ${json['alert_type']}');
      print('   - camera_serial_number: ${json['camera_serial_number']}');
      print('   - created_at: ${json['created_at']}');
      print('   - has skeleton_file: ${json['skeleton_file'] != null}');
      
      return Alert(
        id: json['id'],
        alertType: json['alert_type'],
        cameraSerialNumber: json['camera_serial_number'],
        createdAt: json['created_at'],
        skeletonFile: json['skeleton_file'],
        backgroundUrl: json['background_url'],
      );
    } catch (e) {
      print('❌ Error parsing Alert: $e');
      print('   JSON keys: ${json.keys.toList()}');
      rethrow;
    }
  }
}