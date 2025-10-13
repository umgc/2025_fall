import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:simple_audio_trimmer/simple_audio_trimmer.dart';

import '../../config/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/comprehensive_file_service.dart';
import '../../services/enhanced_file_service.dart';
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig() async {
  final modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-2023-06-26';
  return sherpa_onnx.OnlineModelConfig(
    transducer: sherpa_onnx.OnlineTransducerModelConfig(
      encoder: await copyAssetFile(
        '$modelDir/encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx',
      ),
      decoder: await copyAssetFile(
        '$modelDir/decoder-epoch-99-avg-1-chunk-16-left-128.onnx',
      ),
      joiner: await copyAssetFile(
        '$modelDir/joiner-epoch-99-avg-1-chunk-16-left-128.onnx',
      ),
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
        '$modelDir/encoder-epoch-30-avg-1.int8.onnx',
      ),
      decoder: await copyAssetFile('$modelDir/decoder-epoch-30-avg-1.onnx'),
      joiner: await copyAssetFile('$modelDir/joiner-epoch-30-avg-1.int8.onnx'),
    ),
    tokens: await copyAssetFile('$modelDir/tokens.txt'),
    numThreads: 1,
  );
}

Float32List computeEmbedding({
  required sherpa_onnx.SpeakerEmbeddingExtractor extractor,
  required String filename,
}) {
  final waveData = sherpa_onnx.readWave(filename);
  final stream = extractor.createStream();

  stream.acceptWaveform(
    samples: waveData.samples,
    sampleRate: waveData.sampleRate,
  );
  stream.inputFinished();
  final embedding = extractor.compute(stream);
  stream.free();
  return embedding;
}

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer() async {
  final modelConfig = await getOnlineModelConfig();
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: modelConfig,
    ruleFsts: '',
  );
  return sherpa_onnx.OnlineRecognizer(config);
}

Future<sherpa_onnx.OfflineRecognizer> createOfflineRecognizer() async {
  final modelConfig = await getOfflineModelConfig();
  final config = sherpa_onnx.OfflineRecognizerConfig(model: modelConfig);
  return sherpa_onnx.OfflineRecognizer(config);
}

class StreamingAsrAndDiarizationScreen extends StatefulWidget {
  final List<FileCategory>? allowedCategories;
  final int? patientId;
  final Function(FileUploadResponse)? onUploadSuccess;
  final Function(String)? onUploadError;
  const StreamingAsrAndDiarizationScreen({
    super.key,
    this.allowedCategories,
    this.patientId,
    this.onUploadSuccess,
    this.onUploadError,
  });

  @override
  State<StreamingAsrAndDiarizationScreen> createState() =>
      _StreamingAsrAndDiarizationScreenState();
}

