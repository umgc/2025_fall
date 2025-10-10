import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/services/Token_Utils.dart';

// Builds the context for LLM requests by combining persistent context,
// chat history (oldest -> newest), and the current user prompt (last).
List<Map<String, dynamic>> generateContext({
  required PermTokens permTokens,
  required List<ChatTurn> chatHistory,
  required String userPrompt,
  required int llmContextSize,
  required int maxOutputTokens,
  int safetyMargin = 500,
}) {
  // Budget = model context - reserved for response - safety margin
  final int tokenBudget = llmContextSize - maxOutputTokens - safetyMargin;

  // Messages start with core system prompt (null-safe)
  final msgs = <Map<String, dynamic>>[
    {'role': 'system', 'content': (permTokens.core ?? '').trim()},
  ];

  int count() => Token_Utils.estimateMessages(msgs);

  // Fast path: if budget tiny/negative, return just core + current user
  if (tokenBudget <= 0) {
    return [
      {'role': 'system', 'content': (permTokens.core ?? '').trim()},
      {'role': 'user', 'content': userPrompt},
    ];
  }

  // Add module system prompts (null-safe, trimmed)
  final List<String> modules = (permTokens.modules ?? const <String>[]);
  for (final m in modules) {
    final trimmed = (m ?? '').trim();
    if (trimmed.isEmpty) continue;

    msgs.add({'role': 'system', 'content': trimmed});
    if (count() > tokenBudget) {
      msgs.removeLast(); // back out and stop adding modules
      break;
    }
  }

  // Add prior chat history in chronological order (oldest -> newest)
  for (final turn in chatHistory) {
    final map = turn.toJson();
    final role = (map['role'] as String?)?.trim();
    final content = (map['content'] as String?)?.trim();

    if (role == null || content == null || content.isEmpty) continue;
    if (role != 'user' && role != 'assistant') continue; // only valid roles

    msgs.add({'role': role, 'content': content});
    if (count() > tokenBudget) {
      msgs.removeLast(); // back out and stop adding history
      break;
    }
  }

  // Add the CURRENT user prompt LAST
  msgs.add({'role': 'user', 'content': userPrompt});

  // If we’re over budget now, trim oldest conversation turns (not system)
  while (count() > tokenBudget) {
    final idx = msgs.indexWhere(
      (m) => m['role'] == 'user' || m['role'] == 'assistant',
    );
    if (idx == -1 || idx >= msgs.length - 1) break; // nothing left to trim
    msgs.removeAt(idx);
  }

  // Final guard: ensure we at least have system + current user
  if (msgs.isEmpty || msgs.last['role'] != 'user') {
    // Rebuild minimal context if something went odd during trimming
    return [
      {'role': 'system', 'content': (permTokens.core ?? '').trim()},
      {'role': 'user', 'content': userPrompt},
    ];
  }

  return msgs;
}
