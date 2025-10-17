import 'package:care_connect_app/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/theme/app_theme.dart';

/// Dialog shown when user hasn't verified their email address
class EmailVerificationDialog extends StatefulWidget {
  final String email;

  const EmailVerificationDialog({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isResending = false;
  String? _resendMessage;
  String? _resendError;
  Timer? _pollingTimer;
  WebSocketChannel? _wsChannel;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 20; // 20 attempts * 3 seconds = 60 seconds
  bool _isPolling = true;
  bool _useWebSocket = true;
  bool _wsConnected = false;
  String _connectionMethod = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _startVerificationWaiting();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _wsChannel?.sink.close(status.normalClosure);
    super.dispose();
  }

  /// Start waiting for email verification using WebSocket with polling fallback
  void _startVerificationWaiting() {
    if (_useWebSocket) {
      _connectWebSocket();
    } else {
      _startPolling();
    }
  }

  /// Connect to WebSocket for real-time email verification notifications
  void _connectWebSocket() {
    try {
      // Connect to WebSocket endpoint
      // Note: Change this URL when backend is deployed
      final wsUrl = Uri.parse('ws://localhost:8080/ws/careconnect');
      _wsChannel = WebSocketChannel.connect(wsUrl);

      // Listen to WebSocket messages
      _wsChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _fallbackToPolling();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          if (_isPolling) {
            _fallbackToPolling();
          }
        },
      );

      // Send subscription message after a short delay to ensure connection
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _wsChannel != null) {
          _wsChannel!.sink.add(jsonEncode({
            'type': 'subscribe-email-verification',
            'email': widget.email,
          }));
          debugPrint('WebSocket subscription request sent for: ${widget.email}');
        }
      });

      if (mounted) {
        setState(() {
          _wsConnected = true;
          _connectionMethod = 'WebSocket (Real-time)';
        });
      }
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _fallbackToPolling();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      debugPrint('WebSocket message received: ${message['type']}');

      switch (message['type']) {
        case 'connection-established':
          debugPrint('WebSocket connection established');
          break;
        case 'email-verification-subscription-confirmed':
          if (mounted) {
            setState(() {
              _connectionMethod = 'WebSocket (Real-time) ✓';
            });
          }
          debugPrint('Subscription confirmed for: ${message['email']}');
          break;
        case 'email-verified':
          _handleEmailVerified();
          break;
        case 'error':
          debugPrint('WebSocket error: ${message['message']}');
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  /// Handle email verified notification
  void _handleEmailVerified() async {
    _pollingTimer?.cancel();
    _wsChannel?.sink.close(status.normalClosure);

    if (mounted) {
      // Show success message before closing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully! You can now log in.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Wait a moment for user to see the message
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop(true); // Return true to indicate verified
    }
  }

  /// Fallback to polling if WebSocket fails
  void _fallbackToPolling() {
    if (mounted) {
      setState(() {
        _useWebSocket = false;
        _wsConnected = false;
        _connectionMethod = 'HTTP Polling';
      });
    }
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_pollingAttempts >= _maxPollingAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isPolling = false;
          });
        }
        return;
      }

      _pollingAttempts++;
      await _checkVerificationStatus();
    });
  }

  void _retryPolling() {
    setState(() {
      _pollingAttempts = 0;
      _isPolling = true;
    });
    _startPolling();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      // Check verification status using dedicated endpoint that doesn't send emails
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.auth}/check-verification?email=${Uri.encodeComponent(widget.email)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['verified'] == true) {
          _handleEmailVerified();
        }
      }
      // Continue polling if not verified or other responses
    } catch (e) {
      // Continue polling on errors
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _resendMessage = null;
      _resendError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.auth}/resend-verification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _resendMessage = 'Verification email sent successfully!';
        });
      } else {
        setState(() {
          _resendError = 'Failed to send verification email. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _resendError = 'Error sending verification email: $e';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.email_outlined, color: AppTheme.primary, size: 28),
          SizedBox(width: 8),
          Text('Email Verification Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please check your email and click the verification link to activate your account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email Address',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your inbox and spam folder',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          if (_isPolling) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waiting for verification...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _useWebSocket
                              ? _connectionMethod
                              : 'Polling (${_pollingAttempts}/$_maxPollingAttempts)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_resendMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _resendMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_resendError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _resendError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        if (!_isPolling && !_useWebSocket)
          ElevatedButton.icon(
            onPressed: _retryPolling,
            icon: const Icon(Icons.replay),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isResending ? null : _resendVerificationEmail,
          icon: _isResending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh),
          label: Text(_isResending ? 'Sending...' : 'Resend Email'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}