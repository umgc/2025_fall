import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:learninglens_app/main.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() {
    // Lazy initialization
    return _instance;
  }
  DownloadManager._internal();

  final Map<String, http.Client> _clients = {};
  final Map<String, double> _progress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, bool> _cancelled = {};
  final Map<String, IOSink> _sinks = {};

  bool _initialized = false;
  String? _baseDir;

  bool isCancelled(String modelName) => _cancelled[modelName] ?? false;
  final Map<String, ValueNotifier<bool>> _downloadedNotifiers = {};

  // Stream controller to notify UI of progress changes
  final Map<String, ValueNotifier<double>> _progressNotifiers = {};

  ValueNotifier<double> progressNotifier(String modelName) {
    _progressNotifiers.putIfAbsent(modelName, () => ValueNotifier(0.0));
    return _progressNotifiers[modelName]!;
  }

  ValueNotifier<bool> downloadedNotifier(String modelName) {
    _downloadedNotifiers.putIfAbsent(modelName, () => ValueNotifier(false));
    return _downloadedNotifiers[modelName]!;
  }

// Call this internally after download or on startup
  Future<void> _updateDownloadedState(String modelName) async {
    final path = await _getFilePath(modelName);
    final exists = File(path).existsSync();
    downloadedNotifier(modelName).value = exists;
  }

  bool isDownloading(String modelName) => _isDownloading[modelName] ?? false;

  Future<String> getFilePath(String modelName) async {
    return await _getFilePath(modelName);
  }

  Future<String> _getFilePath(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}\\models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return '${modelsDir.path}\\$modelName.gguf';
  }

  Future<void> init() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}\\models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    _baseDir = modelsDir.path;
    _initialized = true;
  }

  String _getFilePathSync(String modelName) {
    if (!_initialized || _baseDir == null) {
      throw StateError('DownloadManager not initialized.');
    }
    return '$_baseDir\\$modelName.gguf';
  }

  bool isDownloaded(String modelName) {
    final path = _getFilePathSync(modelName);
    return File(path).existsSync() && !isDownloading(modelName);
  }

  Future<void> startDownload(String modelName, String url) async {
    if (isDownloading(modelName)) return;

    final client = http.Client();
    _clients[modelName] = client;
    _isDownloading[modelName] = true;
    _progress[modelName] = 0.0;
    _cancelled[modelName] = false;
    progressNotifier(modelName).value = 0.0;

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      final totalBytes = response.contentLength ?? 0;

      final filePath = await _getFilePath(modelName);
      final file = File(filePath);
      final sink = file.openWrite();

      _sinks[modelName] = sink;

      int bytesReceived = 0;

      await for (final chunk in response.stream) {
        // If cancelled, break the loop
        if (!isDownloading(modelName)) {
          debugPrint('Download cancelled mid-stream: $modelName');
          break;
        }

        bytesReceived += chunk.length;
        sink.add(chunk);

        if (totalBytes > 0) {
          final progress = bytesReceived / totalBytes;
          _progress[modelName] = progress;
          progressNotifier(modelName).value = progress;
        }
      }

      await sink.close();

      await _updateDownloadedState(modelName);
      _showDownloadCompleteNotification(modelName);

      await _updateDownloadedState(modelName);
    } catch (e) {
      debugPrint('Download failed for $modelName: $e');
      final filePath = await _getFilePath(modelName);
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } finally {
      _clients[modelName]?.close();
      _clients.remove(modelName);
      _isDownloading[modelName] = false;
      _progress[modelName] = 0.0;
      _cancelled[modelName] = false;
      progressNotifier(modelName).value = 0.0;
    }
  }

  void _showDownloadCompleteNotification(String modelName) {
    if (navigatorKey.currentContext != null) {
      final context = navigatorKey.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model "$modelName" downloaded successfully!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> cancelDownload(String modelName) async {
    if (_clients.containsKey(modelName)) {
      _isDownloading[modelName] = false; // signal cancellation

      // Close the sink if it exists
      if (_sinks.containsKey(modelName)) {
        await _sinks[modelName]?.close();
        _sinks.remove(modelName);
      }

      // Close HTTP client
      _clients[modelName]?.close();
      _clients.remove(modelName);

      // Delete partial file
      final filePath = await _getFilePath(modelName);
      final file = File(filePath);
      if (await file.exists()) await file.delete();

      // Reset progress
      _progress[modelName] = 0.0;
      progressNotifier(modelName).value = 0.0;

      debugPrint('Download cancelled: $modelName');
    }
  }

  Future<void> deleteModel(String modelName) async {
    try {
      final path = await _getFilePath(modelName);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        progressNotifier(modelName).value = 0.0;
        downloadedNotifier(modelName).value = false;
        debugPrint('Model deleted: $path');
      } else {
        debugPrint('Delete skipped — file not found: $path');
      }
    } catch (e) {
      debugPrint('Error deleting model $modelName: $e');
    }
  }

  Future<String?> getDownloadedPath(String modelName) async {
    if (isDownloaded(modelName)) {
      return await _getFilePath(modelName);
    }
    return null;
  }
}
