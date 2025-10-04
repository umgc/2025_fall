import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig() async {
    final modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-2023-06-26';
    return sherpa_onnx.OnlineModelConfig(
      transducer: sherpa_onnx.OnlineTransducerModelConfig(
        encoder: await copyAssetFile(
            '$modelDir/encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx'),
        decoder: await copyAssetFile(
            '$modelDir/decoder-epoch-99-avg-1-chunk-16-left-128.onnx'),
        joiner: await copyAssetFile(
            '$modelDir/joiner-epoch-99-avg-1-chunk-16-left-128.onnx'),
      ),
      tokens: await copyAssetFile('$modelDir/tokens.txt'),
      modelType: 'zipformer2',
    );
}