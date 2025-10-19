import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AddAlexaDeviceScreen extends StatefulWidget {
  const AddAlexaDeviceScreen({super.key});

  @override
  State<AddAlexaDeviceScreen> createState() => _AddAlexaDeviceScreenState();
}

class _AddAlexaDeviceScreenState extends State<AddAlexaDeviceScreen> {
  List<String> _reminders = [];
  String _errorMsg = '';
  bool _isLoading = true;

  String get _base {
    if (kIsWeb) return 'https://03ad072af7a4.ngrok-free.app';                // web
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';                           // Android emulator
    }
    return 'http://localhost:8080';                            // desktop
  }

  static const String REMINDER_PATH = '/alexa/calenderReminders';

  @override
  void initState() {
    super.initState();
    _loadAlexaBackend();
  }

  Future<void> _loadAlexaBackend() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$_base$REMINDER_PATH'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        // Parse the JSON array
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _reminders = jsonList.cast<String>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Failed to load reminders: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Request failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Alexa Device')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMsg.isNotEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMsg,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadAlexaBackend,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Current Reminders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _reminders.isEmpty
                            ? const Text('No reminders found')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _reminders.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text('${index + 1}'),
                                      ),
                                      title: Text(
                                        _reminders[index],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadAlexaBackend,
                        child: const Text('Refresh'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }
}