import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/services/Token_Utils.dart';

// Builds the context for LLM requests by combining persistent context, chat history, and the user's current prompt.
List<Map<String, dynamic>> buildContext({
  required PermTokens permTokens,
  required List<ChatTurn> chatHistory,
  required String userPrompt,
  required int llmContextSize,
  required int maxOutputTokens,
  int safetyMargin = 500,
}) {
  // Reserve tokens for response and safety margin
  final int tokenBudget = llmContextSize - maxOutputTokens - safetyMargin;

  // If the token budget is tiny or negative, return only core context and user prompt
  if (tokenBudget <= 0) {
    return [
      {'role': 'system', 'content': permTokens.core},
      {'role': 'user', 'content': userPrompt},
    ];
  }

  //Creates the messages list starting with core persistant context.
  final msgs = <Map<String, dynamic>>[
    {'role': 'system', 'content': permTokens.core},
  ];

  // Gets the estimated token count of msgs
  int count() {
    return Token_Utils.estimateMessages(msgs);
  }

  // Iterates though dynamic context adding them to the messages list before checking token count.
  if (permTokens.modules.isNotEmpty) {
    for (final m in permTokens.modules) {
      // Trim whitespace and skip empty modules
      final trimmed = m.trim();
      if (trimmed.isEmpty) continue;

      msgs.add({'role': 'system', 'content': trimmed});

      //Checks if adding the module exceeded the token budget
      if (count() > tokenBudget) {
        msgs.removeLast();
        // Stop adding modules if we exceed the budget
        //TODO Display a warning/return an error that contextsize is too small and feature may not work as expected
        break;
      }
      //adds the current user prompt behind perminent context
      msgs.add({'role': 'user', 'content': userPrompt});

      int insertIndex() =>
          msgs.length - 1; // insert right before the final user prompt
      // Adds chat history in reverse order until the token budget is reached
      for (int i = chatHistory.length - 1; i >= 0; i--) {
        final turn = chatHistory[i];
        msgs.insert(insertIndex(), turn.toJson());

        if (count() > tokenBudget) {
          msgs.removeAt(insertIndex());
          // Stop adding chat history if we exceed the budget
          break;
        }
      }
      // If we still exceed the token budget, start removing the oldest conversation turns
      while (count() > tokenBudget) {
        final index = msgs.indexWhere(
            (msg) => msg['role'] == 'user' || msg['role'] == 'assistant');
        // If no more conversation turns to remove, break
        if (index == -1 || index >= msgs.length - 1) break;
        // Remove the oldest conversation turn
        msgs.removeAt(index);
      }
    }
  }
  return msgs;
}
