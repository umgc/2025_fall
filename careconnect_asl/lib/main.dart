import 'dart:async';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CareConnectAslApp());

class CareConnectAslApp extends StatelessWidget {
  const CareConnectAslApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect — ASL Converter',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2C66F5)),
      home: const AslConverterPage(),
    );
  }
}

class AslOptions {
  final Duration letterDuration;
  final Duration wordPause;
  final double playbackSpeed;
  const AslOptions({this.letterDuration = const Duration(milliseconds: 650), this.wordPause = const Duration(milliseconds: 300), this.playbackSpeed = 1.0});
  AslOptions copyWith({Duration? letterDuration, Duration? wordPause, double? playbackSpeed}) => AslOptions(
    letterDuration: letterDuration ?? this.letterDuration,
    wordPause: wordPause ?? this.wordPause,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
  );
}

sealed class AslToken {
  final Duration duration;
  final String? ariaLabel;
  const AslToken({required this.duration, this.ariaLabel});
}
class LetterTile extends AslToken {
  final String letter;
  const LetterTile(this.letter, {Duration duration = const Duration(milliseconds: 650), String? ariaLabel}) : super(duration: duration, ariaLabel: ariaLabel);
}
class AvatarInstruction extends AslToken {
  final String command;
  final String? label;
  const AvatarInstruction({required this.command, this.label, Duration duration = const Duration(milliseconds: 1200)}) : super(duration: duration, ariaLabel: label);
}
class PauseToken extends AslToken {
  const PauseToken({Duration duration = const Duration(milliseconds: 300)}) : super(duration: duration);
}
class AslSequence {
  final List<AslToken> tokens;
  final String sourceText;
  const AslSequence({required this.tokens, required this.sourceText});
}

abstract class AslEngine {
  String get id;
  String get label;
  Future<bool> isAvailable();
  Future<AslSequence> convert(String text, {AslOptions options = const AslOptions()});
}
class MockAvatarEngine implements AslEngine {
  @override String get id => 'avatar';
  @override String get label => 'ASL Avatar (mock)';
  static final Map<String, List<AvatarInstruction>> _phraseMap = {
    'HELLO': [const AvatarInstruction(command: 'sign:HELLO', label: 'HELLO')],
    'THANK YOU': [const AvatarInstruction(command: 'sign:THANK_YOU', label: 'THANK YOU')],
    'I LOVE YOU': [const AvatarInstruction(command: 'sign:I_LOVE_YOU', label: 'I LOVE YOU')],
  };
  @override Future<bool> isAvailable() async => true;
  @override
  Future<AslSequence> convert(String text, {AslOptions options = const AslOptions()}) async {
    final cleaned = text.trim().toUpperCase();
    final tokens = <AslToken>[];
    bool matched = false;
    for (final phrase in _phraseMap.keys) {
      if (cleaned.contains(phrase)) {
        tokens.addAll(_phraseMap[phrase]!);
        tokens.add(PauseToken(duration: options.wordPause));
        matched = true;
      }
    }
    if (!matched) {
      for (final ch in cleaned.characters) {
        if (RegExp(r'[A-Z0-9]').hasMatch(ch)) {
          tokens.add(LetterTile(ch, duration: options.letterDuration, ariaLabel: 'Letter $ch'));
        } else if (RegExp(r'\s').hasMatch(ch)) {
          tokens.add(PauseToken(duration: options.wordPause));
        }
      }
    }
    return AslSequence(tokens: tokens, sourceText: text);
  }
}
class FingerspellingEngine implements AslEngine {
  @override String get id => 'fingerspelling';
  @override String get label => 'ASL Fingerspelling (fallback)';
  @override Future<bool> isAvailable() async => true;
  @override
  Future<AslSequence> convert(String text, {AslOptions options = const AslOptions()}) async {
    final tokens = <AslToken>[];
    final words = text.trim().split(RegExp(r'\s+'));
    for (var w = 0; w < words.length; w++) {
      for (final rune in words[w].runes) {
        final ch = String.fromCharCode(rune).toUpperCase();
        final letter = RegExp(r'[A-Z0-9]').hasMatch(ch) ? ch : '?';
        tokens.add(LetterTile(letter, duration: options.letterDuration, ariaLabel: 'Letter $letter'));
      }
      if (w != words.length - 1) tokens.add(PauseToken(duration: options.wordPause));
    }
    return AslSequence(tokens: tokens, sourceText: text);
  }
}
class AslService {
  AslService._();
  static final AslService instance = AslService._();
  final _engines = <String, AslEngine>{ 'avatar': MockAvatarEngine(), 'fingerspelling': FingerspellingEngine(), };
  Future<AslSequence> convert(String text, {List<String> enginePreference = const ['avatar', 'fingerspelling'], AslOptions options = const AslOptions(),}) async {
    for (final id in enginePreference) {
      final e = _engines[id];
      if (e != null && await e.isAvailable()) return e.convert(text, options: options);
    }
    return _engines['fingerspelling']!.convert(text, options: options);
  }
}

class AslConverterPage extends StatefulWidget { const AslConverterPage({super.key}); @override State<AslConverterPage> createState() => _AslConverterPageState(); }
class _AslConverterPageState extends State<AslConverterPage> {
  final _input = TextEditingController(text: 'Hello, I love you.');
  final _engines = const ['avatar', 'fingerspelling'];
  String _selected = 'avatar';
  AslSequence? _sequence;
  bool _busy = false;
  AslOptions _options = const AslOptions();

