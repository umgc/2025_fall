import 'dart:convert';
import 'package:http/http.dart' as http;

class AslResult {
  final String mode; // 'video' or 'fingerspell'
  final List<Map<String, dynamic>> frames;
  final String text;
  AslResult.video(this.frames) : mode = 'video', text = '';
  AslResult.fingerspell(this.text) : mode = 'fingerspell', frames = const [];
}

class AslEngine {
  final String baseUrl;
  AslEngine(this.baseUrl);

  Future<AslResult> translate(String text) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/v1/asl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'locale': 'en-US', 'preferVideo': true}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['available'] == true) {
        final List frames = data['frames'] ?? [];
        return AslResult.video(frames.cast<Map<String, dynamic>>());
      }
      return AslResult.fingerspell(text);
    } catch (_) {
      return AslResult.fingerspell(text);
    }
  }
}
