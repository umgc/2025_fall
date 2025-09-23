class AslService {
  /// Stub that simulates rendering. Replace with real pipeline later.
  static Future<String> render(String text) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (text.trim().isEmpty) return 'Nothing to render';
    return 'asl://rendered/${text.trim().replaceAll(' ', '_').toLowerCase()}';
  }
}
