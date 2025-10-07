import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef Progress = void Function(int received, int? totalBytes);

class ModelFetch {
  static Future<String> downloadTo({
    required Uri url,
    required String fileName, 
    Progress? onProgress,
    bool overwrite = false,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(dir.path, 'models'));
    if (!modelsDir.existsSync()) modelsDir.createSync(recursive: true);

    final dest = File(p.join(modelsDir.path, fileName));
    if (dest.existsSync() && !overwrite) return dest.path;

    final tmp = File('${dest.path}.part');
    if (tmp.existsSync()) await tmp.delete();

    final client = HttpClient();
    final req = await client.getUrl(url);
    final resp = await req.close();

    final sink = tmp.openWrite();
    int received = 0;
    final totalStr = resp.headers.value(HttpHeaders.contentLengthHeader);
    final total = totalStr == null ? null : int.tryParse(totalStr);

    await for (final chunk in resp) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }
    await sink.close();
    client.close();

    if (dest.existsSync()) await dest.delete();
    await tmp.rename(dest.path);

    return dest.path;
  }
}