  Future<void> _convert() async {
    setState(() => _busy = true);
    try {
      final seq = await AslService.instance.convert(
        _input.text,
        enginePreference: [_selected, ..._engines.where((e) => e != _selected)],
        options: _options,
      );
      setState(() => _sequence = seq);
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showPlayer(AslSequence seq) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.70,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: AslPlayer(sequence: seq),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seq = _sequence;
    return Scaffold(
      appBar: AppBar(title: const Text('ASL Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _input,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Enter text to convert', border: OutlineInputBorder()),
                onSubmitted: (_) => _convert(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _selected,
                items: _engines.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selected = v ?? _selected),
                decoration: const InputDecoration(labelText: 'Engine', border: OutlineInputBorder()),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Speed'), const SizedBox(width: 12),
            DropdownButton<double>(
              value: _options.playbackSpeed,
              items: const [0.5, 0.75, 1, 1.25, 1.5, 2].map((v) => DropdownMenuItem(value: v, child: Text('${v}x'))).toList(),
              onChanged: (v) => setState(() => _options = _options.copyWith(playbackSpeed: v ?? 1)),
            ),
            const Spacer(),
            FilledButton.icon(onPressed: _busy ? null : _convert, icon: const Icon(Icons.transform_rounded), label: const Text('Convert')),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
              child: seq == null
                  ? const Center(child: Text('Converted ASL will appear here.'))
                  : Column(children: [
                      ListTile(
                        title: Text('Preview: "${seq.sourceText}"'),
                        trailing: IconButton(tooltip: 'Play in sheet', onPressed: () => _showPlayer(seq), icon: const Icon(Icons.play_circle_fill_rounded)),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: seq.tokens.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => AslDisplay(token: seq.tokens[i]),
                        ),
                      ),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class AslDisplay extends StatelessWidget {
  final AslToken token;
  const AslDisplay({super.key, required this.token});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (token is LetterTile) {
      final l = token as LetterTile;
      return Semantics(label: 'Letter ${l.letter}', child: _tile(theme, l.letter));
    }
    if (token is AvatarInstruction) {
      final a = token as AvatarInstruction;
      return Semantics(label: 'Avatar instruction: ${a.label ?? a.command}', child: _tile(theme, a.label ?? a.command, icon: Icons.accessibility_new));
    }
    if (token is PauseToken) {
      return _tile(theme, '•', icon: Icons.pause_rounded);
    }
    return const SizedBox.shrink();
  }

  Widget _tile(ThemeData theme, String text, {IconData? icon}) => Container(
    constraints: const BoxConstraints(minHeight: 180),
    alignment: Alignment.center,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: theme.colorScheme.surfaceVariant, border: Border.all(color: theme.colorScheme.outlineVariant)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (icon != null) ...[Icon(icon, size: 32), const SizedBox(width: 12)],
      Text(text, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2)),
    ]),
  );
}

class AslPlayer extends StatefulWidget {
  final AslSequence sequence;
  final double initialSpeed;
  const AslPlayer({super.key, required this.sequence, this.initialSpeed = 1.0});
  @override
  State<AslPlayer> createState() => _AslPlayerState();
}
class _AslPlayerState extends State<AslPlayer> {
  int _index = 0;
  bool _playing = false;
  double _speed = 1.0;
  Timer? _timer;

  @override void initState() { super.initState(); _speed = widget.initialSpeed.clamp(0.5, 2.0); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  void _play() { if (_playing) return; setState(() => _playing = true); _scheduleNext(); }
  void _pause() { setState(() => _playing = false); _timer?.cancel(); }
  void _stop() { _pause(); setState(() => _index = 0); }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_playing) return;
    if (_index >= widget.sequence.tokens.length) { setState(() => _playing = false); return; }
    final token = widget.sequence.tokens[_index];
    final effective = Duration(milliseconds: (token.duration.inMilliseconds / _speed).round());
    _timer = Timer(effective, () {
      if (!mounted) return;
      setState(() => _index = (_index + 1));
      if (_index < widget.sequence.tokens.length) _scheduleNext(); else setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.sequence.tokens;
    final current = (_index < tokens.length) ? tokens[_index] : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: current == null
        ? Center(key: const ValueKey('done'), child: Text('Playback finished', style: Theme.of(context).textTheme.titleMedium))
        : Padding(key: ValueKey(_index), padding: const EdgeInsets.all(12), child: AslDisplay(token: current)))),
      Row(children: [
        IconButton(onPressed: _play, icon: const Icon(Icons.play_arrow_rounded)),
        IconButton(onPressed: _pause, icon: const Icon(Icons.pause_rounded)),
        IconButton(onPressed: _stop, icon: const Icon(Icons.stop_rounded)),
        const Spacer(),
        const Text('Speed'),
        Slider(value: _speed, min: 0.5, max: 2.0, divisions: 6, label: '${_speed.toStringAsFixed(1)}x', onChanged: (v) => setState(() => _speed = v), onChangeEnd: (_) { if (_playing) _scheduleNext(); }),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(12,0,12,12), child: LinearProgressIndicator(value: tokens.isEmpty ? 0 : (_index / tokens.length).clamp(0.0, 1.0))),
    ]);
  }
}
