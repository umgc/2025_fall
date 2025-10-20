import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReviewPhotosScreen extends StatefulWidget {
  final List<XFile> initialPhotos;
  const ReviewPhotosScreen({Key? key, required this.initialPhotos}) : super(key: key);

  @override
  State<ReviewPhotosScreen> createState() => _ReviewPhotosScreenState();
}

class _ReviewPhotosScreenState extends State<ReviewPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  late List<XFile> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List<XFile>.from(widget.initialPhotos);
  }
  void _addIfNew(XFile x) {
    if (_photos.any((p) => p.path == x.path)) return;
    setState(() => _photos.add(x));
  }
Future<void> _addFromCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (x == null) return;
    _addIfNew(x);
  }

  Future<void> _addFromGallery() async {
    // image_picker does not support multi-select from gallery.
    // If you need multi-select gallery, use file_picker for gallery paths and XFile(...) them.
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => _photos.add(x));
  }

  void _removeAt(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _finish() {
    Navigator.of(context).pop<List<XFile>>(_photos);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Photos'),
        actions: [
          TextButton(
            onPressed: _photos.isEmpty ? null : _finish,
            child: Text(
              'Done',
              style: TextStyle(
                color: _photos.isEmpty ? cs.onSurface.withOpacity(0.38) : cs.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: _photos.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 64),
                  const SizedBox(height: 12),
                  const Text('No photos yet'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('From gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Add'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _addFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                      const Spacer(),
                      Text('${_photos.length} selected'),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _photos.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final file = File(_photos[index].path);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(file, fit: BoxFit.cover),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removeAt(index),
                              customBorder: const CircleBorder(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
     bottomNavigationBar: _photos.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _finish,
                    child: Text('Done (${_photos.length})'),
                  ),
                ),
              ),
            ),
      floatingActionButton: _photos.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Add'),
            ),
    );
  }
}
