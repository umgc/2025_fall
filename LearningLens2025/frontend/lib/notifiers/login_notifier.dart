import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/google_classroom/google_lms_service.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/notifiers/login_state.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

enum LLMKey { openAI, perplexity, claude, grok, deepseek }

class LoginNotifier with ChangeNotifier {
  // ---------------------------------------
  // New: use these model objects
  // ---------------------------------------
  final LoginState _moodleState = LoginState();
  final LoginState _googleState = LoginState();

  // If you want external access to them, you can provide getters:
  LoginState get moodleState => _moodleState;
  LoginState get googleState => _googleState;

  // You can still store other fields here as needed
  bool _hasLLMKey = false;
  String? _username;
  String? _password;
  String? _moodleUrl;
  String? _clientID; // for Google
  // String? _otherError; // Uncomment if you want any global error
  UserRole? _role;

  bool get hasLLMKey => _hasLLMKey;
  String? get username => _username;
  String? get password => _password;
  String? get moodleUrl => _moodleUrl;
  UserRole? get role => _role;
  // Constructor
  LoginNotifier() {
    _loadLoginState(); // Load any saved login state on creation
  }

  // ---------------------------------------
  // Load from local storage
  // ---------------------------------------
  Future<void> _loadLoginState() async {
    // Moodle
    _moodleState.isLoggedIn = LmsFactory.getLmsServiceMoodle().isLoggedIn();
    _username = LocalStorageService.getUsername();
    _password = LocalStorageService.getPassword();
    _moodleUrl = LocalStorageService.getMoodleUrl();

    // Google
    _googleState.isLoggedIn = LmsFactory.getLmsServiceGoogle().isLoggedIn();
    _clientID = LocalStorageService.getGoogleClientId();

    // LLM Key
    _hasLLMKey = await _checkHasLLMKey();

    // Attempt auto-login if we had credentials
    await _autoLogin();
    notifyListeners();
  }

  // ---------------------------------------
  // Check existence of any LLM keys
  // ---------------------------------------
  Future<bool> _checkHasLLMKey() async {
    final openAIKey = LocalStorageService.getOpenAIKey();
    final perplexityKey = LocalStorageService.getPerplexityKey();
    final grokKey = LocalStorageService.getGrokKey();
    final deepseekKey = LocalStorageService.getDeepseekKey();

    return (openAIKey.isNotEmpty) ||
        (perplexityKey.isNotEmpty) ||
        (grokKey.isNotEmpty) ||
        (deepseekKey.isNotEmpty);
  }

  // ---------------------------------------
  // Auto-login if we have saved credentials
  // ---------------------------------------
  Future<void> _autoLogin() async {
    try {
      if (LocalStorageService.getSelectedClassroom() == LmsType.GOOGLE &&
          _clientID != null &&
          _clientID!.isNotEmpty) {
        await signInWithGoogle(_clientID!);
      } else if (LocalStorageService.getSelectedClassroom() == LmsType.MOODLE &&
          (_username != null && _username!.isNotEmpty) &&
          (_password != null && _password!.isNotEmpty) &&
          (_moodleUrl != null && _moodleUrl!.isNotEmpty)) {
        await signInWithMoodle(_username!, _password!, _moodleUrl!);
      } else {
        print('Auto-login skipped: Missing or empty credentials.');
      }
    } catch (e) {
      print('Auto-login Error: $e');
    }
  }

  // ---------------------------------------
  // Moodle: Sign-in
  // ---------------------------------------
  Future<void> signInWithMoodle(
      String username, String password, String moodleUrl) async {
    try {
      MoodleLmsService lms = LmsFactory.getLmsServiceMoodle();

      await lms.login(username, password, moodleUrl);

      if (!lms.isLoggedIn()) {
        // Logged in is false; set a custom error
        _moodleState.isLoggedIn = false;
        _moodleState.errorMessage = "Invalid username or password.";
        notifyListeners();
        return;
      }
      // Make sure moodle user is a teacher.
      final UserRole role = await lms.getUserRole();
      print(role);

      if (role == UserRole.teacher || role == UserRole.student) {
        // User is a teacher or student
        _moodleState.isLoggedIn = true;
        _moodleState.errorMessage = null; // Clear any old error
        _username = username;
        _password = password;
        _moodleUrl = moodleUrl;
        _role = role;

        // Save to local storage
        LocalStorageService.saveMoodleLoginState(_moodleState.isLoggedIn);
        LocalStorageService.saveCredentials(username, password);
        LocalStorageService.saveMoodleUrl(moodleUrl);
        LocalStorageService.saveUserRole(role);
      } else {
        // user is not a teacher or a student
        lms.logout();
        _moodleState.isLoggedIn = false;
        _moodleState.errorMessage = "User does not have a valid role";
      }

      notifyListeners();
    } catch (e) {
      // Catch the exception, set isLoggedIn = false, set error
      _moodleState.isLoggedIn = false;
      _moodleState.errorMessage = "Moodle login failed: ${e.toString()}";
      notifyListeners();
    }
  }

