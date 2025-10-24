import 'package:flutter/material.dart';
import 'asl_fingerspell_player.dart';
import 'asl_video_player.dart';

class AslPlayer extends StatelessWidget {
  final String mode; // 'video' or 'fingerspell'
  final List<Map<String, dynamic>> frames;
  final String text;

  const AslPlayer({super.key, required this.mode, required this.frames, required this.text});

  @override
  Widget build(BuildContext context) {
    if (mode == 'video' && frames.isNotEmpty) {
      return AslVideoPlayer(frames: frames);
    }
    return AslFingerspellPlayer(text: text);
  }
}
