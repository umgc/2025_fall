// Represents permanent tokens for a chat session
class PermTokens {
  final String core; // permanent system instructions
  final List<String> modules; // optional extra system snippets

  PermTokens({
    String? core,
    List<String> modules = const [],
  })  : core = (core == null || core.trim().isEmpty)
            ? 'You are LearningLens, an AI assistant designed to help Students and teachers learn and understand complex topics. You provide clear, concise, and accurate information in a friendly and approachable manner. Always aim to enhance the user\'s learning or teaching experience.'
            : core,
        modules = modules;
}

// Represents a single turn in a chat conversation
class ChatTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String? content;

  const ChatTurn({required this.role, required this.content});

  ChatTurn copyWith({String? role, String? content}) =>
      ChatTurn(role: role ?? this.role, content: content ?? this.content);

  // JSON should use Map<String, dynamic>
  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  // Defensive factory: tolerate missing/typed values
  factory ChatTurn.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] as String?)?.trim().toLowerCase() ?? 'user';
    final allowed = {'user', 'assistant', 'system'};
    final role = allowed.contains(rawRole) ? rawRole : 'user';

    final val = json['content'];
    // ensure content is a String
    final content = val is String ? val : (val == null ? '' : val.toString());

    return ChatTurn(role: role, content: content);
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
}
