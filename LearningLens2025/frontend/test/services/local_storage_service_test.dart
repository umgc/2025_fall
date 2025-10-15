import 'package:flutter_test/flutter_test.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// trigger github actions.

void main() {
  setUpAll(() async {
    // Load the dotenv file before running any test
    await dotenv.load(fileName: ".env");
  });

  setUp(() async {
    // Set up a mock SharedPreferences instance
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('saveCredentials stores and retrieves credentials', () {
    LocalStorageService.saveCredentials('testUser', 'testPass');

    expect(LocalStorageService.getUsername(), 'testUser');
    expect(LocalStorageService.getPassword(), 'testPass');
  });

  test('getUsername defaults to dotenv if no stored credentials', () {
    expect(
        LocalStorageService.getUsername(), dotenv.env['MOODLE_USERNAME'] ?? '');
  });

  test('clearCredentials removes stored credentials', () {
    LocalStorageService.saveCredentials('testUser', 'testPass');
    LocalStorageService.clearCredentials();

    expect(
        LocalStorageService.getUsername(), dotenv.env['MOODLE_USERNAME'] ?? '');
    expect(
        LocalStorageService.getPassword(), dotenv.env['MOODLE_PASSWORD'] ?? '');
  });

  test('saveTheme and getTheme work correctly', () {
    LocalStorageService.saveTheme('dark');

    expect(LocalStorageService.getTheme(), 'dark');
  });

  test('saveLoginState and getIsLoggedIn work correctly', () {
    LocalStorageService.saveMoodleLoginState(true);

    expect(LocalStorageService.isLoggedIntoMoodle(), true);
  });

  test('clearLoginState resets login state', () {
    LocalStorageService.saveMoodleLoginState(true);
    LocalStorageService.clearMoodleLoginState();

    expect(LocalStorageService.isLoggedIntoMoodle(), false);
  });

  test('save and retrieve API keys', () {
    LocalStorageService.saveOpenAIKey('test-api-key');

    expect(LocalStorageService.getOpenAIKey(), 'test-api-key');
  });

  test('clearOpenAIKey removes stored API key', () {
    LocalStorageService.saveOpenAIKey('test-api-key');
    LocalStorageService.clearOpenAIKey();

    expect(
        LocalStorageService.getOpenAIKey(), dotenv.env['openai_apikey'] ?? '');
  });

  test('getMoodleUrl trims trailing /', () {
    LocalStorageService.saveMoodleUrl("test/url/");

    expect(LocalStorageService.getMoodleUrl(), 'test/url');
  });

  test('getAILoggingUrl defaults to dotenv if no stored credentials', () {
    String? actual = dotenv.env['AI_LOGGING_URL'];
    if (actual != null && actual.endsWith("/")) {
      actual = actual.substring(0, actual.length - 1);
    }
    expect(LocalStorageService.getAILoggingUrl(), actual ?? '');
  });

  test('getAILoggingUrl trims trailing /', () {
    LocalStorageService.saveAILoggingUrl("test/url/");

    expect(LocalStorageService.getAILoggingUrl(), 'test/url');
  });

  test('clearAiLoggingUrl removes logging URL', () {
    LocalStorageService.saveAILoggingUrl("testLoggingUrl");
    LocalStorageService.clearAILoggingUrl();
    String? actual = dotenv.env['AI_LOGGING_URL'];
    if (actual != null && actual.endsWith("/")) {
      actual = actual.substring(0, actual.length - 1);
    }

    expect(LocalStorageService.getAILoggingUrl(), actual ?? '');
  });
}
