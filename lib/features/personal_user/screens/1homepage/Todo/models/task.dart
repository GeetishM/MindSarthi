import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isCompleted;

  @HiveField(2)
  DateTime date; // When the task is scheduled

  @HiveField(3)
  int rescheduleCount; // How many times the task was rescheduled

  @HiveField(4)
  String category; // e.g., 'self-care', 'work', etc.

  Task({
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.rescheduleCount = 0,
    this.category = '',
  });

  // Not required for Hive, but useful if you want to convert to/from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
      date: DateTime.parse(map['date']),
      rescheduleCount: map['rescheduleCount'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'rescheduleCount': rescheduleCount,
      'category': category,
    };
  }
}