class _StreamingAsrAndDiarizationScreenState
    extends State<StreamingAsrAndDiarizationScreen> {
  late final TextEditingController _controller;
  late final AudioRecorder _audioRecorder;
  List<int> recordedData = [];
  String _textToDisplay = '';
  String _last = '';
  int _index = 0;
  bool _isInitialized = false;
  final _fileNameController = TextEditingController();
  FileCategory? _selectedCategory;
  bool _isLoading = false;

  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OfflineRecognizer? _offlineRecognizer;
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

  List<FileCategory> get _availableCategories {
    if (widget.allowedCategories != null &&
        widget.allowedCategories!.isNotEmpty) {
      return widget.allowedCategories!;
    } else {
      return FileCategory.values;
    }
  }

  Future<void> _start() async {
    setState(() {
      _controller.clear();
      recordedData = [];
      _textToDisplay = '';
    });
    if (!_isInitialized) {
      sherpa_onnx.initBindings();
      setState(() {
        _isLoading = true;
      });
      _recognizer = await createOnlineRecognizer();
      setState(() {
        _isLoading = false;
      });
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
            final samplesFloat32 = convertBytesToFloat32(
              Uint8List.fromList(data),
            );
            _stream!.acceptWaveform(
              samples: samplesFloat32,
              sampleRate: _sampleRate,
            );
            while (_recognizer!.isReady(_stream!)) {
              _recognizer!.decode(_stream!);
            }
            final result = _recognizer!.getResult(_stream!);
            final text = result.text;
            String textToDisplay = _last;
            if (text != '') {
              if (_last == '') {
                textToDisplay = 'Line $_index: $text';
              } else {
                textToDisplay = 'Line $_index: $text\n$_last';
              }
            }

            if (_recognizer!.isEndpoint(_stream!)) {
              _recognizer!.reset(_stream!);
              if (text != '') {
                _last = textToDisplay;
                _index += 1;
              }
            }
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
    setState(() {
      _isLoading = true;
    });
    if (_controller.value.text.isNotEmpty) {
      saveTemporaryFile(recordedData, _sampleRate);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveTemporaryFile(List<int> data, int sampleRate) async {
    Directory? directory = await getExternalStorageDirectory();
    String filename = "";
    if (directory != null) {
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
        ...data,
      ]);
      recordedFile.writeAsBytesSync(header, flush: true, mode: FileMode.write);
      segmentWaveFile(filename);
    } else {
      print('local storage directory does not exist.');
    }
  }

  Future<List<String>> getSpeakerFiles(String directoryPath) async {
    // Create a Directory object
    final directory = Directory(directoryPath);

    // List to store file paths
    List<String> filePaths = [];

    // Check if the directory exists
    if (await directory.exists()) {
      // Use the list method to get all files and directories
      await for (var entity in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is File) {
          filePaths.add(entity.path); // Add file paths to the list
        }
      }

      // Print the list of file paths
      print('Files in directory:');
      filePaths.forEach(print);
    } else {
      print('Directory does not exist.');
    }
    return filePaths;
  }

  Future<List<String>> getSpeakerDirectories(String directoryPath) async {
    // Create a Directory object
    final directory = Directory(directoryPath);

    // List to store file paths
    List<String> directoryPaths = [];

    // Check if the directory exists
    if (await directory.exists()) {
      // Use the list method to get all files and directories
      await for (var entity in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is Directory) {
          directoryPaths.add(entity.path); // Add file paths to the list
        }
      }

      // Print the list of file paths
      print('Directories in directory:');
      directoryPaths.forEach(print);
    } else {
      print('Directory does not exist.');
    }
    return directoryPaths;
  }

  Future<void> registerSpeakers(
    Directory directory,
    sherpa_onnx.SpeakerEmbeddingExtractor extractor,
    sherpa_onnx.SpeakerEmbeddingManager manager,
  ) async {
    List<List<Float32List>> speakerVectors = [];
    List<String> speakerFolders = await getSpeakerDirectories(
      '${directory.path}/voice_samples/',
    );
    List<String> names = [];
    for (int i = 0; i < speakerFolders.length; i++) {
      speakerVectors.add([]);
      names.add(Path.basename(speakerFolders[i]));
      List<String> speakerFiles = await getSpeakerFiles(speakerFolders[i]);
      for (var file in speakerFiles) {
        Float32List embedding = computeEmbedding(
          extractor: extractor,
          filename: file,
        );
        speakerVectors[i].add(embedding);
      }
    }
    for (int k = 0; k < speakerVectors.length; k++) {
      if (!manager.addMulti(name: names[k], embeddingList: speakerVectors[k])) {
        print('Failed to register ${names[k]}');
      }
      print('REGISTERED: ${names[k]}');
    }
  }

  Future<void> segmentWaveFile(String waveFilename) async {
    final segmentationModel = await copyAssetFile(
      "assets/sherpa-onnx-pyannote-segmentation-3-0/model.onnx",
    );
    final embeddingModel = await copyAssetFile(
      "assets/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx",
    );

    final segmentationConfig =
        sherpa_onnx.OfflineSpeakerSegmentationModelConfig(
          pyannote: sherpa_onnx.OfflineSpeakerSegmentationPyannoteModelConfig(
            model: segmentationModel,
          ),
        );

    final embeddingConfig = sherpa_onnx.SpeakerEmbeddingExtractorConfig(
      model: embeddingModel,
    );
    final extractor = sherpa_onnx.SpeakerEmbeddingExtractor(
      config: embeddingConfig,
    );
    final manager = sherpa_onnx.SpeakerEmbeddingManager(extractor.dim);

    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      await registerSpeakers(directory, extractor, manager);
    }
    print("ALL SPEAKERS REGISTERED");
    // since we know there are 4 speakers in ./0-four-speakers-zh.wav, we set
    // numClusters to 4. If you don't know the exact number, please set it to -1.
    // in that case, you have to set threshold. A larger threshold leads to
    // fewer clusters, i.e., fewer speakers.
    final clusteringConfig = sherpa_onnx.FastClusteringConfig(
      numClusters: 4,
      threshold: 0.5,
    );

    var config = sherpa_onnx.OfflineSpeakerDiarizationConfig(
      segmentation: segmentationConfig,
      embedding: embeddingConfig,
      clustering: clusteringConfig,
      minDurationOn: 0.2,
      minDurationOff: 0.5,
    );

    final sd = sherpa_onnx.OfflineSpeakerDiarization(config);
    if (sd.ptr == nullptr) {
      return;
    }

    final waveData = sherpa_onnx.readWave(waveFilename);

    if (sd.sampleRate != waveData.sampleRate) {
      print(
        'Expected sample rate: ${sd.sampleRate}, given: ${waveData.sampleRate}',
      );
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
      },
    );
    sd.free();
    if (segments.isNotEmpty) {
      _offlineRecognizer = await createOfflineRecognizer();
      for (int i = 0; i < segments.length; ++i) {
        print(
          '${segments[i].start.toStringAsFixed(3)} -- ${segments[i].end.toStringAsFixed(3)}  speaker_${segments[i].speaker}',
        );
        String outputFile = waveFilename.replaceFirst('.wav', '/$i.wav');
        await File(outputFile).create(recursive: true);
        await trimAudio(
          waveFilename,
          outputFile,
          segments[i],
          extractor,
          manager,
        );
      }
      _offlineRecognizer!.free();
      extractor.free();
      manager.free();
      _controller.value = TextEditingValue(
        text: _textToDisplay,
        selection: TextSelection.collapsed(offset: _textToDisplay.length),
      );
      //Delete Temporary Files
      if (directory != null) {
        File('${directory.path}/temporary.wav').deleteSync();
        Directory('${directory.path}/temporary/').deleteSync();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Trim audio file
  Future<void> trimAudio(
    String inputPath,
    String outputPath,
    sherpa_onnx.OfflineSpeakerDiarizationSegment segment,
    sherpa_onnx.SpeakerEmbeddingExtractor extractor,
    sherpa_onnx.SpeakerEmbeddingManager manager,
  ) async {
    try {
      await SimpleAudioTrimmer.trim(
        inputPath: inputPath,
        outputPath: outputPath,
        start: segment.start,
        end: segment.end,
      );
      await offlineSpeechRecognizer(
        outputPath,
        segment.speaker,
        extractor,
        manager,
      );
    } on PlatformException catch (e) {
      print(e.message);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> offlineSpeechRecognizer(
    String waveFilename,
    int speaker,
    sherpa_onnx.SpeakerEmbeddingExtractor extractor,
    sherpa_onnx.SpeakerEmbeddingManager manager,
  ) async {
    final waveData = sherpa_onnx.readWave(waveFilename);
    final stream = _offlineRecognizer!.createStream();
    stream.acceptWaveform(
      samples: waveData.samples,
      sampleRate: waveData.sampleRate,
    );
    _offlineRecognizer!.decode(stream);
    final result = _offlineRecognizer!.getResult(stream);
    final embedding = computeEmbedding(
      extractor: extractor,
      filename: waveFilename,
    );
    var name = manager.search(embedding: embedding, threshold: .6);
    if (name == '') {
      name = 'speaker_$speaker';
    }
    setState(() {
      _textToDisplay += '$name: ${result.text}\n';
    });

    stream.free();
  }

  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder.isEncoderSupported(encoder);

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

  Future<void> _saveRecognizedText() async {
    if (_textToDisplay.trim().isEmpty) {
      return;
    }

    final fileName = _fileNameController.text.trim();
    final fileBytes = Uint8List.fromList(_textToDisplay.codeUnits);

    await _uploadSpeechToTextFileToWeb(fileName, fileBytes);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Speech-to-text file saved')));
  }

  Future<void> _uploadSpeechToTextFileToWeb(
    String fileName,
    List<int> fileBytes,
  ) async {
    if (_selectedCategory == null || fileBytes.isEmpty || fileName.isEmpty) {
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) {
        throw Exception('User not logged in');
      }

      //Save File To Local
      Directory? directory = await getExternalStorageDirectory();
      if (directory != null) {
        File localFile = await File(
          '${directory.path}/notetaker_files/$fileName.txt',
        ).create(recursive: true);
        localFile.writeAsBytesSync(Uint8List.fromList(fileBytes));
      } else if (widget.onUploadError != null) {
        widget.onUploadError!('Could not save the file locally');
      }

      FileUploadResponse? response;

      // Use the existing enhanced file service for other categories
      response = await EnhancedFileService.uploadFileWeb(
        fileBytes: Uint8List.fromList(fileBytes),
        fileName: '$fileName.txt',
        category: _selectedCategory!.value,
        patientId: widget.patientId,
      );

      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File uploaded successfully: ${response.fileName}'),
            backgroundColor: AppTheme.success,
          ),
        );

        // Reset form
        setState(() {
          _selectedCategory = null;
          _fileNameController.clear();
          _textToDisplay = '';
        });

        // Callback
        if (widget.onUploadSuccess != null) {
          widget.onUploadSuccess!(response);
        }
      } else {
        throw Exception('Upload failed - no response received');
      }
    } catch (e, stacktrace) {
      print('Upload Exception: $e');
      print('Stacktrace: $stacktrace');
      final errorMessage = 'Upload failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: AppTheme.error),
      );

      if (widget.onUploadError != null) {
        widget.onUploadError!(errorMessage);
      }
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.mic, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Speech to Text',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = _availableCategories;

    if (categories.isEmpty) {
      return const Text('No categories available.');
    }

    return DropdownButtonFormField<FileCategory>(
      items: categories.map((category) {
        return DropdownMenuItem<FileCategory>(
          value: category,
          child: Text('${category.icon} ${category.displayName}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a file category';
        }
        return null;
      },
      initialValue: _selectedCategory,
      // Starts as null!
      hint: const Text('Select Category'),
      // This shows when value is null
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _selectCategory() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file category first'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'Enter file name (no extension)',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'File name cannot be empty';
            }
            if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(value.trim())) {
              return 'Invalid characters in file name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _isLoading
            ? Column(
                children: [CircularProgressIndicator(), Text("Processing")],
              )
            : TextField(maxLines: 5, controller: _controller, readOnly: true),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildRecordStopControl(),
            const SizedBox(width: 16),
            _buildText(),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _textToDisplay.isNotEmpty ? _saveRecognizedText : null,
          child: const Text('Save to File'),
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
            if (_selectedCategory == null) {
              _selectCategory();
            } else {
              (_recordState != RecordState.stop) ? _stop() : _start();
            }
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
