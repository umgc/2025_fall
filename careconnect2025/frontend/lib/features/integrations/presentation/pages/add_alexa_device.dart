import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AddAlexaDeviceScreen extends StatefulWidget {
  const AddAlexaDeviceScreen({super.key});

  @override
  State<AddAlexaDeviceScreen> createState() => _AddAlexaDeviceScreenState();
}

class _AddAlexaDeviceScreenState extends State<AddAlexaDeviceScreen> {
  String _backendMsg = 'Loading...';

  String get _base {
    if (kIsWeb) return 'http://localhost:8080';                // web
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';                           // Android emulator
    }
    return 'http://localhost:8080';                            // desktop
  }

  @override
  void initState() {
    super.initState();
    _loadAlexaBackend();
  }

  Future<void> _loadAlexaBackend() async {
    try {
      final res = await http.get(Uri.parse('$_base/alexa/hello'));
      if (!mounted) return;
      setState(() => _backendMsg = res.body);
    } catch (e) {
      if (!mounted) return;
      setState(() => _backendMsg = 'Request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Alexa Device')),
      body: Center(
        child: Text(
          _backendMsg,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
