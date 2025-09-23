import 'package:flutter/material.dart';
import '../services/asl_service.dart';

class AslDemoScreen extends StatefulWidget {
  const AslDemoScreen({super.key});
  @override State<AslDemoScreen> createState() => _AslDemoScreenState();
}

class _AslDemoScreenState extends State<AslDemoScreen> {
  final ctrl = TextEditingController();
  String? rendered;
  bool busy = false;

  Future<void> _render() async {
    setState(()=>busy=true);
    rendered = await AslService.render(ctrl.text);
    setState(()=>busy=false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASL Prototype')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Text → ASL')),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(onPressed: busy ? null : _render, child: const Text('Render to ASL')),
              const SizedBox(width: 12),
              if (busy) const CircularProgressIndicator(),
            ]),
            const SizedBox(height: 24),
            if (rendered!=null) Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Rendered (stub): $rendered\n[Play] [Pause] [Captions]'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
