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

Future<sherpa_onnx.OfflineModelConfig> getOfflineModelConfig() async {
  final modelDir = 'assets/sherpa-onnx-zipformer-gigaspeech-2023-12-12';
  return sherpa_onnx.OfflineModelConfig(
    transducer: sherpa_onnx.OfflineTransducerModelConfig(
      encoder: await copyAssetFile(
          '$modelDir/encoder-epoch-30-avg-1.int8.onnx'),
      decoder: await copyAssetFile(
          '$modelDir/decoder-epoch-30-avg-1.onnx'),
      joiner: await copyAssetFile(
          '$modelDir/joiner-epoch-30-avg-1.int8.onnx'),
    ),
    tokens: await copyAssetFile('$modelDir/tokens.txt'),
    numThreads: 1,
  );
}