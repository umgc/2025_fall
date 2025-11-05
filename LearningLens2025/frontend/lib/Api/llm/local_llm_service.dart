import 'package:fllama/fllama.dart';
import 'package:flutter/foundation.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'dart:async';
import 'package:xml/xml.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:learninglens_app/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learninglens_app/services/download_manager.dart';

class ToolFunction {
  final String name;
  final String description;
  final String parametersAsString;
  const ToolFunction({
    required this.description,
    required this.name,
    required this.parametersAsString,
  });
}

// class to run LLM locally.
class LocalLLMService implements LLM {
  static final LocalLLMService _instance = LocalLLMService._internal();
  factory LocalLLMService() => _instance;
  LocalLLMService._internal();

  int? _runningRequestId;
  ToolFunction? _tool;

  var _temperature = 0.5;
  var _topP = 1.0;

  String errorMessage = "";

  // if longer than max tokens, output cuts off
  @override
  int maxOutputTokens = 4000;
  @override
  int contextSize = 16000;
  @override
  double tokenCount = .25;
  @override
  String url = "";
  @override
  // Local LLM has no key
  String apiKey = "";

  @override
  String model = LocalStorageService.getLocalLLMPath();

  Completer<String> completer = Completer<String>();

  void configureToken({int? maxTokens}) {
    if (maxTokens != null) maxOutputTokens = maxTokens;
  }

  @override
  Future<String> getChatResponse(String prompt) async {
    return await runModel(prompt);
  }

  @override
  Future<String> postToLlm(String prompt) async {
    return await runModel(prompt);
  }

