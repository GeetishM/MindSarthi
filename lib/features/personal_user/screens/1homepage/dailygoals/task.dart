import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 3)
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

  @HiveField(5)
  String? id;

  @HiveField(6)
  bool? isSynced;

  @HiveField(7)
  String? userId;

  Task({
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.rescheduleCount = 0,
    this.category = '',
    this.id,
    this.isSynced = false,
    this.userId,
  });

  // Not required for Hive, but useful if you want to convert to/from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      rescheduleCount: map['rescheduleCount'] ?? 0,
      category: map['category'] ?? '',
      id: map['id'],
      isSynced: map['isSynced'] ?? false,
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'rescheduleCount': rescheduleCount,
      'category': category,
      'isSynced': isSynced,
      'userId': userId,
    };
  }
}