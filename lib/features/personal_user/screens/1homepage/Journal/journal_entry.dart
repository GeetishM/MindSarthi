import 'package:hive/hive.dart';
part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime createdAt; 

  @HiveField(3)
  DateTime lastEdited; 

  @HiveField(4)
  List<String> tag;

  @HiveField(5)
  double? sentimentScore;

  @HiveField(6)
  List<String>? sentimentEmotions;

  @HiveField(7)
  String? sentimentRecommendation;

  @HiveField(8)
  bool? crisisFlag;

  @HiveField(9)
  String? id;

  @HiveField(10)
  bool? isSynced;

  @HiveField(11)
  String? userId;

  JournalEntry({
    required this.title,
    required this.content,
    required this.createdAt,
    required this.lastEdited,
    required this.tag,
    this.sentimentScore,
    this.sentimentEmotions,
    this.sentimentRecommendation,
    this.crisisFlag,
    this.id,
    this.isSynced = false,
    this.userId,
  });
}