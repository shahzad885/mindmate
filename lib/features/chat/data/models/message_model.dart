import '../../../../core/ai/ai_message.dart';

class MessageModel {
  final String id;
  final String content;
  final String role; // 'user' | 'assistant'
  final DateTime timestamp;
  final String? mood;

  const MessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.mood,
  });

  bool get isUser => role == 'user';

  MessageModel copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
    String? mood,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        content: json['content'] as String,
        role: json['role'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        mood: json['mood'] as String?,
      );

  AiMessage toAiMessage() => AiMessage(
        role: role,
        content: content,
      );
}
