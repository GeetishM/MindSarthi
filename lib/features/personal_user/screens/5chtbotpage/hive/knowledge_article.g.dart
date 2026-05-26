// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_article.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KnowledgeArticleAdapter extends TypeAdapter<KnowledgeArticle> {
  @override
  final int typeId = 4;

  @override
  KnowledgeArticle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KnowledgeArticle(
      id: fields[0] as String,
      category: fields[1] as String,
      keywords: (fields[2] as List).cast<String>(),
      content: fields[3] as String,
      appSuggestion: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, KnowledgeArticle obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.keywords)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.appSuggestion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
