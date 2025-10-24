import 'dart:async';
import 'package:flutter/material.dart';

class AslFingerspellPlayer extends StatefulWidget {
  final String text;
  const AslFingerspellPlayer({super.key, required this.text});

  @override
  State<AslFingerspellPlayer> createState() => _AslFingerspellPlayerState();
}

class _AslFingerspellPlayerState extends State<AslFingerspellPlayer> {
  int _pos = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) return;
      setState(() {
        _pos = (_pos + 1).clamp(0, widget.text.length);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('')));
    }
    final chars = widget.text.toUpperCase().characters.toList();
    final current = _pos < chars.length ? chars[_pos] : ' ';
    // If you uploaded letter images, you could map to assets/asl/fingerspelling/<letter>.png.
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          current,
          style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}
