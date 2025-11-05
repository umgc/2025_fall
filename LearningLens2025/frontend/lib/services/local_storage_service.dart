import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This class manages local storage operations using SharedPreferences and dotenv.
/// TODO:
/// - Encrypt sensitive data stored in SharedPreferences.
/// - Implement periodic server checks for API availability (Moodle, OpenAI, Claude, Perplexity).
class LocalStorageService {
  static late SharedPreferences _prefs;

  /// Initializes SharedPreferences. MUST be called once at app startup.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Saves user credentials.
  static void saveCredentials(String username, String password) {
    _prefs.setStringList('credentials', [username, password]);
  }

  /// Retrieves stored username, falling back to dotenv.
  static String getUsername() {
    final credentials = _prefs.getStringList('credentials');
    return credentials != null && credentials.isNotEmpty
        ? credentials[0]
        : dotenv.env['MOODLE_USERNAME'] ?? '';
  }

  /// Retrieves stored password, falling back to dotenv.
  static String getPassword() {
    final credentials = _prefs.getStringList('credentials');
    return credentials != null && credentials.length > 1
        ? credentials[1]
        : dotenv.env['MOODLE_PASSWORD'] ?? '';
  }

  /// Clears stored credentials.
  static void clearCredentials() {
    _prefs.remove('credentials');
  }

  /// Saves theme preference.
  static void saveTheme(String themeName) {
    _prefs.setString('theme', themeName);
  }

  /// Retrieves stored theme preference.
  static String getTheme() {
    return _prefs.getString('theme') ?? 'light'; // Default to 'light' theme
  }

  /// Clears theme preference.
  static void clearTheme() {
    _prefs.remove('theme');
  }

  /// Saves login state.
  static void saveMoodleLoginState(bool isLoggedIn) {
    _prefs.setBool('isLoggedIntoMoodle', isLoggedIn);
  }

  /// Retrieves login state.
  static bool isLoggedIntoMoodle() {
    return _prefs.getBool('isLoggedIntoMoodle') ?? false;
  }

  /// Clears login state.
  static void clearMoodleLoginState() {
    _prefs.remove('isLoggedIntoMoodle');
  }

  /// Saves login state.
  static void saveGoogleLoginState(bool isLoggedIn) {
    _prefs.setBool('isLoggedIntoGoogle', isLoggedIn);
  }

  /// Retrieves login state.
  static bool isLoggedIntoGoogle() {
    return _prefs.getBool('isLoggedIntoGoogle') ?? false;
  }

  /// Clears login state.
  static void clearGoogleLoginState() {
    _prefs.remove('isLoggedIntoGoogle');
  }

  /// Saves Moodle URL.
  static void saveMoodleUrl(String moodleUrl) {
    _prefs.setString('moodleUrl', moodleUrl);
  }

  /// Saves current user role
  static void saveUserRole(UserRole role) {
    _prefs.setString('role', role.toString());
  }

  /// Gets current user role.
  static UserRole getUserRole() {
    if (_prefs.getString('role') == 'UserRole.teacher') {
      return UserRole.teacher;
    }

    return UserRole.student;
  }

