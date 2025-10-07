// Do not add emoji's in comments
import 'dart:io';
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
 
import 'package:care_connect_app/features/invoices/ai/ai_bootstrap.dart';
import 'package:care_connect_app/features/invoices/ai/model_fetch.dart';
import 'package:care_connect_app/features/invoices/ai/model_registry.dart';

class ModelManagerPage extends StatefulWidget {
  const ModelManagerPage({super.key});

  @override
  State<ModelManagerPage> createState() => _ModelManagerPageState();
}

class _ModelManagerPageState extends State<ModelManagerPage> {
  List<ModelFile> _items = [];
  String? _activePath;

  final _urlCtr = TextEditingController();
  final _nameCtr = TextEditingController(text: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf');

  int _progressBytes = 0;
  int? _progressTotal;
  bool _downloading = false;
  bool _loadingModel = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _urlCtr.dispose();
    _nameCtr.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final items = await ModelRegistry.list();
    final active = await ModelRegistry.getActivePath();
    setState(() {
      _items = items;
      _activePath = active;
    });
  }

  Future<void> _pickLocalFile() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );
    if (res == null) return;

    final srcPath = res.files.single.path;
    if (srcPath == null) return;

    final modelsDir = await ModelRegistry.modelsDir();
    final dest = File(p.join(modelsDir.path, p.basename(srcPath)));

    try {
      await File(srcPath).copy(dest.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${p.basename(srcPath)}')),
        );
      }
      await _refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _download() async {
    final urlText = _urlCtr.text.trim();
    final fileName = _nameCtr.text.trim();
    if (urlText.isEmpty || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter URL and file name')),
      );
      return;
    }
    setState(() {
      _downloading = true;
      _progressBytes = 0;
      _progressTotal = null;
    });
    try {
      final path = await ModelFetch.downloadTo(
        url: Uri.parse(urlText),
        fileName: fileName,
        onProgress: (r, t) {
          setState(() {
            _progressBytes = r;
            _progressTotal = t;
          });
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded ${p.basename(path)}')),
        );
      }
      await _refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _setActive(String path) async {
    setState(() => _loadingModel = true);
    try {
      await AIBootstrap.ensureReadyWithPath(path, nCtx: 512); // adjust nCtx if needed
      await ModelRegistry.setActivePath(path);
      await _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model loaded and set active')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingModel = false);
    }
  }

  Future<void> _delete(String path) async {
    await ModelRegistry.deletePath(path);
    await _refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${p.basename(path)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBusy = _downloading || _loadingModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Models'),
      ),
        drawer: const CommonDrawer(currentRoute: '/models'),
      body: AbsorbPointer(
        absorbing: isBusy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Download model', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlCtr,
                      decoration: const InputDecoration(
                        labelText: 'Model URL (https://...)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtr,
                      decoration: const InputDecoration(
                        labelText: 'Save as filename (.gguf)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _downloading ? null : _download,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _pickLocalFile,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Import .gguf'),
                        ),
                      ],
                    ),
                    if (_downloading) ...[
                      const SizedBox(height: 12),
                      _DownloadProgress(
                        received: _progressBytes,
                        total: _progressTotal,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Installed models', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              const Text('No models yet. Download or import a .gguf above.')
            else
              ..._items.map((m) {
                final isActive = m.path == _activePath;
          return Card(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: isActive ? cs.primary : cs.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ModelRegistry.humanSize(m.sizeBytes)} • Modified ${m.modified}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: isActive || _loadingModel ? null : () => _setActive(m.path),
                child: const Text('Set Active'),
              ),
              OutlinedButton(
                onPressed: (_activePath == null || _loadingModel || _downloading)
                    ? null
                    : () { context.go('/chat'); },
                child: const Text('Test'),
              ),
              OutlinedButton.icon(
                onPressed: _loadingModel ? null : () => _delete(m.path),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

              }),
            if (_loadingModel) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Loading model into memory. This can take a moment on low memory devices.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  final int received;
  final int? total;
  const _DownloadProgress({required this.received, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == null || total == 0 ? null : received / total!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: pct),
        const SizedBox(height: 6),
        Text(
          total == null
              ? 'Downloaded ${ModelRegistry.humanSize(received)}'
              : '${ModelRegistry.humanSize(received)} of ${ModelRegistry.humanSize(total!)}',
        ),
      ],
    );
  }
}
