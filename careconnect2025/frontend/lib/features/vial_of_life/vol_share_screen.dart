import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vol_api_service.dart';

class VolShareScreen extends StatefulWidget {
  final int patientId;
  const VolShareScreen({super.key, required this.patientId});

  @override
  State<VolShareScreen> createState() => _VolShareScreenState();
}

class _VolShareScreenState extends State<VolShareScreen> {
  bool loading = true;
  String? payload;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await VolApiService.sharePayload(widget.patientId);
      setState(() {
        payload = p;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load share payload';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Vial')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: loading
              ? const CircularProgressIndicator()
              : (error != null)
                  ? Text(error!)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Share Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        SelectableText(payload ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: payload == null
                              ? null
                              : () async {
                                  await Clipboard.setData(ClipboardData(text: payload!));
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied to clipboard')),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(height: 8),
                        const Text('We can switch this to a QR later without changing the backend.'),
                      ],
                    ),
        ),
      ),
    );
  }
}
