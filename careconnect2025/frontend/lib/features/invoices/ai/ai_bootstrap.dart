import 'package:flutter/widgets.dart';
import 'package:llm_toolkit/llm_toolkit.dart';

class AIBootstrap {
  static bool _inited = false;
  static bool _modelLoaded = false;

  static void _initIfNeeded() {
    if (_inited) return;
    WidgetsFlutterBinding.ensureInitialized();
    LLMToolkit.instance.initialize(
      defaultConfig: InferenceConfig.mobile(),
    );
    _inited = true;
  }

  static Future<void> ensureReadyWithPath(String modelPath, {int nCtx = 512}) async {
    _initIfNeeded();
    await LLMToolkit.instance.loadModel(
      modelPath,
      config: InferenceConfig(nCtx: nCtx, verbose: false),
    );
    _modelLoaded = true;
  }

  static bool get isReady => _inited && _modelLoaded;
}
