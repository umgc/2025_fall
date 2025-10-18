import 'dart:async';
import 'package:flutter/material.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommandAI extends StatefulWidget {
  final bool singleShot;

  const VoiceCommandAI({
    super.key,
    this.singleShot = false,
  });

  @override
  State<VoiceCommandAI> createState() => _VoiceCommandAIState();
}

class _VoiceCommandAIState extends State<VoiceCommandAI> {
  PorcupineManager? _porcupine;
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _wakeDetected = false;
  Timer? _timeoutTimer;

  String _buffer = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initPorcupine();
  }

  Future<void> _initPorcupine() async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final mgr = await PorcupineManager.fromBuiltInKeywords(
        'Qxjb+VJuMnPDRseioWb9czxnyKe7EWFMdNNMbIWrJiARG2q9Tvo5XA==',
        [BuiltInKeyword.PORCUPINE],
        _onWakeDetected,
      );

      if (!mounted) return;
      _porcupine = mgr;

      await _porcupine?.start();
    } on PorcupineException catch (e) {
      debugPrint('Porcupine init failed: ${e.message}');

      messenger?.showSnackBar(
        SnackBar(content: Text('Wake word init error: ${e.message}')),
      );
    } catch (e, st) {
      debugPrint('Unexpected init error: $e\n$st');
    }
  }

  void _onWakeDetected(int _) {
    setState(() => _wakeDetected = true);
    _startListening();
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    bool available = await _speech.initialize();
    if (available && await _speech.hasPermission) {
      setState(() => _isListening = true);

      _speech.listen(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 2),
        onResult: (r) {
          if (r.recognizedWords.isNotEmpty) {
            _buffer = r.recognizedWords;
          }
          if (r.finalResult) {
            _timeoutTimer?.cancel();
            _process(_buffer.isNotEmpty ? _buffer : r.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          onDevice: false,
          autoPunctuation: true,
          enableHapticFeedback: false,
        ),
      );

      _timeoutTimer = Timer(const Duration(seconds: 12), _onTimeout);
    } else {
      _showError('Mic permission denied');
      _reset();
    }
  }

  void _process(String words) {
    final cmd = words.toLowerCase().trim();
    debugPrint('Heard: $cmd');

    if (widget.singleShot) {
      Navigator.of(context).pop<String>(words);
      _reset();
      return;
    }

    if (cmd.contains('take me home')) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } else if (cmd.contains('take me to calendar')) {
      Navigator.pushNamed(context, '/telehealth');
    } else if (cmd.contains('take me to my tracker')) {
      Navigator.pushNamed(context, '/symptomTracker');
    } else {
      _showError('Command not recognized — please try again.');
    }
    _reset();
  }

  void _onTimeout() {
    if (_isListening) {
      final txt = _buffer.trim().isNotEmpty
          ? _buffer
          : _speech.lastRecognizedWords; // fallback just in case

      if (txt.trim().isNotEmpty) {
        _process(txt);
      } else {
        _showError('Listening timed out.');
        _reset();
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _reset() {
    _timeoutTimer?.cancel();
    _speech.stop();
    _buffer = '';
    setState(() {
      _isListening = false;
      _wakeDetected = false;
    });
  }

  void _onMicPressed() {
    setState(() => _wakeDetected = true);
    _startListening();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _porcupine?.stop();
    _porcupine?.delete();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Commands'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            _wakeDetected ? Icons.mic : Icons.mic_none,
            size: 64,
            color: _wakeDetected ? Colors.red : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            !_wakeDetected
                ? 'Say wake word or tap mic'
                : _isListening
                    ? 'Listening...'
                    : 'Processing...',
            style: const TextStyle(fontSize: 18),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onMicPressed,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
