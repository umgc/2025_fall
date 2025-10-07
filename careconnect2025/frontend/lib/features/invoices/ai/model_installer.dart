import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'model_constants.dart';

class ModelInstaller {
  /// Copies the bundled GGUF asset into the app documents dir if not present.
  /// Returns the absolute path to the installed model file.
  static Future<String> copyAssetIfNeeded() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/models');
    if (!modelsDir.existsSync()) modelsDir.createSync(recursive: true);

    final dest = File('${modelsDir.path}/${ModelConstants.localFileName}');
    if (dest.existsSync()) return dest.path;

    final bytes = await rootBundle.load(ModelConstants.assetPath);
    await dest.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return dest.path;
  }
}
