import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:learninglens_app/notifiers/theme_notifier.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/download_manager.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class UserSettings extends StatefulWidget {
  @override
  UserSettingsState createState() => UserSettingsState();
}

class UserSettingsState extends State<UserSettings> {
  String? _ggufModelPath;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _moodleUrlController = TextEditingController();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _grokKeyController = TextEditingController();
  final TextEditingController _preplexityKeyController =
      TextEditingController();
  final TextEditingController _deepSeekKeyController = TextEditingController();

  final TextEditingController _googleClientIdController =
      TextEditingController();

  Map<String, String> modelMap = {};
  Set<String> downloadedModels = {};
  String? selectedModel;
  bool isDownloading = false;
  http.Client? _httpClient;
  bool _isCancelled = false;
  String? _currentDownloadPath;
  bool _modelsLoading = true;

  double downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initCycle();
    DownloadManager().init();
    //_checkSelectedModelDownloaded();
  }

  Future<void> _initCycle() async {
    await _loadStoredValues();
    await _fetchModelsCsv();
    await _loadStoredModel();
  }

  Future<void> _loadStoredValues() async {
    final username = LocalStorageService.getUsername();
    final password = LocalStorageService.getPassword();
    final moodleUrl = LocalStorageService.getMoodleUrl();
    final apiKey = LocalStorageService.getOpenAIKey();
    final preplexityKey = LocalStorageService.getPerplexityKey();
    final grokKey = LocalStorageService.getGrokKey();
    final googleClientId = LocalStorageService.getGoogleClientId();
    final deepSeekKey = LocalStorageService.getDeepseekKey();
    final localLLMPath = LocalStorageService.getLocalLLMPath();

    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _moodleUrlController.text = moodleUrl;
      _apiKeyController.text = apiKey;
      _preplexityKeyController.text = preplexityKey;
      _grokKeyController.text = grokKey;
      _deepSeekKeyController.text = deepSeekKey;
      _googleClientIdController.text = googleClientId;
      _ggufModelPath = localLLMPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginNotifier = Provider.of<LoginNotifier>(context);
    final themeColor = Provider.of<ThemeNotifier>(context).primaryColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Settings',
        onRefresh: () {
          // Add refresh logic here
        },
        userprofileurl: MoodleLmsService().profileImage ?? '',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Moodle Login Block
              _buildMoodleLoginBlock(loginNotifier),

              const SizedBox(height: 20),
              const Divider(),

              // Google Classroom Login Block
              _buildGoogleClassroomLoginBlock(loginNotifier),

              const SizedBox(height: 20),
              const Divider(),

              // API Key Block
              _buildApiKeyBlock(loginNotifier),

              _buildGGUFModelPicker(),

              const SizedBox(height: 20),
              const Divider(),

              // Theme Color Picker
              Text(
                'Theme Color Picker:',
                style: TextStyle(fontSize: 20),
              ),
              ElevatedButton(
                onPressed: _pickColor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text('Pick Theme Color'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------
  // Moodle Login Block
  // -------------------------------------------
  Widget _buildMoodleLoginBlock(LoginNotifier loginNotifier) {
    final moodleState = loginNotifier.moodleState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moodle Login:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(labelText: 'Username'),
          enabled: !moodleState.isLoggedIn,
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
          enabled: !moodleState.isLoggedIn,
        ),
        TextField(
          controller: _moodleUrlController,
          decoration: InputDecoration(labelText: 'Moodle URL'),
          enabled: !moodleState.isLoggedIn,
        ),
        const SizedBox(height: 10),
        if (!moodleState.isLoggedIn)
          ElevatedButton(
            onPressed: () {
              loginNotifier.signInWithMoodle(
                _usernameController.text.trim(),
                _passwordController.text.trim(),
                _moodleUrlController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Login to Moodle'),
          ),
        if (moodleState.isLoggedIn)
          ElevatedButton(
            onPressed: loginNotifier.signOutFromMoodle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout from Moodle'),
          ),
        if (moodleState.errorMessage?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              moodleState.errorMessage!,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------
  // Google Classroom Login Block
  // -------------------------------------------
  Widget _buildGoogleClassroomLoginBlock(LoginNotifier loginNotifier) {
    final googleState = loginNotifier.googleState; // convenience variable

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Google Classroom Login:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: _googleClientIdController,
          decoration: InputDecoration(labelText: 'Client ID'),
          enabled: !googleState.isLoggedIn, // Make it non-editable
        ),
        const SizedBox(height: 10),
        if (!googleState.isLoggedIn)
          ElevatedButton(
            onPressed: () {
              loginNotifier
                  .signInWithGoogle(_googleClientIdController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Login to Google Classroom'),
          ),
        if (googleState.isLoggedIn)
          ElevatedButton(
            onPressed: loginNotifier.signOutFromGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout from Google Classroom'),
          ),
        if (googleState.errorMessage?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              googleState.errorMessage!,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------
  // API Key Block
  // -------------------------------------------
  Widget _buildApiKeyBlock(LoginNotifier loginNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Keys:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        _buildApiKeyField(
          label: 'OpenAI API Key',
          controller: _apiKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.openAI,
        ),
        _buildApiKeyField(
          label: 'Preplexity AI API Key',
          controller: _preplexityKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.perplexity,
        ),
        _buildApiKeyField(
          label: 'Grok AI API Key',
          controller: _grokKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.grok,
        ),
        _buildApiKeyField(
          label: 'Deepseek AI API Key',
          controller: _deepSeekKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.deepseek,
        ),
      ],
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required TextEditingController controller,
    required LoginNotifier loginNotifier,
    required LLMKey keyType,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: label),
          enabled: controller.text.isEmpty,
          // If you want to disable the TextField once it has a value,
          // keep this. Otherwise, feel free to remove "enabled: controller.text.isEmpty".
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            loginNotifier.saveLLMKey(keyType, controller.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('Save'),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _loadStoredModel() async {
    // Load previously saved GGUF path
    final storedPath = LocalStorageService.getLocalLLMPath();
    String? modelName;

    if (storedPath.isNotEmpty) {
      // Find the model name in the modelMap that matches the stored path
      modelMap.forEach((key, url) {
        final fileName = url.split('/').last; // assuming file name matches
        if (storedPath.endsWith(fileName)) {
          modelName = key;
        }
      });
    }

    setState(() {
      _ggufModelPath = storedPath;
      selectedModel = modelName; // set default selection
    });
  }

  // Fetch CSV from GitHub
  Future<void> _fetchModelsCsv() async {
    final url = Uri.parse(
      'https://raw.githubusercontent.com/ssung13/SWEN670F2025/main/models.csv',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final csvContent = response.body;
        final Map<String, String> tempMap = {};
        for (var line in LineSplitter.split(csvContent)) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length >= 2) tempMap[parts[0].trim()] = parts[1].trim();
        }
        setState(() {
          modelMap = tempMap;
          if (modelMap.isNotEmpty) {
            selectedModel = modelMap.keys.first;
          }
          _modelsLoading = false;
        });
      } else {
        print('Failed to fetch CSV: ${response.statusCode}');
        setState(() => _modelsLoading = false);
      }
    } catch (e) {
      print('Error fetching CSV: $e');
      setState(() => _modelsLoading = false);
    }
  }

// Updated GGUF Model Picker
  Widget _buildGGUFModelPicker() {
    if (_modelsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Local LLM Model:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Dropdown with checkmark
            Expanded(
              child: DropdownButton<String>(
                value: selectedModel,
                isExpanded: true,
                hint: const Text('Select a model'),
                onChanged: (value) {
                  setState(() {
                    selectedModel = value;
                  });
                },
                items: modelMap.keys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(key),
                        ValueListenableBuilder<double>(
                          valueListenable:
                              DownloadManager().progressNotifier(key),
                          builder: (context, progress, child) {
                            final isDownloaded = progress >= 1.0 ||
                                DownloadManager().isDownloaded(key);

                            if (isDownloaded) {
                              return Row(
                                children: [
                                  const Icon(Icons.check,
                                      color: Colors.green, size: 18),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Downloaded',
                                    style: TextStyle(
                                        color: Colors.green, fontSize: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete model',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Model'),
                                          content: Text(
                                              'Are you sure you want to delete "$key"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await DownloadManager()
                                            .deleteModel(key);
                                        LocalStorageService.saveLocalLLMPath(
                                            "");
                                        _ggufModelPath = "";

                                        if (selectedModel == key) {
                                          setState(() {
                                            selectedModel = null;
                                          });
                                        }
                                        // Rebuild to reflect change
                                        (context as Element).markNeedsBuild();
                                      }
                                    },
                                  ),
                                ],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 10),

            // Right-hand panel
            if (selectedModel != null)
              ValueListenableBuilder<double>(
                valueListenable:
                    DownloadManager().progressNotifier(selectedModel!),
                builder: (context, progress, child) {
                  final isDownloading =
                      DownloadManager().isDownloading(selectedModel!);
                  final isDownloaded = progress >= 1.0 ||
                      DownloadManager().isDownloaded(selectedModel!);

                  if (isDownloaded) {
                    final modelName = _ggufModelPath!
                        .split('models\\')
                        .last
                        .split(".gguf")
                        .first;
                    print(modelName);
                    if (modelName != selectedModel!) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final path = await DownloadManager()
                                  .getFilePath(selectedModel!);
                              LocalStorageService.saveLocalLLMPath(path);
                              setState(() {
                                _ggufModelPath = path;
                              });
                              debugPrint('Model loaded: $path');
                            },
                            child: const Text('Load this model'),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: null,
                            child: const Text('Loaded'),
                          ),
                        ],
                      );
                    }
                  } else if (isDownloading) {
                    return Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            DownloadManager().cancelDownload(selectedModel!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  } else {
                    final url = modelMap[selectedModel!];
                    return ElevatedButton(
                      onPressed: () {
                        if (url != null) {
                          DownloadManager().startDownload(selectedModel!, url);
                        }
                      },
                      child: const Text('Download'),
                    );
                  }
                },
              ),
          ],
        ),
        // Pick GGUF
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['gguf'],
                );
                if (result != null && result.files.single.path != null) {
                  setState(() {
                    selectedModel = result.files.single.path!
                        .split('\\')
                        .last
                        .split(".gguf")
                        .first;

                    if (!modelMap.containsKey(selectedModel)) {
                      modelMap[selectedModel!] =
                          ""; // URL is null since it’s local
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('Select GGUF Model From Device'),
            ),
          ],
        ),
        if (_ggufModelPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Currently Loaded Model: $_ggufModelPath',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        const Divider(),
      ],
    );
  }

  // -------------------------------------------
  // Theme Color Picker
  // -------------------------------------------
  void _pickColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pick a theme color',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            height: 50,
            child: BlockPicker(
              pickerColor: Provider.of<ThemeNotifier>(context, listen: false)
                  .primaryColor,
              onColorChanged: (color) {
                Provider.of<ThemeNotifier>(context, listen: false)
                    .updateTheme(color);
              },
              availableColors: [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Select'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
