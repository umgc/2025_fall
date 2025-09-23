import 'package:flutter/material.dart';
import '../services/asl_service.dart';

class AslDemoScreen extends StatefulWidget {
  const AslDemoScreen({super.key});
  @override State<AslDemoScreen> createState() => _AslDemoScreenState();
}

class _AslDemoScreenState extends State<AslDemoScreen> {
  final ctrl = TextEditingController();
  String? rendered;
  bool loading = false;

  Future<void> _render() async {
    setState(() => loading = true);
    rendered = await AslService.render(ctrl.text);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASL Prototype')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Enter text to render to ASL',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: loading ? null : _render,
                  child: loading ? const CircularProgressIndicator() : const Text('Render to ASL'),
                ),
                const SizedBox(width: 12),
                if (rendered != null) const Text('Ready', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: rendered == null
                  ? const Text('ASL panel (placeholder)')
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.slideshow, size: 48),
                        SizedBox(height: 8),
                        Text('Playing placeholder ASL clip'),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