  // ---------------------------------------
  // Moodle: Sign-out
  // ---------------------------------------
  Future<void> signOutFromMoodle() async {
    _moodleState.isLoggedIn = false;
    _moodleState.errorMessage = null;
    _username = null;
    _password = null;
    _moodleUrl = null;

    // Clear from local storage
    LocalStorageService.clearMoodleLoginState();
    LocalStorageService.clearCredentials();
    LocalStorageService.clearMoodleUrl();

    // Reset LMS
    LmsFactory.getLmsService().resetLMSUserInfo();

    LocalStorageService.clearUserId();

    notifyListeners();
  }

  // ---------------------------------------
  // Google: Sign-in
  // ---------------------------------------
  Future<void> signInWithGoogle(String clientID) async {
    // if (_clientID == null) {
    //   throw Exception("GOOGLE_CLIENT_ID not found in .env file.");
    // }

    try {
      final GoogleLmsService googleLms = LmsFactory.getLmsServiceGoogle();
      await googleLms.loginOath(clientID);

      if (!googleLms.isLoggedIn()) {
        _googleState.isLoggedIn = false;
        _googleState.errorMessage = 'Google login failed.';
        LocalStorageService.saveGoogleLoginState(_googleState.isLoggedIn);
        notifyListeners();
        return;
      }

      final UserRole role = await googleLms.getUserRole();
      if (role == UserRole.teacher || role == UserRole.student) {
        _googleState.isLoggedIn = true;
        _googleState.errorMessage = null;
        _role = role;
        // Save to local storage
        LocalStorageService.saveUserRole(role);
        LocalStorageService.saveGoogleLoginState(_googleState.isLoggedIn);
        LocalStorageService.saveGoogleAccessToken(
            googleLms.getGoogleAccessToken());
        LocalStorageService.saveGoogleClientId(clientID);
      } else {
        googleLms.logout();
        _googleState.isLoggedIn = false;
        _googleState.errorMessage = 'User does not have a valid role';
      }
    } catch (e) {
      _googleState.isLoggedIn = false;
      _googleState.errorMessage = "Google login failed: ${e.toString()}";
    } finally {
      LocalStorageService.saveGoogleLoginState(_googleState.isLoggedIn);
      notifyListeners();
    }
  }

  // ---------------------------------------
  // Google: Sign-out
  // ---------------------------------------
  Future<void> signOutFromGoogle() async {
    try {
      LmsFactory.getLmsServiceGoogle().logout();
      _googleState.isLoggedIn = false;
      _googleState.errorMessage = null;

      LocalStorageService.clearGoogleLoginState();
      LocalStorageService.clearGoogleAccessToken();

      notifyListeners();
    } catch (error) {
      print("Google Sign-Out Error: $error");
      // Optionally set _googleState.errorMessage
      throw Exception("Google Sign-Out failed: $error");
    }
  }

  // ---------------------------------------
  // Example Classroom API request for Google
  // ---------------------------------------
  Future<void> makeClassroomApiRequest(String apiEndpoint, dynamic http) async {
    final accessToken = LocalStorageService.getGoogleAccessToken();

    if (accessToken != null) {
      try {
        final response = await http.get(
          Uri.parse(apiEndpoint),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          print('Classroom API Response: ${response.body}');
        } else {
          print(
              'Classroom API Error: ${response.statusCode} - ${response.body}');
          throw Exception(
              "Classroom API request failed: ${response.statusCode}");
        }
      } catch (e) {
        print('Error making Classroom API request: $e');
        throw Exception("Failed to make Classroom API request: $e");
      }
    } else {
      print('No Google access token available. User needs to sign in.');
      throw Exception("No access token available. Please sign in again.");
    }
  }

  // ---------------------------------------
  // Save the LLM key to local storage
  // ---------------------------------------
  Future<void> saveLLMKey(LLMKey key, String value) async {
    switch (key) {
      case LLMKey.openAI:
        LocalStorageService.saveOpenAIKey(value);
      case LLMKey.perplexity:
        LocalStorageService.savePerplexityKey(value);
      case LLMKey.grok:
        LocalStorageService.saveGrokKey(value);
      case LLMKey.claude:
      // If you had a Claude key, you could handle it here
      case LLMKey.deepseek:
        LocalStorageService.saveDeepseekKey(value);
    }

    _hasLLMKey = await _checkHasLLMKey();
    notifyListeners();
  }
}
