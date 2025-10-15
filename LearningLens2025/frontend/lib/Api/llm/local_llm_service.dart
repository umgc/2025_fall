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
  int contextSize = 15984;
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
  Future<String> runModel(String prompt) async {
    model = LocalStorageService.getLocalLLMPath();

    print(model);
    if (model == "") {
      return "Please specify the model path";
    }

    String finalResponse = "";

    // model id for the web build (DO NOT use WEB for now / WIP).
    String mlcModelId = MlcModelId.qwen05b;

    // model path for the desktop build.

    String mmprojPath = "";

    var messageText = prompt;

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

  // Cancel the current inference if running
  void cancel() {
    if (_runningRequestId != null) {
      fllamaCancelInference(_runningRequestId!);
      _runningRequestId = null;
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

  @override
  Future<String> chat(
      {List<Map<String, dynamic>>? context,
      String? prompt,
      double temperature = 0.7,
      double topP = 1.0,
      double frequencyPenalty = 0.0,
      double presencePenalty = 0.0,
      bool stream = false}) {
    // TODO: implement chat
    throw UnimplementedError();
  }

  @override
  Future<String> generate(String prompt) {
    // TODO: implement generate
    throw UnimplementedError();
  }

  /// Main XML repair loop
  Future<String?> handleInvalidXml(String brokenXml) async {
    bool repairSuccessful = false;
    bool cancelPressed = false;
    String repairedXml = brokenXml;

    while (!repairSuccessful && !cancelPressed) {
      // Ask user if they want to attempt repair
      final repairChoice =
          await _showRepairPromptDialog(navigatorKey.currentContext!);
      if (repairChoice != true) {
        cancelPressed = true;
        break;
      }

      // Show spinner dialog
      _showRepairInProgressDialog(navigatorKey.currentContext!);

      // try to repair
      final attempt = await _attemptRepairWithLocalLLM(repairedXml);

      // Close spinner safely
      final ctx = navigatorKey.currentContext;
      if (ctx != null && Navigator.canPop(navigatorKey.currentContext!)) {
        Navigator.pop(navigatorKey.currentContext!);
      }

      repairSuccessful = checkXMLValid(attempt);

      if (repairSuccessful) {
        repairedXml = attempt;
        final ctx2 = navigatorKey.currentContext;
        if (ctx2 != null) {
          await _showRepairSuccessDialog(navigatorKey.currentContext!);
        }
      } else {
        final retry =
            await _showRepairFailedDialog(navigatorKey.currentContext!);
        if (retry != true) cancelPressed = true;
      }
    }

    if (cancelPressed && !repairSuccessful) {
      final ctx3 = navigatorKey.currentContext;
      if (ctx3 != null) {
        await _showRepairCancelledDialog(navigatorKey.currentContext!);
      }
      return null;
    }

    return repairedXml;
  }

  // Call XML fix
  Future<String> _attemptRepairWithLocalLLM(String xml) async {
    String prompt =
        '''You are a strict XML validator and repair assistant. Given a broken XML snippet, your task is to: 
        1. Identify and describe the structural issues (e.g. unclosed tags, invalid nesting, missing attributes). 
        2. Return a corrected version that is minimal, valid, and schema-compliant. 
        3. Preserve original data and tag intent as much as possible, however if you need to delete data to make the XML valid, you can delete data.
        Here is the error that the XML validator gave: $errorMessage. Use this to pinpoint the error.
        Broken XML: $xml Return only the fixed XML. Do not include explanations or extra commentary.''';
    String response = await runModel(prompt);
    print(response);
    return response;
  }

  // Dialogs
  Future<bool?> _showRepairPromptDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invalid XML Output'),
        content: const Text(
          'The Local LLM outputted invalid XML.\n\n'
          'Would you like to attempt to repair it using the Local LLM?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Attempt Repair'),
          ),
        ],
      ),
    );
  }

  void _showRepairInProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // user cannot close
      builder: (dialogContext) => AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Repair in progress...')),
          TextButton(
            onPressed: () async {
              final shouldCancel = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Cancel Repair'),
                    content: Text(
                        'Are you sure you want to cancel the repair process?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Yes'),
                      ),
                    ],
                  );
                },
              );

              if (shouldCancel == true) {
                cancel();
              }
            },
            child: Text('Cancel'),
          ),
        ]),
      ),
    );
  }

  Future<void> _showRepairSuccessDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Repair Successful'),
        content: const Text(
          'The Local LLM successfully repaired the XML. You can continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> fetchModelKeys() async {
    final url = Uri.parse(
      'https://raw.githubusercontent.com/ssung13/SWEN670F2025/main/models.csv',
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
  }

  Future<bool?> _showRepairFailedDialog(BuildContext context) async {
    String? selectedModel = LocalStorageService.getLocalLLMPath()
        .split('models\\')
        .last
        .split(".gguf")
        .first;

    // Filter to only downloaded models
    final keys = await fetchModelKeys();

    final downloadedModels =
        keys.where((k) => DownloadManager().isDownloaded(k)).toList();
    return showDialog<bool>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Repair Failed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The Local LLM failed to repair the XML. You can select another downloaded model and try again.',
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
                      print(modelPath);
                      LocalStorageService.saveLocalLLMPath(modelPath);
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

  Future<void> _showRepairCancelledDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Repair Cancelled'),
        content: const Text(
          'The XML remains invalid. Operation was cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
