import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/services/Token_Utils.dart';

// Builds the context for LLM requests by combining persistent context,
// chat history (oldest -> newest), and the current user prompt (last).
List<Map<String, dynamic>> generateContext({
  required PermTokens permTokens,
  required List<ChatTurn> chatHistory, // assumed chronological: oldest → newest
  required String userPrompt,
  required int llmContextSize,
  required int maxOutputTokens,
  int safetyMargin = 500,
}) {
  final int tokenBudget = llmContextSize - maxOutputTokens - safetyMargin;

  // Fixed/system context
  final fixed = <Map<String, dynamic>>[
    {'role': 'system', 'content': (permTokens.core).trim()},
    ...permTokens.modules
        .map((m) => (m).trim())
        .where((m) => m.isNotEmpty)
        .map((m) => {'role': 'system', 'content': m}),
  ];

  // Minimal fallback if budget is tiny
  List<Map<String, dynamic>> minimal() => [
        {'role': 'system', 'content': (permTokens.core).trim()},
        {'role': 'user', 'content': userPrompt},
      ];

  // Quick count helper on an arbitrary message list
  int count(List<Map<String, dynamic>> msgs) =>
      Token_Utils.estimateMessages(msgs);

  // If even fixed + user won't fit, return minimal
  if (tokenBudget <= 0 ||
      count([
            ...fixed,
            {'role': 'user', 'content': userPrompt}
          ]) >
          tokenBudget) {
    return minimal();
  }

  // Build recent context from the end, **in pairs** (user → assistant).
  // Accumulate newest-first then reverse later.
  final pickedNewestFirst = <Map<String, dynamic>>[];

  bool fitsWith(List<Map<String, dynamic>> candidateChrono) {
    // final order we will send: fixed + candidateChrono + current user
    final prospective = <Map<String, dynamic>>[
      ...fixed,
      ...candidateChrono,
      {'role': 'user', 'content': userPrompt},
    ];
    return count(prospective) <= tokenBudget;
  }

  int i = chatHistory.length - 1;
  while (i >= 0) {
    final turn = chatHistory[i].toJson();
    final role = (turn['role'] as String?)?.trim();
    final content = (turn['content'] as String?)?.trim();
    if (role == null || content == null || content.isEmpty) {
      i--;
      continue;
    }
    if (role != 'user' && role != 'assistant') {
      i--;
      continue;
    }

    // Form a coherent pair [user, assistant] in chronological order.
    if (role == 'assistant' &&
        i - 1 >= 0 &&
        (chatHistory[i - 1].toJson()['role'] as String?)?.trim() == 'user') {
      // Build the pair chronologically (older user first, then assistant)
      final userMap = {
        'role': 'user',
        'content': (chatHistory[i - 1].toJson()['content'] as String).trim(),
      };
      final asstMap = {
        'role': 'assistant',
        'content': (chatHistory[i].toJson()['content'] as String).trim(),
      };

      // Since pickedNewestFirst is newest-first, we need to reverse it for testing.
      final chronoSoFar = pickedNewestFirst.reversed.toList(growable: true)
        ..addAll([userMap, asstMap]);

      if (fitsWith(chronoSoFar)) {
        // Keep the pair as newest-first in our accumulator (assistant after user chronologically,
        // but newest-first accumulator stores the latest chunk at the end).
        pickedNewestFirst.addAll([asstMap, userMap]); // store newest-first
        i -= 2; // consumed two turns
        continue;
      } else {
        // If the pair doesn't fit, try just the assistant (or just the user) as a last resort.
        // First try assistant alone (newest).
        final chronoTestAssistant =
            pickedNewestFirst.reversed.toList(growable: true)..add(asstMap);
        if (fitsWith(chronoTestAssistant)) {
          pickedNewestFirst.add(asstMap);
        } else {
          // Try user alone
          final chronoTestUser =
              pickedNewestFirst.reversed.toList(growable: true)..add(userMap);
          if (fitsWith(chronoTestUser)) {
            pickedNewestFirst.add(userMap);
          }
        }
        break; // stop going further back once we fail to fit a pair
      }
    } else {
      // Single turn (no matching pair adjacent). Try to include it by itself.
      final single = {'role': role, 'content': content};
      final chronoSoFar = pickedNewestFirst.reversed.toList(growable: true)
        ..add(single);
      if (fitsWith(chronoSoFar)) {
        pickedNewestFirst.add(single); // keep newest-first
        i -= 1;
        continue;
      } else {
        break;
      }
    }
  }

  // Final assembly in **chronological** order:
  // fixed → (pickedNewestFirst reversed) → current user (LAST)
  final chronologicalHistory = pickedNewestFirst.reversed.toList();
  final finalMsgs = <Map<String, dynamic>>[
    ...fixed,
    ...chronologicalHistory,
    {'role': 'user', 'content': userPrompt},
  ];

  // Extra guard: if somehow over budget (edge rounding), drop the OLDEST non-system turns.
  while (count(finalMsgs) > tokenBudget) {
    final idx = finalMsgs.indexWhere(
      (m) => m['role'] == 'user' || m['role'] == 'assistant',
    );
    if (idx == -1 || idx >= finalMsgs.length - 1) {
      return minimal();
    }
    finalMsgs.removeAt(idx);
  }

  return _normalizeContext(finalMsgs);
}

List<Map<String, dynamic>> _normalizeContext(List<Map<String, dynamic>> raw) {
  final out = <Map<String, dynamic>>[];

  //merge all system messages
  final sys = StringBuffer();
  for (final m in raw) {
    final role = (m['role'] ?? '').toString();
    final content = (m['content'] ?? '').toString().trim();
    if (content.isEmpty) continue;
    if (role == 'system') {
      if (sys.isNotEmpty) sys.writeln();
      sys.write(content);
    }
  }
  if (sys.isNotEmpty) {
    out.add({'role': 'system', 'content': sys.toString()});
  }

  //collect non-system in order, drop empties/unknown roles
  final core = <Map<String, dynamic>>[];
  for (final m in raw) {
    final role = (m['role'] ?? '').toString();
    if (role == 'system') continue;
    final content = (m['content'] ?? '').toString().trim();
    if (content.isEmpty) continue;
    if (role == 'user' || role == 'assistant' || role == 'tool') {
      core.add({'role': role, 'content': content});
    }
  }
  if (core.isEmpty) return out;

  //first non-system must be user
  if (core.first['role'] != 'user') {
    core.first = {'role': 'user', 'content': core.first['content']};
  }

  //merge consecutive same-role messages
  final merged = <Map<String, dynamic>>[];
  for (final m in core) {
    if (merged.isEmpty) {
      merged.add(m);
      continue;
    }
    final last = merged.last;
    if (last['role'] == m['role']) {
      merged.last = {
        'role': last['role'],
        'content': '${last['content']}\n\n${m['content']}',
      };
    } else {
      merged.add(m);
    }
  }

  out.addAll(merged);
  return out;
}
