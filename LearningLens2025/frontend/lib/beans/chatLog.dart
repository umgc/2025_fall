
// Represents permanent tokens for a chat session
class PermTokens {
  final String core; // Perminant context. includes system role/instructions
  final List<String> modules; // Optinal Perminant context. Meant to be dynamically added/removed
 
  // Constructor that sets a default core if none is provided
  PermTokens({
    String? core,
    this.modules = const [],
  }) : core = (core == null || core.trim().isEmpty)
            ? "You are LearningLens, an AI assistant designed to help users learn and understand complex topics. You provide clear, concise, and accurate information in a friendly and approachable manner. Always aim to enhance the user's learning experience."
            : core;
}
// Represents a single turn in a chat conversation
class ChatTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;

  ChatTurn({required this.role, required this.content});
  
  // Converts the chatTurn to a JSON object
  Map<String, String> toJson() {
    return {'role': role, 'content': content};
  }
  // Factory constructor to create a chatTurn from a JSON object
  factory ChatTurn.fromJson(Map<String, dynamic> json) {
    return ChatTurn(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
  // Helper methods to check the role of the chat turn
  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';

}