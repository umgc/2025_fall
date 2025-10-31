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
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class UserSettings extends StatefulWidget {
  @override
  UserSettingsState createState() => UserSettingsState();
}

class UserSettingsState extends State<UserSettings> {
  String? _ggufModelPath;
  String? _gpuModel;
  String? _gpuVRAM;

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
  bool _modelsLoading = true;
  bool fetchModelsFail = false;

  double downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initCycle();
    if (!kIsWeb) {
      DownloadManager().init();
    }
    //_checkSelectedModelDownloaded();
  }

  bool get isWindows {
    try {
      return Platform.isWindows;
    } catch (_) {
      return false; // Safe fallback for unsupported platforms
    }
  }

  Future<void> _initCycle() async {
    await _loadStoredValues();
    await _fetchModelsCsv();
    await _loadStoredModel();
    if (isWindows &&
        !(LocalStorageService.hasGPUInfo() &&
            LocalStorageService.hasGPUVRam())) {
      await getWindowsGPUInfo();
    }
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
    final gpuModel = LocalStorageService.getGPUInfo();
    final gpuVRam = LocalStorageService.getGPUVRam();

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
      _gpuModel = gpuModel;
      _gpuVRAM = gpuVRam;
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
              // _buildApiKeyBlock(loginNotifier),

              _buildGGUFModelPicker(),

              const SizedBox(height: 20),
              const Divider(),
              // const SizedBox(height: 20),
              // const Divider(),

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

/*
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
  */

  Future<void> _loadStoredModel() async {
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

  // Fetch CSV from URL
  Future<void> _fetchModelsCsv() async {
    setState(() {
      fetchModelsFail = false;
    });
    final downloadUrl = LocalStorageService.getLocalLLMDownloadURLPath();
    if (downloadUrl != '') {
      final url = Uri.parse(
        downloadUrl,
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
    } else {
      setState(() {
        fetchModelsFail = true;
        _modelsLoading = false;
      });
    }
  }

  // detects GPU for Local LLM and displays message accordingly
  Future<void> getWindowsGPUInfo() async {
    // only available in Windows
    // Run dxdiag and export results to a text file
    final result = await Process.run('dxdiag', ['/t', 'gpu_info.txt']);

    if (result.exitCode == 0) {
      final file = File('gpu_info.txt');

      // Read safely as Latin1 (Windows ANSI)
      final bytes = await file.readAsBytes();
      final content = const Latin1Decoder().convert(bytes);

      // Extract GPU name and VRAM
      final gpuMatch = RegExp(r'Card name:\s*(.*)').firstMatch(content);
      final vramMatch = RegExp(r'Dedicated Memory:\s*(.*)').firstMatch(content);

      final gpu = gpuMatch?.group(1)?.trim() ?? 'Unknown GPU';
      final vram = vramMatch?.group(1)?.trim() ?? 'Unknown VRAM';

      LocalStorageService.saveGPUInfo(gpu);
      LocalStorageService.saveGPUVRam(vram);

      setState(() {
        _gpuModel = gpu;
        _gpuVRAM = vram;
      });

      print("GPU : $gpu VRAM: $vram");

      await file.delete();
    } else {
      print('dxdiag failed: ${result.stderr}');
    }
  }

  Widget buildGpuStatusMessage() {
    final ValueNotifier<bool> expanded = ValueNotifier(false);

    final String gpuName = _gpuModel ?? 'Unknown GPU';
    final String vramInfo = _gpuVRAM ?? 'Unknown VRAM';

    String message;
    Color messageColor;
    IconData icon;

    if (LocalStorageService.hasGPUInfo() &&
        LocalStorageService.hasGPUVRam() &&
        (LocalStorageService.getGPUInfo() != "Unknown GPU" &&
            LocalStorageService.getGPUVRam() != "Unknown VRAM")) {
      final double? vramGB =
          double.tryParse(vramInfo.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (vramGB != null && vramGB / 1000 >= 8.0) {
        messageColor = Colors.green;
        icon = Icons.check_circle;
        message =
            '''Your system meets the recommended hardware requirements for running a Local Large Language model (LLM).
A discrete GPU with at least 8 GB of VRAM has been detected, providing acceptable performance for 7B models - the minimum recommended size for using the local LLM function.

As a general guideline, each 1 billion (1B) model parameters typically requires about 1 GB of VRAM.
For every 1 GB of VRAM that is unavailable, an additional 2 GB of system memory (RAM) is recommended to compensate. 

Your GPU may not be optimal for models larger than 7B, so please ensure your system has enough memory before attempting to run larger models. 
Ensure your graphics drivers are up to date and that sufficient resources are available for optimal operation.

For the best performance and accuracy, using and external LLM is still recommended.''';
      } else {
        messageColor = Colors.orange;
        icon = Icons.warning;
        message =
            '''A discrete GPU has been detected; however, the available VRAM appears to be below 8 GB.
            Running larger models locally may result in slow performance, instability, or loading failures.
            As a general guideline, each 1 billion (1B) model parameter typically requires about 1 GB of VRAM.
            For every 1 GB of VRAM that is unavailable, an additional 2 GB of system memory (RAM) is recommended to compensate.

            Smaller models may still operate, but responsiveness and quality may be limited. Please ensure your system has enough memory before attempting to run larger models.'
            For the best performance and accuracy, using an external LLM is recommended.''';
      }
    } else {
      messageColor = Colors.redAccent;
      icon = Icons.dangerous;
      message =
          '''Warning: No discrete GPU was detected, or GPU information is unavailable.
          Running a local large language model (LLM) on integrated graphics or low-memory systems is not recommended.
          This configuration may lead to severe lag, instability, or complete failure of the application.
          Small models (1B) may still operate, but responsiveness and quality may be limited.
          For the best performance and accuracy, using an external LLM is strongly recommended.''';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: expanded,
        builder: (context, isExpanded, _) {
          return GestureDetector(
            onTap: () => expanded.value = !expanded.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: messageColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPU: $gpuName, VRAM: $vramInfo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black54,
                    ),
                  ],
                ),
                if (isExpanded)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0, left: 28.0, right: 8.0),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showModelDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information about different local models'),
        content: SingleChildScrollView(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.black, fontSize: 15, height: 1.5),
              children: [
                TextSpan(
                  text:
                      'There are many different local large language models (LLMs) you can run on your own device, each designed for specific strengths.\n'
                      'Some excel at reasoning and analysis, while others are better for conversation, structured tasks, or coding.\n'
                      'For EduLense application, we recommend using reasoning models for their accuracy and structured thought.\n\n'
                      'Here’s a quick overview of the main types and when to use each:\n\n',
                ),

                // --- Reasoning Models ---
                TextSpan(
                  text: 'Reasoning Models\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Best for: Math, logic, and multi-step reasoning.\nExamples: DeepSeek R1/Qwen, Qwen-Math, Llama 3-Reasoning.\nUse when: You need accuracy and structured thought.\n\n',
                ),

                // --- Balanced / General Models ---
                TextSpan(
                  text: 'Balanced / General Models\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Best for: Everyday writing, summarizing, or general chat.\nExamples: Qwen 2.5, DeepSeek-Chat, Llama 3.\nUse when: You want good all-around performance and natural tone.\n\n',
                ),

                // --- Chat Models ---
                TextSpan(
                  text: 'Chat Models\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Best for: Conversations, tutoring, and dialogue.\nExamples: Qwen-Chat, Mistral-Chat, Phi-3.\nUse when: You need fast, fluent, human-like responses.\n\n',
                ),

                // --- Instruction Models ---
                TextSpan(
                  text: 'Instruction Models\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Best for: Structured or formatted outputs (e.g., JSON, XML, Markdown).\nExamples: Llama 3-Instruct, Qwen-Instruct, DeepSeek-Instruct.\nUse when: Tasks require the model to follow directions exactly.\n\n',
                ),

                // --- Coding Models ---
                TextSpan(
                  text: 'Coding Models\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Best for: Code generation, debugging, and technical explanations.\nExamples: DeepSeek-Coder, CodeLlama, Qwen-Coder.\nUse when: Working in programming or automation tasks.\n\n',
                ),

                // --- Lightweight Models ---
                TextSpan(
                  text: 'Lightweight Models\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Best for: Fast responses on limited hardware.\nExamples: Phi-3-mini, TinyLlama, Mistral 7B.\nUse when: You prioritize speed or have less GPU memory.\n',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

// Updated GGUF Model Picker
  Widget _buildGGUFModelPicker() {
    // support for web:
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local LLM Feature is not available in web',
            style: TextStyle(fontSize: 20),
          ),
        ],
      );
    } else {
      // Not a Web Build
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
            'Local LLM:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '''
⚠️ Hardware & Model Requirements

EduLense recommends using a reasoning model with at least 7B parameters to reliably generate structured content (e.g., JSON, XML) for platforms like Moodle and Google Classroom.
Only GGUF models are currently supported.

Recommended hardware specifications for running local LLMs are:
• A discrete GPU with at least 8GB or more VRAM
• 12GB or higher system memory (RAM)

Systems using integrated graphics or low-memory setups may experience severe lag, crashes, or complete failure to load.
For the best performance and accuracy, using an API-hosted LLM is recommended.

Please refer to the information below to better understand your device's GPU and memory specifications.
''',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.4, // for readability across lines
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          buildGpuStatusMessage(),

          const Divider(),
          const SizedBox(height: 8),
          if (fetchModelsFail)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.warning, color: Colors.red, size: 32),
                Text(
                  'Fetching recommended local LLM failed. Please check your connection or try again.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          const Text(
            'Load Local LLM:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text(
                    'Information about different types of local models'),
                onPressed: () => showModelDetails(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                ),
              ),
            ),
          ),
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
                    final modelName = _ggufModelPath!
                        .split('models\\')
                        .last
                        .split(".gguf")
                        .first;
                    final isSelected = key == modelName;

                    return DropdownMenuItem(
                      value: key,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(key),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Text(
                                  '(Selected)',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
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
                            DownloadManager()
                                .startDownload(selectedModel!, url);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Currently Loaded Model: $_ggufModelPath',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  if (_ggufModelPath != "")
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _ggufModelPath = "";
                          LocalStorageService.saveLocalLLMPath("");
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Unload Model'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(width: 10),
        ],
      );
    }
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
