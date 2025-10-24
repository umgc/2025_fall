import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../shared/asl/asl_engine.dart';
import '../../shared/asl/asl_player.dart';

class AslDemoScreen extends StatefulWidget {
  const AslDemoScreen({super.key});
  @override
  State<AslDemoScreen> createState() => _AslDemoScreenState();
}

class _AslDemoScreenState extends State<AslDemoScreen> {
  final _controller = TextEditingController(text: 'Your appointment is Tuesday at 3pm');
  AslResult? _result;
  late final AslEngine _engine;
  final String _baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _engine = AslEngine(_baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASL Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Type text to render in ASL'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final r = await _engine.translate(_controller.text.trim());
                setState(() => _result = r);
              },
              child: const Text('Render ASL'),
            ),
            const SizedBox(height: 16),
            if (_result != null)
              AslPlayer(mode: _result!.mode, frames: _result!.frames, text: _result!.text),
          ],
        ),
      ),
    );
  }
}
