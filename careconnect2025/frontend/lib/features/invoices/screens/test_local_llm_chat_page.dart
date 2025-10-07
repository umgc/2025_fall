// Do not add emoji's in comments
import 'package:flutter/material.dart';
import 'package:llm_toolkit/llm_toolkit.dart';

import '../../invoices/ai/model_registry.dart';
 
import 'package:care_connect_app/widgets/common_drawer.dart';
import 'package:care_connect_app/features/invoices/ai/ai_bootstrap.dart';
 

class LocalChatPage extends StatefulWidget {
  const LocalChatPage({super.key});

  @override
  State<LocalChatPage> createState() => _LocalChatPageState();
}

class _LocalChatPageState extends State<LocalChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  bool _sending = false;

  final List<_Turn> _messages = <_Turn>[
    _Turn.role('assistant', 'Local model ready. Ask me something short to start.'),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ensureModelLoaded() async {
    final active = await ModelRegistry.getActivePath();
    if (active == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active model. Open Models and set one as active.')),
      );
      if (mounted) {
        Navigator.of(context).pushNamed('/models');
      }
      throw Exception('No active model');
    }
    if (!AIBootstrap.isReady) {
      await AIBootstrap.ensureReadyWithPath(active, nCtx: 512);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_Turn.role('user', text));
      _messages.add(_Turn.role('assistant', '')); // placeholder for streaming
    });
    _input.clear();

    await _ensureModelLoaded();

    // Build a simple chat-style prompt for instruct models
    const system = 'You are a concise helpful assistant.';
    final maxTurns = 8;
    final turns = _messages.take(_messages.length - 1).toList(); // exclude placeholder
    final last = turns.length > maxTurns ? turns.sublist(turns.length - maxTurns) : turns;

    final buf = StringBuffer();
    buf.writeln('System:\n$system\n');
    for (final t in last) {
      if (t.role == 'user') {
        buf.writeln('User:\n${t.text}\n');
      } else if (t.role == 'assistant') {
        buf.writeln('Assistant:\n${t.text}\n');
      }
    }
    buf.writeln('Assistant:');

    final params = GenerationParams.custom(
      maxTokens: 256,
      temperature: 0.3,
      topP: 0.9,
      topK: 40,
      repeatPenalty: 1.05,
    );

    final idxAssistant = _messages.length - 1;

    try {
      await for (final chunk in LLMToolkit.instance.generateText(buf.toString(), params: params)) {
        if (!mounted) break;
        setState(() {
          _messages[idxAssistant] = _messages[idxAssistant].append(chunk);
        });
        _scrollToEndSoon();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[idxAssistant] = _Turn.role('assistant', 'Error: $e');
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToEndSoon();
      }
    }
  }

  void _scrollToEndSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Local Chat')),
      drawer: const CommonDrawer(currentRoute: '/chat'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                final bubbleColor = isUser ? cs.primary : cs.surfaceContainerHighest;
                final textColor = isUser ? cs.onPrimary : cs.onSurface;

                return Column(
                  crossAxisAlignment: align,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        m.text,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Ask a short question',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Turn {
  final String role; // "user" or "assistant"
  final String text;

  _Turn.role(this.role, this.text);

  _Turn append(String more) => _Turn.role(role, text + more);
}
