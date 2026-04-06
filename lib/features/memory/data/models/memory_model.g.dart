// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written adapter — no build_runner used per project rules.

part of 'memory_model.dart';

class MemoryEntryAdapter extends TypeAdapter<MemoryEntry> {
  @override
  final int typeId = 0;

  @override
  MemoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoryEntry(
      id: fields[0] as String,
      type: fields[1] as String,
      content: fields[2] as String,
      sentiment: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      mentions: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MemoryEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.sentiment)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.mentions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
