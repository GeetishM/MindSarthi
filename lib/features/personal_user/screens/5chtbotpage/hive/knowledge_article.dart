import 'package:hive/hive.dart';

part 'knowledge_article.g.dart';

@HiveType(typeId: 4)
class KnowledgeArticle extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category; // 'anxiety', 'panic', 'adhd', 'depression', etc.

  @HiveField(2)
  final List<String> keywords;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String appSuggestion; // 'journal', 'breathing', 'goals', 'mood', etc.

  KnowledgeArticle({
    required this.id,
    required this.category,
    required this.keywords,
    required this.content,
    required this.appSuggestion,
  });
}
