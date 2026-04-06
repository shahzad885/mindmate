import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/ai/ai_message.dart';

part 'message_model.g.dart';

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String role;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? mood;

  MessageModel({
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

  AiMessage toAiMessage() => AiMessage(role: role, content: content);
}
