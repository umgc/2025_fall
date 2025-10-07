import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelFile {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modified;

  ModelFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modified,
  });
}

class ModelRegistry {
  static const _kActiveModelPath = 'active_model_path';

  static Future<Directory> modelsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final models = Directory(p.join(dir.path, 'models'));
    if (!models.existsSync()) models.createSync(recursive: true);
    return models;
  }

  static Future<List<ModelFile>> list() async {
    final dir = await modelsDir();
    final files = <ModelFile>[];
    for (final f in dir.listSync().whereType<File>()) {
      if (f.path.toLowerCase().endsWith('.gguf')) {
        final stat = await f.stat();
        files.add(ModelFile(
          path: f.path,
          name: p.basename(f.path),
          sizeBytes: stat.size,
          modified: stat.modified,
        ));
      }
    }
    files.sort((a, b) => a.name.compareTo(b.name));
    return files;
  }

  static Future<String?> getActivePath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kActiveModelPath);
    if (path == null) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  static Future<void> setActivePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveModelPath, path);
  }

  static Future<void> deletePath(String path) async {
    final f = File(path);
    if (f.existsSync()) await f.delete();
    final active = await getActivePath();
    if (active == path) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveModelPath);
    }
  }

  static String humanSize(int bytes) {
    const units = ['B','KB','MB','GB','TB'];
    var b = bytes.toDouble();
    var i = 0;
    while (b >= 1024 && i < units.length - 1) { b /= 1024; i++; }
    return '${b.toStringAsFixed(b >= 10 || i == 0 ? 0 : 1)} ${units[i]}';
  }
}
