import 'package:hive_flutter/hive_flutter.dart';

part 'memory_model.g.dart';

@HiveType(typeId: 0)
class MemoryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'person' | 'event' | 'emotion' | 'goal'

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String? sentiment; // 'positive' | 'negative' | 'neutral'

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  int mentions;

  MemoryEntry({
    required this.id,
    required this.type,
    required this.content,
    this.sentiment,
    required this.createdAt,
    required this.updatedAt,
    this.mentions = 1,
  });

  MemoryEntry copyWith({
    String? id,
    String? type,
    String? content,
    String? sentiment,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? mentions,
  }) {
    return MemoryEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      sentiment: sentiment ?? this.sentiment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mentions: mentions ?? this.mentions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
        'sentiment': sentiment,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'mentions': mentions,
      };

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
        id: json['id'] as String,
        type: json['type'] as String,
        content: json['content'] as String,
        sentiment: json['sentiment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        mentions: json['mentions'] as int? ?? 1,
      );
}
