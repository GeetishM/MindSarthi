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

  JournalEntry({
    required this.title,
    required this.content,
    required this.createdAt,
    required this.lastEdited,
    required this.tag,
  });
}