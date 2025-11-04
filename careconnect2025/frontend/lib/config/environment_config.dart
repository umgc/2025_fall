import 'package:flutter/foundation.dart' show kIsWeb;

class EnvironmentConfig {
  static const String _web =
  String.fromEnvironment('CC_BASE_URL_WEB', defaultValue: 'http://localhost:8080');
  static const String _android =
  String.fromEnvironment('CC_BASE_URL_ANDROID', defaultValue: 'http://10.0.2.2:8080');
  static const String _other =
  String.fromEnvironment('CC_BASE_URL_OTHER', defaultValue: 'http://localhost:8080');

  /// Call this anywhere you need the API base.
  static String get baseUrl {
    if (kIsWeb) return _web;

    // Default to Android emulator for now
    return _android;
  }
}

