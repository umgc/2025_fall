import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import './utils.dart';
import './online_model.dart';

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer() async {

  final modelConfig = await getOnlineModelConfig();
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: modelConfig,
    ruleFsts: '',
  );
  return sherpa_onnx.OnlineRecognizer(config);
}

class StreamingAsrScreen extends StatefulWidget {
  const StreamingAsrScreen({super.key});

  @override
  State<StreamingAsrScreen> createState() => _StreamingAsrScreenState();
}

class _StreamingAsrScreenState extends State<StreamingAsrScreen> {
  late final TextEditingController _controller;
  late final AudioRecorder _audioRecorder;
  List<int> recordedData = [];
  List<sherpa_onnx.OnlineRecognizerResult> segmentResults = [];
  String _title = 'Real-time speech recognition';
  String _last = '';
  int _index = 0;
  bool _isInitialized = false;

  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  int _sampleRate = 16000;

  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;

  @override
  void initState() {
    _audioRecorder = AudioRecorder();
    _controller = TextEditingController();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    super.initState();
  }

  Future<void> _start() async {
    if (!_isInitialized) {
      sherpa_onnx.initBindings();
      _recognizer = await createOnlineRecognizer();
      _stream = _recognizer?.createStream();

      _isInitialized = true;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.pcm16bits;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(
          encoder: encoder,
          sampleRate: 16000,
          numChannels: 1,
        );

        final stream = await _audioRecorder.startStream(config);

        stream.listen(
              (data) {
                recordedData.addAll(data);
            final samplesFloat32 =
            convertBytesToFloat32(Uint8List.fromList(data));
            _stream!.acceptWaveform(
                samples: samplesFloat32, sampleRate: _sampleRate);
            while (_recognizer!.isReady(_stream!)) {
              _recognizer!.decode(_stream!);
            }
            final result = _recognizer!.getResult(_stream!);
            final text = result.text;
            String textToDisplay = _last;
            if (text != '') {
              segmentResults.add(result);
              if (_last == '') {
                textToDisplay = '$_index: $text';
              } else {
                textToDisplay = '$_index: $text\n$_last';
              }
            }

            if (_recognizer!.isEndpoint(_stream!)) {
              _recognizer!.reset(_stream!);
              if (text != '') {
                _last = textToDisplay;
                _index += 1;
              }
            }
            // print('text: $textToDisplay');

            _controller.value = TextEditingValue(
              text: textToDisplay,
              selection: TextSelection.collapsed(offset: textToDisplay.length),
            );
          },
          onDone: () {
            print('stream stopped.');
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stop() async {
    _stream!.free();
    _stream = _recognizer!.createStream();

    await _audioRecorder.stop();
    saveTemporaryFile(recordedData, _sampleRate);
  }

  Future<void> saveTemporaryFile(List<int> data, int sampleRate) async {
    Directory? directory = await getExternalStorageDirectory();
    String filename = "";
    if(directory != null) {
      filename = "${directory.path}/temporary.wav";
      File recordedFile = File(filename);

      var channels = 1;

      int byteRate = ((16 * sampleRate * channels) / 8).round();

      var size = data.length;

      var fileSize = size + 36;

      Uint8List header = Uint8List.fromList([
        // "RIFF"
        82, 73, 70, 70,
        fileSize & 0xff,
        (fileSize >> 8) & 0xff,
        (fileSize >> 16) & 0xff,
        (fileSize >> 24) & 0xff,
        // WAVE
        87, 65, 86, 69,
        // fmt
        102, 109, 116, 32,
        // fmt chunk size 16
        16, 0, 0, 0,
        // Type of format
        1, 0,
        // One channel
        channels, 0,
        // Sample rate
        sampleRate & 0xff,
        (sampleRate >> 8) & 0xff,
        (sampleRate >> 16) & 0xff,
        (sampleRate >> 24) & 0xff,
        // Byte rate
        byteRate & 0xff,
        (byteRate >> 8) & 0xff,
        (byteRate >> 16) & 0xff,
        (byteRate >> 24) & 0xff,
        // Uhm
        ((16 * channels) / 8).round(), 0,
        // bitsize
        16, 0,
        // "data"
        100, 97, 116, 97,
        size & 0xff,
        (size >> 8) & 0xff,
        (size >> 16) & 0xff,
        (size >> 24) & 0xff,
        ...data
      ]);
      recordedFile.writeAsBytesSync(header, flush: true);
      processWavFile(filename);
    } else {
      print('local storage directory does not exist.');
    }
  }

  Future<void> processWavFile(String waveFilename) async {
    final segmentationModel = await copyAssetFile("assets/sherpa-onnx-pyannote-segmentation-3-0/model.onnx");
    final embeddingModel = await copyAssetFile("assets/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx");

    final segmentationConfig = sherpa_onnx.OfflineSpeakerSegmentationModelConfig(
      pyannote: sherpa_onnx.OfflineSpeakerSegmentationPyannoteModelConfig(
          model: segmentationModel),
    );

    final embeddingConfig =
    sherpa_onnx.SpeakerEmbeddingExtractorConfig(model: embeddingModel);
    // since we know there are 4 speakers in ./0-four-speakers-zh.wav, we set
    // numClusters to 4. If you don't know the exact number, please set it to -1.
    // in that case, you have to set threshold. A larger threshold leads to
    // fewer clusters, i.e., fewer speakers.
    final clusteringConfig =
    sherpa_onnx.FastClusteringConfig(numClusters: 4, threshold: 0.5);

    var config = sherpa_onnx.OfflineSpeakerDiarizationConfig(
        segmentation: segmentationConfig,
        embedding: embeddingConfig,
        clustering: clusteringConfig,
        minDurationOn: 0.2,
        minDurationOff: 0.5);

    final sd = sherpa_onnx.OfflineSpeakerDiarization(config);
    if (sd.ptr == nullptr) {
      return;
    }

    final waveData = sherpa_onnx.readWave(waveFilename);
    if (sd.sampleRate != waveData.sampleRate) {
      print(
          'Expected sample rate: ${sd.sampleRate}, given: ${waveData.sampleRate}');
      return;
    }

    print('started');

    // Use the following statement if you don't want to use a callback
    // final segments = sd.process(samples: waveData.samples);

    final segments = sd.processWithCallback(
        samples: waveData.samples,
        callback: (int numProcessedChunk, int numTotalChunks) {
          final progress = 100.0 * numProcessedChunk / numTotalChunks;

          print('Progress ${progress.toStringAsFixed(2)}%');

          return 0;
        });
    String textToDisplay = '';
    print("SEGMENTS LENGTH: ${segments.length}");
    for (int i = 0; i < segments.length; ++i) {
      print(
          '${segments[i].start.toStringAsFixed(3)} -- ${segments[i].end.toStringAsFixed(3)}  speaker_${segments[i].speaker}');
      print("RESULTS LENGTH: ${segmentResults.length}");
      sherpa_onnx.OnlineRecognizerResult? result = segmentResults.firstWhere((segment) {
        if(segment.text.isEmpty) {
          return false;
        } else {
          print("TIMESTAMPS LENGTH: ${segment.timestamps.length}");
          double middleTime = segment.timestamps[0];
          print("MIDDLE TIME: ${middleTime.toStringAsFixed(3)}");
          return segment.text.isNotEmpty && ((segments[i].start < middleTime) &&
              (segments[i].end > middleTime));
        }
      },
      orElse: ()=> null);
      if(result != null) {
        textToDisplay += 'speaker_${segments[i].speaker}: ${result.text}\n';
      }
    }

    _controller.value = TextEditingValue(
      text: textToDisplay,
      selection: TextSelection.collapsed(offset: textToDisplay.length),
    );

  }

  Future<void> _pause() => _audioRecorder.pause();

  Future<void> _resume() => _audioRecorder.resume();

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(
      encoder,
    );

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder.isEncoderSupported(e)) {
          debugPrint('- ${encoder.name}');
        }
      }
    }

    return isSupported;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        TextField(
          maxLines: 5,
          controller: _controller,
          readOnly: true,
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildRecordStopControl(),
            const SizedBox(width: 20),
            _buildText(),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    super.dispose();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;
    late Color color;

    if (_recordState != RecordState.stop) {
      icon = const Icon(Icons.stop, color: Colors.red, size: 30);
      color = Colors.red.withOpacity(0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
      color = theme.primaryColor.withOpacity(0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: 56, height: 56, child: icon),
          onTap: () {
            (_recordState != RecordState.stop) ? _stop() : _start();
          },
        ),
      ),
    );
  }

  Widget _buildText() {
    if (_recordState == RecordState.stop) {
      return const Text("Start");
    } else {
      return const Text("Stop");
    }
  }
}