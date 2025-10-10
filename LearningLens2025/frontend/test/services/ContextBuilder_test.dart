import 'package:flutter_test/flutter_test.dart';
import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/services/LLMContextBuilder.dart';

void main() {
  group('buildContext', () {
    final perm = PermTokens(
      core: 'CORE: You are LearningLens.',
      modules: [
        'MODULE: Reflective question at end.',
        'MODULE: Prefer concise bullets.'
      ],
    );
    final history = <ChatTurn>[
      ChatTurn(role: 'user', content: 'Hi'),
      ChatTurn(role: 'assistant', content: 'Hello!'),
      ChatTurn(role: 'user', content: 'Help me plan study schedule.'),
      ChatTurn(role: 'assistant', content: 'What’s your availability?'),
      ChatTurn(role: 'user', content: '90 minutes daily.'),
    ];

    test('includes persistant context first and user prompt last', () {
      final msgs = generateContext(
        permTokens: perm,
        chatHistory: history,
        userPrompt: 'Create week 1 plan.',
        llmContextSize: 4000,
        maxOutputTokens: 200,
      );

      expect(msgs.first['role'], 'system');
      expect(msgs.first['content']!.startsWith('CORE:'), isTrue);
      expect(msgs.last['role'], 'user');
      expect(msgs.last['content'], 'Create week 1 plan.');
    });

    test('attempts to include modules before history', () {
      final msgs = generateContext(
        permTokens: perm,
        chatHistory: history,
        userPrompt: 'Create week 1 plan.',
        llmContextSize: 4000,
        maxOutputTokens: 800,
      );

      // core + modules appear before any user/assistant turns
      final firstConvIdx = msgs
          .indexWhere((m) => m['role'] == 'user' || m['role'] == 'assistant');

      // All system messages (core/modules) are before conversation starts
      for (int i = 0; i < firstConvIdx; i++) {
        expect(msgs[i]['role'], 'system');
      }

      // The first system should be core
      expect(msgs[0]['content']!.startsWith('CORE:'), isTrue);
      // At least one module present (when budget allows)
      expect(
          msgs.any((m) =>
              m['role'] == 'system' && m['content']!.startsWith('MODULE:')),
          isTrue);
    });
    test('packs history newest -> oldest to fill remaining budget', () {
      final msgs = generateContext(
        permTokens: perm,
        chatHistory: history,
        userPrompt: 'Create week 1 plan.',
        llmContextSize: 4000,
        maxOutputTokens: 800,
      );

      // Find the final user prompt
      final lastUserIndex = msgs.lastIndexWhere((m) => m['role'] == 'user');
      // Immediately before it should be the most recent history turn (assistant or user)
      // given sufficient budget.
      if (lastUserIndex > 0) {
        expect(
          msgs[lastUserIndex - 1]['role'] == 'assistant' ||
              msgs[lastUserIndex - 1]['role'] == 'user',
          isTrue,
        );
      }
    });

    test('respects very small budgets (core + prompt only)', () {
      final msgs = generateContext(
        permTokens: perm,
        chatHistory: history,
        userPrompt: 'Create week 1 plan.',
        llmContextSize: 100, // tiny window on purpose
        maxOutputTokens: 80, // large output
        safetyMargin: 40, // leaves almost no input room
      );

      expect(msgs.length, 2);
      expect(msgs[0]['role'], 'system'); // core
      expect(msgs[1]['role'], 'user'); // prompt
    });

    test('never drops the core system message', () {
      final msgs = generateContext(
        permTokens: perm,
        chatHistory: history,
        userPrompt: 'Create week 1 plan.',
        llmContextSize: 512, // very tight
        maxOutputTokens: 400,
        safetyMargin: 80,
      );

      expect(msgs.first['role'], 'system');
      expect(msgs.first['content']!.startsWith('CORE:'), isTrue);
    });
  });
}
