class AiMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;

  const AiMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}