  /// Run the model with a prompt and return the final response
  Future<String> runModel(
    String prompt, {
    List<Map<String, dynamic>>? context,
    int? maxTokenSet,
    int? contextSizeSet,
    double? tokenCountSet,
  }) async {
    model = LocalStorageService.getLocalLLMPath();
    if (model == "") {
      return "Please specify the model path";
    }

    List<Message>? convertedContext = context?.map((entry) {
      final role = Role.values.firstWhere((r) => r.name == entry['role']);
      final message = entry['content'] as String;
      return Message(role, message);
    }).toList();

    // set the params if they exist
    maxOutputTokens = maxTokenSet ?? maxOutputTokens;
    contextSize = contextSizeSet ?? contextSize;
    tokenCount = tokenCountSet ?? tokenCount;

    String finalResponse = "";

    // model id for the web build (DO NOT use WEB for now / WIP).
    String mlcModelId = MlcModelId.qwen05b;

    // model path for the desktop build.

    String mmprojPath = "";

    var messageText = prompt;

    convertedContext?.add(Message(Role.user, messageText));

    print(messageText);

    final request = OpenAiRequest(
      tools: [
        if (_tool != null)
          Tool(
            name: _tool!.name,
            jsonSchema: _tool!.parametersAsString,
          ),
      ],
      maxTokens: maxOutputTokens.round(),
      messages: [
        Message(Role.system, 'You are a chatbot.'),
        Message(Role.user, messageText),
      ],
      numGpuLayers: 99,
      /* this seems to have no adverse effects in environments w/o GPU support, ex. Android and web */
      modelPath: kIsWeb ? mlcModelId : model,
      mmprojPath: mmprojPath,
      frequencyPenalty: 0.0,
      // Don't use below 1.1, LLMs without a repeat penalty
      // will repeat the same token.
      presencePenalty: 1.1,
      topP: _topP,
      // 22.9s for 249 input tokens with 20K context for SmolLM3.
      // 22.9s for 249 input tokens with 4K context for SmolLM3.
      contextSize: contextSize,
      // Don't use 0.0, some models will repeat
      // the same token.
      temperature: _temperature,
      logger: (log) {
        if (log.contains('<unused')) {
          // 25-03-11: Added because Gemma 3 outputs so many that it
          // can break the VS Code log viewer.
          return;
        }
        if (log.contains('ggml_')) {
          // 25-03-11: Added because that's the biggest clutter-er left
          // when trying to get logs reduced down to compare Gemma 3 working vs.
          // not-working cases.
          return;
        }
        // ignore: avoid_print
        print('[llama.cpp] $log');
      },
    );

    List<String> responseBuff = [];

    // This is required, otherwise the fllama will crash if using fllamaChat
    await fllamaChatTemplateGet(model);

    int requestId = await fllamaChat(request, (response, responseJson, done) {
      responseBuff.add(response);
      print(response);
      if (done) {
        _runningRequestId = null;
        finalResponse = _getFinalResponse(responseBuff);

        if (completer.isCompleted) {
          completer = Completer<String>();
        }
        // strip thinking, if not using a chat model.
        final regex = RegExp(r'<think>.*?<\/think>', dotAll: true);
        completer.complete(finalResponse.replaceAll(regex, '').trim());
      }
    });

    _runningRequestId = requestId;

    // Wait until inference finishes
    while (_runningRequestId != null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return completer.future;
  }

  bool get isRunning => _runningRequestId != null;

  // method to make sure that the last repsonse wasn't a dummy
  // (sometimes it returns a random Chinese characters if using Deepseek)
  String _getFinalResponse(List<String> responseBuff) {
    // Start from the end, find the last non-empty response
    for (int i = responseBuff.length - 1; i >= 0; i--) {
      if (responseBuff[i].trim().isNotEmpty && responseBuff[i].length > 4) {
        return responseBuff[i];
      }
    }
    // fallback: if all entries are empty, return error message
    return "ERROR: Local LLM failed to produce a response";
  }

  // method to run model with previous contexts
  Future<String> runModel2(
    List<Map<String, dynamic>>? context, {
    int? maxTokenSet,
    int? contextSizeSet,
    double? tokenCountSet,
  }) async {
    model = LocalStorageService.getLocalLLMPath();
    if (model == "") {
      return "Please specify the model path";
    }

    List<Message> convertedContext = context!.map((entry) {
      final role = Role.values.firstWhere((r) => r.name == entry['role']);
      final message = entry['content'] as String;
      return Message(role, message);
    }).toList();

    // set the params if they exist
    maxOutputTokens = maxTokenSet ?? maxOutputTokens;
    contextSize = contextSizeSet ?? contextSize;
    tokenCount = tokenCountSet ?? tokenCount;

    String finalResponse = "";

    // model id for the web build (DO NOT use WEB for now / WIP).
    String mlcModelId = MlcModelId.qwen05b;

    // model path for the desktop build.

    String mmprojPath = "";

    final request = OpenAiRequest(
      tools: [
        if (_tool != null)
          Tool(
            name: _tool!.name,
            jsonSchema: _tool!.parametersAsString,
          ),
      ],
      maxTokens: maxOutputTokens.round(),
      messages: convertedContext,
      numGpuLayers: 99,
      /* this seems to have no adverse effects in environments w/o GPU support, ex. Android and web */
      modelPath: kIsWeb ? mlcModelId : model,
      mmprojPath: mmprojPath,
      frequencyPenalty: 0.0,
      // Don't use below 1.1, LLMs without a repeat penalty
      // will repeat the same token.
      presencePenalty: 1.1,
      topP: _topP,
      // 22.9s for 249 input tokens with 20K context for SmolLM3.
      // 22.9s for 249 input tokens with 4K context for SmolLM3.
      contextSize: contextSize,
      // Don't use 0.0, some models will repeat
      // the same token.
      temperature: _temperature,
      logger: (log) {
        if (log.contains('<unused')) {
          // 25-03-11: Added because Gemma 3 outputs so many that it
          // can break the VS Code log viewer.
          return;
        }
        if (log.contains('ggml_')) {
          // 25-03-11: Added because that's the biggest clutter-er left
          // when trying to get logs reduced down to compare Gemma 3 working vs.
          // not-working cases.
          return;
        }
        // ignore: avoid_print
        print('[llama.cpp] $log');
      },
    );

    List<String> responseBuff = [];

    // This is required, otherwise the fllama will crash if using fllamaChat
    await fllamaChatTemplateGet(model);

    int requestId = await fllamaChat(request, (response, responseJson, done) {
      responseBuff.add(response);
      print(response);
      if (done) {
        _runningRequestId = null;
        finalResponse = _getFinalResponse(responseBuff);

        if (completer.isCompleted) {
          completer = Completer<String>();
        }
        // strip thinking, if not using a chat model.
        final regex = RegExp(r'<think>.*?<\/think>', dotAll: true);
        completer.complete(finalResponse.replaceAll(regex, '').trim());
      }
    });

    _runningRequestId = requestId;

    // Wait until inference finishes
    while (_runningRequestId != null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return completer.future;
  }

  // Cancel the current inference if running
  void cancel({int? count}) {
    if (count == null && _runningRequestId != null) {
      fllamaCancelInference(_runningRequestId!);
      _runningRequestId = null;
    }
    if (count != null) {
      while (count! >= 0) {
        fllamaCancelInference(count);
        count--;
      }
    }
  }

  bool checkXMLValid(String input) {
    try {
      XmlDocument.parse(input);
      return true; // well-formed XML
    } catch (e) {
      errorMessage = e.toString();
      print('Invalid XML: $e');
      return false;
    }
  }

  bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkIfLoadedLocalLLMRecommended() async {
    final String path = LocalStorageService.getLocalLLMPath().toLowerCase();
    if (!path.contains("qwen")) {
      final result = await showDialog<bool>(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('⚠️Warning:'),
          content: Text(
            'The currently loaded Local LLM does not consistently generate a valid XML or json files used in Learning Management System.\n'
            'Proceeding could result in invalid XML or json output error.\n\n'
            'The recommended model for this task is 7B or higher reasoning models (Qwen).\n'
            'Do you want to continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Continue
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      return result ?? false;
    } else {
      return true;
    }
  }

  Future<bool> showCancelConfirmationDialog({int? count}) async {
    final result = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Confirmation'),
        content: Text('Are you sure you want to cancel the generation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // no
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            }, // yes
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result! && count != null) {
      cancel(count: count);
    } else if (result && count == null) {
      cancel();
    }
    return result;
  }

  @override
  Future<String> chat(
      {List<Map<String, dynamic>>? context,
      String? prompt,
      double temperature = 0.7,
      double topP = 1.0,
      double frequencyPenalty = 0.0,
      double presencePenalty = 0.0,
      bool stream = false}) async {
    return await runModel2(context);
  }

  // unused in local LLM;
  @override
  Future<String> generate(String prompt) {
    // TODO: implement generate
    throw UnimplementedError();
  }

  Future<void> handleInvalidXml() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final switchModel = await _showModelSwitchDialog(ctx);

    if (switchModel == true) {
      // User wants to switch to another model
      debugPrint('User chose to switch model.');
    } else {
      // User canceled
      debugPrint('User canceled model switch.');
    }
  }

  Future<bool?> _showModelSwitchDialog(BuildContext context) async {
    String? selectedModel = LocalStorageService.getLocalLLMPath()
        .split('models\\')
        .last
        .split(".gguf")
        .first;

    // Fetch available downloaded models
    final keys = await fetchModelKeys();
    await DownloadManager().init();
    final downloadedModels =
        keys.where((k) => DownloadManager().isDownloaded(k)).toList();

    return showDialog<bool>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Switch Model'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Would you like to switch to another downloaded model?',
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedModel,
                    isExpanded: true,
                    items: downloadedModels.map((key) {
                      return DropdownMenuItem(
                        value: key,
                        child: Text(key),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedModel = value!;
                      });
                      String modelPath =
                          await DownloadManager().getFilePath(value!);
                      LocalStorageService.saveLocalLLMPath(modelPath);
                      debugPrint('Model switched to: $value');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Use Selected Model'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<String>> fetchModelKeys() async {
    final downloadUrl = LocalStorageService.getLocalLLMDownloadURLPath();
    if (downloadUrl != '') {
      final url = Uri.parse(
        downloadUrl,
      );

      final List<String> modelKeys = [];

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final csvContent = response.body;

          for (var line in LineSplitter.split(csvContent)) {
            if (line.trim().isEmpty) continue;
            final parts = line.split(',');
            if (parts.isNotEmpty) {
              modelKeys.add(parts[0].trim());
            }
          }
        } else {
          print('Failed to fetch CSV: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching CSV: $e');
      }

      return modelKeys;
    } else {
      return [];
    }
  }

  // method for outputting stream.
  @override
  Stream<String> chatStream(
      {List<Map<String, dynamic>>? context,
      String? prompt,
      double? temperature,
      double? topP,
      double? frequencyPenalty,
      double? presencePenalty}) async* {
    try {
      model = LocalStorageService.getLocalLLMPath();

      List<Message>? convertedContext = context?.map((entry) {
        final role = Role.values.firstWhere((r) => r.name == entry['role']);
        final message = entry['content'] as String;
        return Message(role, message);
      }).toList();

      double temperatureInput = temperature ?? 0.7;

      // model id for the web build (DO NOT use WEB for now / WIP).
      String mlcModelId = MlcModelId.qwen05b;

      // model path for the desktop build.
      String mmprojPath = "";

      final request = OpenAiRequest(
        tools: [
          if (_tool != null)
            Tool(
              name: _tool!.name,
              jsonSchema: _tool!.parametersAsString,
            ),
        ],
        maxTokens: maxOutputTokens.round(),
        messages: convertedContext!,
        numGpuLayers: 99,
        /* this seems to have no adverse effects in environments w/o GPU support, ex. Android and web */
        modelPath: kIsWeb ? mlcModelId : model,
        mmprojPath: mmprojPath,
        frequencyPenalty: 0.0,
        // Don't use below 1.1, LLMs without a repeat penalty
        // will repeat the same token.
        presencePenalty: 1.1,
        topP: _topP,
        // 22.9s for 249 input tokens with 20K context for SmolLM3.
        // 22.9s for 249 input tokens with 4K context for SmolLM3.
        contextSize: contextSize,
        // Don't use 0.0, some models will repeat
        // the same token.
        temperature: temperatureInput,
        logger: (log) {
          if (log.contains('<unused')) {
            // 25-03-11: Added because Gemma 3 outputs so many that it
            // can break the VS Code log viewer.
            return;
          }
          if (log.contains('ggml_')) {
            // 25-03-11: Added because that's the biggest clutter-er left
            // when trying to get logs reduced down to compare Gemma 3 working vs.
            // not-working cases.
            return;
          }
          // ignore: avoid_print
          print('[llama.cpp] $log');
        },
      );

      // This is required, otherwise the fllama will crash if using fllamaChat
      await fllamaChatTemplateGet(model);

      final controller = StreamController<String>();
      String previous = '';
      int requestId = await fllamaChat(request, (response, responseJson, done) {
        if (!controller.isClosed) {
          if (response.isNotEmpty) {
            if (response.startsWith(previous)) {
              controller.add(response.substring(previous.length));
              previous = response;
            } else {
              // In case it doesn't follow pattern (rare)
              controller.add(response);
              previous = response;
            }
          }
          if (done) {
            controller.close();
            _runningRequestId = null;
          }
        }
      });

      _runningRequestId = requestId;
      yield* controller.stream;

      while (_runningRequestId != null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      print(e);
    }
  }
}
