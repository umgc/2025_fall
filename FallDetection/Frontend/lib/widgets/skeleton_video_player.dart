// lib/widgets/skeleton_video_player.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/skeleton_frame.dart';
import 'skeleton_painter.dart';

/// Widget that plays back skeleton frames as a video
/// Used for alert skeleton files that contain multiple frames
class SkeletonVideoPlayer extends StatefulWidget {
  final List<SkeletonFrame> frames;
  final double frameRate; // Frames per second (default: 25 fps)
  final bool autoPlay;
  final int? totalEpochTime; // Total time span from skeleton data
  final int? numFrames; // Number of frames from skeleton data
  
  const SkeletonVideoPlayer({
    super.key,
    required this.frames,
    this.frameRate = 25.0,
    this.autoPlay = true,
    this.totalEpochTime,
    this.numFrames,
  });
  
  @override
  State<SkeletonVideoPlayer> createState() => _SkeletonVideoPlayerState();
}

class _SkeletonVideoPlayerState extends State<SkeletonVideoPlayer> {
  int currentFrameIndex = 0;
  bool isPlaying = false;
  Timer? _playbackTimer;
  
  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && widget.frames.isNotEmpty) {
      _play();
    }
  }
  
  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
  
  void _play() {
    if (widget.frames.isEmpty) return;
    
    setState(() {
      isPlaying = true;
    });
    
    // Calculate frame duration from skeleton data if available
    Duration frameDuration;
    if (widget.totalEpochTime != null && widget.numFrames != null && widget.numFrames! > 0) {
      // Use actual timing from skeleton data
      // epochTime appears to be the total duration, so divide by frames for interval
      final intervalMs = widget.totalEpochTime! / widget.numFrames!;
      
      // Clamp the interval to reasonable values (10ms to 1000ms)
      final clampedInterval = intervalMs.clamp(10.0, 1000.0);
      frameDuration = Duration(milliseconds: clampedInterval.round());
      
      final calculatedFPS = 1000.0 / clampedInterval;
      print('🎬 Using skeleton timing: ${clampedInterval}ms per frame (~${calculatedFPS.toStringAsFixed(1)} FPS)');
    } else {
      // Fallback to provided frame rate
      frameDuration = Duration(milliseconds: (1000 / widget.frameRate).round());
      print('🎬 Using fallback timing: ${1000/widget.frameRate}ms per frame (${widget.frameRate} FPS)');
    }
    
    _playbackTimer = Timer.periodic(frameDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        currentFrameIndex++;
        if (currentFrameIndex >= widget.frames.length) {
          // Loop back to start
          currentFrameIndex = 0;
        }
      });
    });
  }
  
  void _pause() {
    setState(() {
      isPlaying = false;
    });
    _playbackTimer?.cancel();
  }
  
  void _restart() {
    setState(() {
      currentFrameIndex = 0;
    });
    if (isPlaying) {
      _playbackTimer?.cancel();
      _play();
    }
  }
  
  void _previousFrame() {
    if (widget.frames.isEmpty) return;
    setState(() {
      currentFrameIndex = (currentFrameIndex - 1) % widget.frames.length;
      if (currentFrameIndex < 0) {
        currentFrameIndex = widget.frames.length - 1;
      }
    });
  }
  
  void _nextFrame() {
    if (widget.frames.isEmpty) return;
    setState(() {
      currentFrameIndex = (currentFrameIndex + 1) % widget.frames.length;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'No skeleton frames available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    print('🎬 SkeletonVideoPlayer: ${widget.frames.length} frames, current: $currentFrameIndex');
    
    final currentFrame = widget.frames[currentFrameIndex];
    
    return Column(
      children: [
        // Video display (transparent overlay for skeleton only)
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomPaint(
                painter: SkeletonPainter(currentFrame),
                child: Container(), // Transparent container
              ),
            ),
          ),
        ),
        
        // Controls
        Container(
          color: Colors.grey[900],
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.restart_alt, color: Colors.white),
                    onPressed: _restart,
                    tooltip: 'Restart',
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: _previousFrame,
                    tooltip: 'Previous Frame',
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: isPlaying ? _pause : _play,
                    tooltip: isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: Colors.white),
                    onPressed: _nextFrame,
                    tooltip: 'Next Frame',
                  ),
                ],
              ),
              
              // Frame slider
              Row(
                children: [
                  Text(
                    '${currentFrameIndex + 1}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentFrameIndex.toDouble(),
                      min: 0,
                      max: (widget.frames.length - 1).toDouble(),
                      onChanged: (value) {
                        setState(() {
                          currentFrameIndex = value.round();
                        });
                      },
                    ),
                  ),
                  Text(
                    '${widget.frames.length}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              
              // Frame info
              Text(
                'Frame ${currentFrameIndex + 1} of ${widget.frames.length} • '
                '${currentFrame.people.length} person(s) detected',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
