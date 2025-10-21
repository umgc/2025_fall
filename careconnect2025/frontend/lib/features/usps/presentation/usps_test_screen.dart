import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:care_connect_app/providers/user_provider.dart';
import 'dart:html' as html;

class UspsTestScreen extends StatefulWidget {
  const UspsTestScreen({super.key});
  @override
  State<UspsTestScreen> createState() => _UspsTestScreenState();
}

class _UspsTestScreenState extends State<UspsTestScreen> {
  Map<String, dynamic>? digest;
  bool loading = false;
  String? error;
  bool isGoogleConnected = false;

  Future<void> _fetchDigest() async {
    setState(() { loading = true; error = null; });
    final base = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8080';

    // Get user ID to pass as parameter
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final userId = user?.id ?? 'demo-user';

    final url = '$base/api/usps/digest?userId=$userId';
    print('Fetching USPS digest for userId: $userId from: $url');

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

  Future<void> _checkGoogleConnection() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    final base = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8080';
    try {
      final dio = Dio();
      final resp = await dio.get('$base/api/email-credentials/status?userId=${user.id}');
      if (resp.statusCode == 200 && resp.data == true) {
        setState(() => isGoogleConnected = true);
      }
    } catch (e) {
      // Connection check failed, assume not connected
      setState(() => isGoogleConnected = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkGoogleConnection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh connection status when coming back from OAuth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGoogleConnection();
    });
  }

  Future<void> _clearCache() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final userId = user?.id ?? 'demo-user';

    final base = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8080';
    try {
      final dio = Dio();
      await dio.post('$base/api/usps/clear-cache?userId=$userId');
      print('Cache cleared successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared! Try fetching digest again.')),
      );
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }

  Future<void> _connectGoogleAccount() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final base = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8080';

    // Get actual current page URL from browser window
    final currentUrl = html.window.location.href;
    final authUrl = '$base/oauth/google/start?userId=${user.id}&returnUrl=${Uri.encodeComponent(currentUrl)}';

    print('Starting OAuth with return URL: $currentUrl');
    final uri = Uri.parse(authUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google authentication')),
        );
      }
    }
  }

  Widget _buildMailImage(String? imageDataUrl) {
    if (imageDataUrl == null || imageDataUrl.isEmpty) {
      return const Icon(Icons.markunread_mailbox);
    }

    // Handle CID references - these shouldn't be processed as base64
    if (imageDataUrl.startsWith('cid:')) {
      return const Icon(Icons.image_not_supported);
    }

    // Handle data URLs
    if (imageDataUrl.startsWith('data:')) {
      try {
        final base64Data = imageDataUrl.split(',').last;
        final bytes = const Base64Decoder().convert(base64Data);
        return Image.memory(
          bytes,
          width: 48,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
        );
      } catch (e) {
        return const Icon(Icons.image_not_supported);
      }
    }

    // Handle regular URLs
    if (imageDataUrl.startsWith('http')) {
      return Image.network(
        imageDataUrl,
        width: 48,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    }

    // Fallback for unknown formats
    return const Icon(Icons.image_not_supported);
  }

  @override
  Widget build(BuildContext context) {
    final mail = (digest?['mailPieces'] as List?) ?? const [];
    final pkgs = (digest?['packages'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('USPS Mail Digest')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Google Authentication Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mail, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Gmail Integration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGoogleConnected
                        ? '✅ Google account connected! You can now fetch USPS digests automatically.'
                        : 'Connect your Google account to automatically fetch USPS digests from Gmail.',
                      style: TextStyle(
                        color: isGoogleConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isGoogleConnected)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _connectGoogleAccount,
                          icon: const Icon(Icons.link),
                          label: const Text('Connect Google Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => isGoogleConnected = false);
                            _connectGoogleAccount();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reconnect Google Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Existing controls
            Row(children: [
              ElevatedButton(
                onPressed: loading ? null : _fetchDigest,
                child: const Text('Fetch Digest'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: loading ? null : _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Cache'),
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
                          leading: _buildMailImage(m['imageDataUrl']),
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
