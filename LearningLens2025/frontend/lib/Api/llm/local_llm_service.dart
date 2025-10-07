import 'dart:io';

import 'package:fllama/fllama.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:learninglens_app/services/local_storage_service.dart';

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
class LocalLLMService {
  static final LocalLLMService _instance = LocalLLMService._internal();
  factory LocalLLMService() => _instance;
  LocalLLMService._internal();

  int? _runningRequestId;
  ToolFunction? _tool;

  bool _loading = false;

  var _temperature = 0.5;
  var _topP = 1.0;

  // if longer than max tokens, output cuts off
  int _maxTokens = 3000;

  bool _modelLoaded = false;
  String _modelPath = LocalStorageService.getLocalLLMPath();

  Completer<String> completer = Completer<String>();

  void configureToken({int? maxTokens}) {
    if (maxTokens != null) _maxTokens = maxTokens;
  }

  Future<String> getChatResponse(String prompt) async {
    return await runModel(prompt);
  }

  Future<String> postToLlm(String prompt) async {
    return await runModel(prompt);
  }

  /// Run the model with a prompt and return the final response
  Future<String> runModel(String prompt) async {
    _modelPath = LocalStorageService.getLocalLLMPath();

    print(_modelPath);
    if (_modelPath == "") {
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
      maxTokens: _maxTokens.round(),
      messages: [
        Message(Role.system, 'You are a chatbot.'),
        Message(Role.user, messageText),
      ],
      numGpuLayers: 99,
      /* this seems to have no adverse effects in environments w/o GPU support, ex. Android and web */
      modelPath: kIsWeb ? mlcModelId : _modelPath,
      mmprojPath: mmprojPath,
      frequencyPenalty: 0.0,
      // Don't use below 1.1, LLMs without a repeat penalty
      // will repeat the same token.
      presencePenalty: 1.1,
      topP: _topP,
      // 22.9s for 249 input tokens with 20K context for SmolLM3.
      // 22.9s for 249 input tokens with 4K context for SmolLM3.
      contextSize: 16000,
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

    final chatTemplate = await fllamaChatTemplateGet(_modelPath);

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
}
