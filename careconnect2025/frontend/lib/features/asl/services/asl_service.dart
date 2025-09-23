import 'dart:async';

class AslService {
  // MVP stub: emulate a "render" pipeline that returns a mock asset path
  static Future<String> render(String text) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return "assets/asl/clips/placeholder.mp4"; // replace when real engine is wired
  }
}
