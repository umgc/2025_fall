// lib/services/google_auth_helper.dart
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class SimpleGoogleAuth {
  static const String clientId = '51530330417-a5kp7dl5rmasfh9748nh30ie3eaj3b45.apps.googleusercontent.com';
  static const String redirectUri = 'http://localhost:3000/auth_callback.html';
  
  // UPDATED SCOPES - These are critical for grading functionality
  static const String scope = 
    'https://www.googleapis.com/auth/classroom.courses.readonly '
    'https://www.googleapis.com/auth/classroom.rosters.readonly '
    'https://www.googleapis.com/auth/classroom.student-submissions.students.readonly '
    'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly '
    'https://www.googleapis.com/auth/classroom.coursework.students '
    'https://www.googleapis.com/auth/classroom.coursework.me '
    'https://www.googleapis.com/auth/classroom.courseworkmaterials.readonly '
    'https://www.googleapis.com/auth/drive.readonly '
    'https://www.googleapis.com/auth/drive.file '
    'https://www.googleapis.com/auth/userinfo.profile '
    'https://www.googleapis.com/auth/userinfo.email';

  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static Completer<String?> _authCompleter = Completer<String?>();

  /// Start OAuth authentication flow
  static Future<String?> signIn() async {
    print('🚀 Starting Google authentication with full permissions...');
    
    // Reset completer if already completed
    if (_authCompleter.isCompleted) {
      _authCompleter = Completer<String?>();
    }

    // Clear any existing tokens
    _clearTokens();

    // Set up message listener BEFORE opening popup
    _setupMessageListener();

    // Build auth URL with all required parameters
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scope,
      'access_type': 'offline', // Request refresh token
      'prompt': 'consent', // Force consent screen to ensure all permissions
      'include_granted_scopes': 'true',
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    print('🔗 Opening authentication URL...');
    print('   Scopes requested: ${scope.split(' ').length} scopes');

    // Open popup for authentication
    final popup = html.window.open(
      authUrl.toString(),
      'google_auth',
      'width=600,height=700,scrollbars=yes,resizable=yes,top=100,left=100',
    );

    if (popup == null) {
      print('❌ Failed to open popup - popup blocked?');
      return null;
    }

    print('🪟 Authentication popup opened');

    // Wait for authentication (with timeout)
    final result = await Future.any([
      _authCompleter.future,
      Future.delayed(const Duration(minutes: 10), () {
        print('⏰ Authentication timeout after 10 minutes');
        return null;
      }),
    ]);

    // Close popup
    try {
      popup.close();
    } catch (e) {
      print('⚠️ Could not close popup: $e');
    }

    if (result != null) {
      print('✅ Authentication successful!');
      print('   Token length: ${result.length}');
      
      // Immediate validation
      await _validateTokenImmediate();
    } else {
      print('❌ Authentication failed or timed out');
    }

    return result;
  }

  /// Set up message listener for OAuth callback
  static void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      if (event.data is String) {
        try {
          final data = jsonDecode(event.data);
          print('📨 Received message: ${data['type']}');
          
          if (data['type'] == 'auth_success') {
            final accessToken = data['access_token'];
            final refreshToken = data['refresh_token'];
            
            if (accessToken != null && accessToken.isNotEmpty) {
              _accessToken = accessToken;
              _refreshToken = refreshToken; // Store refresh token
              
              // Set expiry (default 1 hour if not provided)
              final expiresIn = data['expires_in'] ?? 3600;
              _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
              
              print('✅ Tokens received and stored');
              print('   Access token length: ${_accessToken!.length}');
              print('   Has refresh token: ${_refreshToken != null}');
              print('   Expires at: $_tokenExpiry');
              
              if (!_authCompleter.isCompleted) {
                _authCompleter.complete(accessToken);
              }
            } else {
              print('❌ No access token in response');
              if (!_authCompleter.isCompleted) {
                _authCompleter.complete(null);
              }
            }
          } else if (data['type'] == 'auth_error') {
            print('❌ Authentication error: ${data['error']}');
            if (!_authCompleter.isCompleted) {
              _authCompleter.complete(null);
            }
          }
        } catch (e) {
          print('❌ Error processing message: $e');
          if (!_authCompleter.isCompleted) {
            _authCompleter.complete(null);
          }
        }
      }
    });
  }

  /// Validate token immediately after receiving it
  static Future<void> _validateTokenImmediate() async {
    if (_accessToken == null) return;
    
    try {
      print('🔍 Validating token...');
      
      // Test with a simple API call
      final response = await http.get(
        Uri.parse('https://classroom.googleapis.com/v1/courses?pageSize=1'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 Validation result: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Token is valid and working');
        
        // Check token info for scopes
        await _checkTokenScopes();
      } else if (response.statusCode == 401) {
        print('❌ Token is invalid (401)');
        _clearTokens();
      } else {
        print('⚠️ Unexpected response: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Token validation error: $e');
    }
  }

  /// Check what scopes the token actually has
  static Future<void> _checkTokenScopes() async {
    if (_accessToken == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$_accessToken'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenScopes = data['scope'].toString();
        
        print('📋 Token scopes check:');
        print('   All scopes: $tokenScopes');
        
        // Check critical scopes
        final requiredScopes = [
          'classroom.coursework.students',
          'classroom.coursework.me',
          'classroom.courses',
          'classroom.student-submissions',
          'drive',
        ];
        
        bool hasAllRequired = true;
        for (final required in requiredScopes) {
          final hasScope = tokenScopes.contains(required);
          print('   ${hasScope ? "✅" : "❌"} $required');
          if (!hasScope) hasAllRequired = false;
        }
        
        if (hasAllRequired) {
          print('🎉 All required scopes granted!');
        } else {
          print('⚠️ Missing some required scopes - functionality may be limited');
        }
      }
    } catch (e) {
      print('⚠️ Could not check token scopes: $e');
    }
  }

  /// Clear all stored tokens
  static void _clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  /// Get current access token (with automatic refresh if needed)
  static Future<String?> getValidToken() async {
    // If no token, return null
    if (_accessToken == null) {
      print('⚠️ No access token available');
      return null;
    }
    
    // If token is expired, try to refresh
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      print('🔄 Token expired, attempting refresh...');
      
      if (_refreshToken != null) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          print('✅ Token refreshed successfully');
          return newToken;
        }
      }
      
      print('❌ Could not refresh token');
      _clearTokens();
      return null;
    }
    
    return _accessToken;
  }

  /// Refresh access token using refresh token
  static Future<String?> _refreshAccessToken() async {
    if (_refreshToken == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': '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', // Your client secret
          'refresh_token': _refreshToken!,
          'grant_type': 'refresh_token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        
        // Update expiry
        final expiresIn = data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        return _accessToken;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    
    return null;
  }

  /// Get access token (with validation)
  static String? get accessToken => _accessToken;

  /// Check if user is authenticated
  static bool get isAuthenticated => _accessToken != null;

  /// Test token by making API call
  static Future<bool> testToken() async {
    final token = await getValidToken();
    if (token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('https://classroom.googleapis.com/v1/courses?pageSize=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Token test error: $e');
      return false;
    }
  }

  /// Check if token has grading permissions
  static Future<bool> hasGradingPermission() async {
    final token = await getValidToken();
    if (token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$token'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scopes = data['scope'].toString();
        return scopes.contains('classroom.coursework.students') ||
               scopes.contains('classroom.coursework.me');
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
    
    return false;
  }

  /// Force re-authentication
  static Future<String?> forceReAuth() async {
    print('🔄 Forcing re-authentication...');
    _clearTokens();
    return signIn();
  }

  /// Sign out
  static Future<void> signOut() async {
    final currentToken = _accessToken;
    
    _clearTokens();
    
    // Reset completer
    if (_authCompleter.isCompleted) {
      _authCompleter = Completer<String?>();
    }
    
    // Revoke token on server
    if (currentToken != null) {
      try {
        await http.post(
          Uri.parse('https://oauth2.googleapis.com/revoke?token=$currentToken'),
        );
        print('✅ Token revoked on server');
      } catch (e) {
        print('⚠️ Could not revoke token: $e');
      }
    }
    
    print('✅ Signed out successfully');
  }

  /// Get authentication status
  static Future<Map<String, dynamic>> getAuthStatus() async {
    return {
      'hasToken': _accessToken != null,
      'tokenLength': _accessToken?.length ?? 0,
      'isExpired': _tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!),
      'expiry': _tokenExpiry?.toIso8601String(),
      'isAuthenticated': isAuthenticated,
      'isValid': await testToken(),
    };
  }
}