  /// Retrieves Moodle URL from storage or dotenv.
  static String getMoodleUrl() {
    String url =
        _prefs.getString('moodleUrl') ?? dotenv.env['MOODLE_URL'] ?? '';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Clears Moodle URL.
  static void clearMoodleUrl() {
    _prefs.remove('moodleUrl');
  }

  /// Saves primary color.
  static void savePrimaryColor(String colorHex) {
    _prefs.setString('primaryColor', colorHex);
  }

  /// Retrieves primary color.
  static String getPrimaryColor() {
    return _prefs.getString('primaryColor') ?? '#FFFFFF'; // Default to white
  }

  /// Saves OpenAI API key.
  static void saveOpenAIKey(String openAIKey) {
    _prefs.setString('openAIKey', openAIKey);
  }

  /// Retrieves OpenAI API key from storage or dotenv.
  static String getOpenAIKey() {
    return _prefs.getString('openAIKey') ?? dotenv.env['openai_apikey'] ?? '';
  }

  static bool hasOpenAIKey() {
    return getOpenAIKey().isNotEmpty;
  }

  /// Clears OpenAI API key.
  static void clearOpenAIKey() {
    _prefs.remove('openAIKey');
  }

  // /// Saves Claude API key.
  // static void saveClaudeKey(String claudeKey) {
  //   _prefs.setString('claudeKey', claudeKey);
  // }

  // /// Retrieves Claude API key from storage or dotenv.
  // static String getClaudeKey() {
  //   return _prefs.getString('claudeKey') ?? dotenv.env['claude_apiKey'] ?? '';
  // }

  // /// Clears Claude API key.
  // static void clearClaudeKey() {
  //   _prefs.remove('claudeKey');
  // }

  /// Saves Perplexity API key.
  static void savePerplexityKey(String perplexityKey) {
    _prefs.setString('perplexityKey', perplexityKey);
  }

  /// Retrieves Perplexity API key from storage or dotenv.
  static String getPerplexityKey() {
    return _prefs.getString('perplexityKey') ??
        dotenv.env['perplexity_apikey'] ??
        '';
  }

  static bool hasPerplexityKey() {
    return getPerplexityKey().isNotEmpty;
  }

  /// Clears Perplexity API key.
  static void clearPerplexityKey() {
    _prefs.remove('perplexityKey');
  }

  /// Saves Grok API key.
  static void saveGrokKey(String grokKey) {
    _prefs.setString('grokKey', grokKey);
  }

  /// Retrieves Grok API key from storage or dotenv.
  static String getGrokKey() {
    return _prefs.getString('grokKey') ?? dotenv.env['grokKey'] ?? '';
  }

  static bool hasGrokKey() {
    return getGrokKey().isNotEmpty;
  }

  /// Clears Grok API key.
  static void clearGrokKey() {
    _prefs.remove('grokKey');
  }

  /// Saves Deepseek API key.
  static void saveDeepseekKey(String deepseekKey) {
    _prefs.setString('deepseekKey', deepseekKey);
  }

  /// Retrieves Deepseek API key from storage or dotenv.
  static String getDeepseekKey() {
    return _prefs.getString('deepseekKey') ??
        dotenv.env['deepseek_apiKey'] ??
        '';
  }

  /// Checks if Deepseek API key exists.
  static bool hasDeepseekKey() {
    return getDeepseekKey().isNotEmpty;
  }

  /// Clears Deepseek API key.
  static void clearDeepseekKey() {
    _prefs.remove('deepseekKey');
  }

  // saves path to the selected local llm model
  static void saveLocalLLMPath(String path) {
    _prefs.setString('LOCAL_LLM_PATH', path);
  }

  // Retrieves the path to the selected local llm model from storage or dotenv
  static String getLocalLLMPath() {
    return _prefs.getString('LOCAL_LLM_PATH') ??
        dotenv.env['LOCAL_LLM_PATH'] ??
        '';
  }

  // Retrieves the url where the csv file with the models/download urls are located.
  static String getLocalLLMDownloadURLPath() {
    return dotenv.env['LOCAL_MODEL_DOWNLOAD_URL_PATH'] ?? '';
  }

  // returns whether or not the local LLM has a path
  static hasLocalLLMPath() {
    return getLocalLLMPath().isNotEmpty;
  }

  // Retrieves the GPU Name from the storage
  static String getGPUInfo() {
    return _prefs.getString('GPU_NAME') ?? "";
  }

  static hasGPUInfo() {
    return getGPUInfo().isNotEmpty;
  }

  static void saveGPUInfo(String name) {
    _prefs.setString('GPU_NAME', name);
  }

  static String getGPUVRam() {
    return _prefs.getString('GPU_VRAM') ?? "";
  }

  static hasGPUVRam() {
    return getGPUVRam().isNotEmpty;
  }

  static void saveGPUVRam(String size) {
    _prefs.setString('GPU_VRAM', size);
  }

  static String getGoogleClientId() {
    return _prefs.getString('GOOGLE_CLIENT_ID') ??
        dotenv.env['GOOGLE_CLIENT_ID'] ??
        '';
  }

  static void saveGoogleClientId(String clientId) {
    _prefs.setString('GOOGLE_CLIENT_ID', clientId);
  }

  static void clearGoogleClientId() {
    _prefs.remove('GOOGLE_CLIENT_ID');
  }

  static saveGoogleAccessToken(String accessToken) {
    _prefs.setString('GOOGLE_ACCESS_TOKEN', accessToken);
  }

  static String? getGoogleAccessToken() {
    return _prefs.getString('GOOGLE_ACCESS_TOKEN');
  }

  static clearGoogleAccessToken() {
    _prefs.remove('GOOGLE_ACCESS_TOKEN');
  }

  // Save LmsType as an INTEGER
  static void saveSelectedClassroom(LmsType type) {
    _prefs.setInt('selectedClassroom', type.index);
  }

  // Get LmsType from stored INTEGER
  static LmsType getSelectedClassroom() {
    int? storedValue = _prefs.getInt('selectedClassroom');
    return storedValue != null ? LmsType.values[storedValue] : LmsType.MOODLE;
  }

  // Clear stored selection
  static void clearSelectedClassroom() {
    _prefs.remove('selectedClassroom');
  }

  static saveAILoggingUrl(String url) {
    _prefs.setString('AI_LOGGING_URL', url);
  }

  static String getAILoggingUrl() {
    String url = _prefs.getString('AI_LOGGING_URL') ??
        dotenv.env['AI_LOGGING_URL'] ??
        '';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String getCodeEvalUrl() {
    String url =
        _prefs.getString('CODE_EVAL_URL') ?? dotenv.env['CODE_EVAL_URL'] ?? '';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String getGameUrl() {
    String url = _prefs.getString('GAME_URL') ?? dotenv.env['GAME_URL'] ?? '';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String getReflectionsUrl() {
    String url = _prefs.getString('REFLECTIONS_URL') ??
        dotenv.env['REFLECTIONS_URL'] ??
        '';
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static void clearAILoggingUrl() {
    _prefs.remove('AI_LOGGING_URL');
  }

  static void clearCodeEvalUrl() {
    _prefs.remove('CODE_EVAL_URL');
  }

  static void clearGameUrl() {
    _prefs.remove('GAME_URL');
  }

  static void clearReflectionsUrl() {
    _prefs.remove('REFLECTIONS_URL');
  }

  static hasLLMKey() {
    return getOpenAIKey().isNotEmpty ||
        getGrokKey().isNotEmpty ||
        getPerplexityKey().isNotEmpty ||
        getDeepseekKey().isNotEmpty;
  }

  static bool userHasLlmKey(LlmType llm) {
    if (llm == LlmType.CHATGPT) {
      return LocalStorageService.hasOpenAIKey();
    } else if (llm == LlmType.GROK) {
      return LocalStorageService.hasGrokKey();
    } else if (llm == LlmType.PERPLEXITY) {
      return LocalStorageService.hasPerplexityKey();
    } else if (llm == LlmType.DEEPSEEK) {
      return LocalStorageService.hasDeepseekKey();
    }

    return false;
  }

  static bool canUserAccessApp() {
    bool isLoggedIntoGoogleClassroom =
        LmsFactory.getLmsServiceGoogle().isLoggedIn() &&
            LocalStorageService.hasLLMKey();
    bool isLoggedIntoMoodle = LmsFactory.getLmsServiceMoodle().isLoggedIn() &&
        LocalStorageService.hasLLMKey();
    return isMoodle() ? isLoggedIntoMoodle : isLoggedIntoGoogleClassroom;
  }

  static String getClassroom() {
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE
        ? 'Moodle'
        : 'Google';
  }

  static bool isMoodle() {
    print(LocalStorageService.getSelectedClassroom());
    return LocalStorageService.getSelectedClassroom() == LmsType.MOODLE;
  }

  /// Generic method to save a string value
  static void setString(String key, String value) {
    _prefs.setString(key, value);
  }

  /// Generic method to retrieve a string value
  static String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Saves current user ID
  static void saveUserId(String userId) {
    _prefs.setString('userId', userId);
  }

  /// Clears current user ID
  static void clearUserId() {
    _prefs.remove('userId');
  }

  /// Retrieves current user ID
  static String? getUserId() {
    return _prefs.getString('userId');
  }
}
