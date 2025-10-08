class Token_Utils {
  static int estimateTokenText(String text) {
    // A very rough estimate: 1 token ~= 4 characters in English
    final chars = text.length;
    return (chars / 4).ceil() + 8; // Adding some buffer
  }

  static int estimateMessages(List<Map<String, dynamic>> messages) {
    // Start with a token count of 0
    int totalTokens = 0;

    // Go through each message in the list
    for (final message in messages) {
      // Extract the role (system, user, assistant, etc.)
      final role = message['role'] ?? '';

      // Extract the content (the actual text of the message)
      final content = message['content'] ?? '';

      // Combine role and content into one string to count
      final combined = "$role:$content";

      // Estimate tokens for this single message
      final tokensForMessage = estimateTokenText(combined);

      // Add it to the running total
      totalTokens += tokensForMessage;
    }

    // After looping through all messages, return the total token count
    return totalTokens;
  }
}
