import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 5)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String mood;

  @HiveField(2)
  final List<String> emotions;

  @HiveField(3)
  final List<String> activities;

  @HiveField(4)
  final String notes;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String userId;

  @HiveField(7)
  bool isSynced;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.emotions,
    required this.activities,
    required this.notes,
    required this.timestamp,
    required this.userId,
    this.isSynced = false,
  });

  factory MoodEntry.fromAppwrite(Map<String, dynamic> data, String id) {
    return MoodEntry(
      id: id,
      mood: data['mood'] ?? '',
      emotions: List<String>.from(data['emotions'] ?? []),
      activities: List<String>.from(data['activities'] ?? []),
      notes: data['notes'] ?? '',
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      userId: data['userId'] ?? '',
      isSynced: true,
    );
  }

  Map<String, dynamic> toAppwrite() {
    return {
      'mood': mood,
      'emotions': emotions,
      'activities': activities,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }
}
