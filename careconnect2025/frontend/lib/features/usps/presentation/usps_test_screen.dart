import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class UspsTestScreen extends StatefulWidget {
  const UspsTestScreen({super.key});
  @override
  State<UspsTestScreen> createState() => _UspsTestScreenState();
}

class _UspsTestScreenState extends State<UspsTestScreen> {
  Map<String, dynamic>? digest;
  bool loading = false;
  String? error;

  Future<void> _fetchDigest() async {
    setState(() { loading = true; error = null; });
    final base = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8080';
    final url = '$base/api/usps/digest';

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ));

      final resp = await dio.get(url);
      if (resp.statusCode == 200) {
        setState(() {
          digest = resp.data is Map<String, dynamic>
              ? (resp.data as Map<String, dynamic>)
              : json.decode(json.encode(resp.data)) as Map<String, dynamic>;
        });
      } else {
        setState(() => error = 'HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openUri(String? u) async {
    if (u == null || u.isEmpty) return;
    final uri = Uri.parse(u);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mail = (digest?['mailpieces'] as List?) ?? const [];
    final pkgs = (digest?['packages'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('USPS Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              ElevatedButton(
                onPressed: loading ? null : _fetchDigest,
                child: const Text('Fetch Digest'),
              ),
              const SizedBox(width: 12),
              if (loading) const CircularProgressIndicator(),
            ]),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (pkgs.isNotEmpty) ...[
                    const Text('Packages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final p in pkgs)
                      Card(
                        child: ListTile(
                          title: Text(p['trackingNumber'] ?? 'Unknown'),
                          subtitle: Text('Expected: ${p['expectedDateIso'] ?? '—'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.local_shipping),
                            onPressed: () => _openUri(p['actions']?['track']),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (mail.isNotEmpty) ...[
                    const Text('Mail Pieces', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final m in mail)
                      Card(
                        child: ListTile(
                          leading: (m['imageDataUrl'] != null)
                              ? Image.memory(
                            // quick inline base64 decode (data URL acceptable for demo)
                            const Base64Decoder().convert(
                              (m['imageDataUrl'] as String).split(',').last,
                            ),
                            width: 48, height: 32, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                          )
                              : const Icon(Icons.markunread_mailbox),
                          title: Text(m['sender'] ?? 'Sender'),
                          subtitle: Text(m['summary'] ?? 'Summary'),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openUri(m['actions']?['dashboard']),
                          ),
                        ),
                      ),
                  ],
                  if ((mail.isEmpty && pkgs.isEmpty) && digest != null)
                    const Center(child: Text('No items in digest')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
