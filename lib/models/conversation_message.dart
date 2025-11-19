/// Enum for message role in conversation
enum MessageRole {
  user,
  model;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'User';
      case MessageRole.model:
        return 'AI';
    }
  }
}

/// Model for a conversation message
class ConversationMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? fileUri; // Gemini file URI if attached

  ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.fileUri,
  });

  /// Create a user message
  factory ConversationMessage.user(
    String content, {
    String? fileUri,
  }) =>
      ConversationMessage(
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
        fileUri: fileUri,
      );

  /// Create a model (AI) message
  factory ConversationMessage.model(String content) => ConversationMessage(
        role: MessageRole.model,
        content: content,
        timestamp: DateTime.now(),
      );

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'fileUri': fileUri,
      };

  /// Create from JSON
  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        role: MessageRole.values.firstWhere(
          (e) => e.name == json['role'],
        ),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        fileUri: json['fileUri'] as String?,
      );

  @override
  String toString() => 'Message(${role.displayName}: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
}
