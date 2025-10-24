import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AslVideoPlayer extends StatefulWidget {
  final List<Map<String, dynamic>> frames;
  const AslVideoPlayer({super.key, required this.frames});

  @override
  State<AslVideoPlayer> createState() => _AslVideoPlayerState();
}

class _AslVideoPlayerState extends State<AslVideoPlayer> {
  VideoPlayerController? _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _playNext();
  }

  Future<void> _playNext() async {
    if (_index >= widget.frames.length) return;
    final url = (widget.frames[_index]['url'] ?? '') as String;
    final isAsset = url.startsWith('asset://');
    final source = isAsset ? url.replaceFirst('asset://', 'assets/') : url;

    _controller?.dispose();
    _controller = isAsset
        ? VideoPlayerController.asset(source)
        : VideoPlayerController.networkUrl(Uri.parse(source));

    await _controller!.initialize();
    await _controller!.play();
    _controller!.addListener(() async {
      if (_controller!.value.isCompleted) {
        setState(() => _index++);
        if (_index < widget.frames.length) {
          await _playNext();
        }
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio == 0 ? 16/9 : _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}
