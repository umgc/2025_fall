import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/camera.dart';
import '../services/api_service.dart';

class CameraImagesScreen extends StatefulWidget {
  const CameraImagesScreen({super.key});

  @override
  State<CameraImagesScreen> createState() => _CameraImagesScreenState();
}

class _CameraImagesScreenState extends State<CameraImagesScreen> {
  final ApiService _apiService = ApiService();
  List<Camera> _cameras = [];
  Camera? _selectedCamera;
  bool _isLoadingCameras = true;
  bool _isLoadingView = false;
  bool _isLoadingBackground = false;
  String? _error;
  Uint8List? _viewImage;
  Uint8List? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() {
      _isLoadingCameras = true;
      _error = null;
    });

    try {
      final cameras = await _apiService.getCameras();
      setState(() {
        _cameras = cameras;
        _isLoadingCameras = false;
        if (cameras.isNotEmpty) {
          _selectedCamera = cameras.first;
          _loadImages();
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCameras = false;
      });
    }
  }

  Future<void> _loadImages() async {
    if (_selectedCamera == null) return;

    setState(() {
      _isLoadingView = true;
      _isLoadingBackground = true;
    });

    // Load view image
    _loadViewImage();
    
    // Load background image
    _loadBackgroundImage();
  }

  Future<void> _loadViewImage() async {
    if (_selectedCamera == null) return;

    try {
      final imageBytes = await _apiService.getCameraView(_selectedCamera!.id);
      setState(() {
        _viewImage = imageBytes;
        _isLoadingView = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingView = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading camera view: $e')),
        );
      }
    }
  }

  Future<void> _loadBackgroundImage() async {
    if (_selectedCamera == null) return;

    try {
      final imageBytes = await _apiService.getCameraBackground(_selectedCamera!.id);
      setState(() {
        _backgroundImage = imageBytes;
        _isLoadingBackground = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBackground = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading background: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Images'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImages,
            tooltip: 'Refresh Images',
          ),
        ],
      ),
      body: _isLoadingCameras
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCameras,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _cameras.isEmpty
                  ? const Center(
                      child: Text('No cameras found'),
                    )
                  : Column(
                      children: [
                        // Camera selector
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam, color: Colors.blue),
                              const SizedBox(width: 12),
                              const Text(
                                'Camera:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<Camera>(
                                  value: _selectedCamera,
                                  isExpanded: true,
                                  items: _cameras.map((camera) {
                                    return DropdownMenuItem(
                                      value: camera,
                                      child: Text(
                                        '${camera.friendlyName} (${camera.serialNumber})',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (camera) {
                                    setState(() {
                                      _selectedCamera = camera;
                                      _viewImage = null;
                                      _backgroundImage = null;
                                    });
                                    _loadImages();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Images grid
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Current View
                                Expanded(
                                  child: _buildImageCard(
                                    title: 'Current View',
                                    icon: Icons.camera_alt,
                                    color: Colors.green,
                                    imageBytes: _viewImage,
                                    isLoading: _isLoadingView,
                                    onRefresh: _loadViewImage,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Background Image
                                Expanded(
                                  child: _buildImageCard(
                                    title: 'Background',
                                    icon: Icons.image,
                                    color: Colors.purple,
                                    imageBytes: _backgroundImage,
                                    isLoading: _isLoadingBackground,
                                    onRefresh: _loadBackgroundImage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required IconData icon,
    required Color color,
    required Uint8List? imageBytes,
    required bool isLoading,
    required VoidCallback onRefresh,
  }) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: isLoading ? null : onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          
          // Image content
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading image...'),
                        ],
                      ),
                    )
                  : imageBytes == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No image available',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 64, color: Colors.red.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading image',
                                      style: TextStyle(color: Colors.red.shade600),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ),
          
          // Footer with image info
          if (imageBytes != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Size: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
