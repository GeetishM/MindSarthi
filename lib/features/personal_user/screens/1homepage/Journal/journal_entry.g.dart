// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 0;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      title: fields[0] as String,
      content: fields[1] as String,
      createdAt: fields[2] as DateTime,
      lastEdited: fields[3] as DateTime,
      tag: (fields[4] as List).cast<String>(),
      sentimentScore: fields[5] as double?,
      sentimentEmotions: (fields[6] as List?)?.cast<String>(),
      sentimentRecommendation: fields[7] as String?,
      crisisFlag: fields[8] as bool?,
      id: fields[9] as String?,
      isSynced: fields[10] as bool?,
      userId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.lastEdited)
      ..writeByte(4)
      ..write(obj.tag)
      ..writeByte(5)
      ..write(obj.sentimentScore)
      ..writeByte(6)
      ..write(obj.sentimentEmotions)
      ..writeByte(7)
      ..write(obj.sentimentRecommendation)
      ..writeByte(8)
      ..write(obj.crisisFlag)
      ..writeByte(9)
      ..write(obj.id)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
