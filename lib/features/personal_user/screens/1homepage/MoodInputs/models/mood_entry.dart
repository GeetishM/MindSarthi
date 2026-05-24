class MoodEntry {
  final String id;
  final String mood;
  final List<String> emotions;
  final List<String> activities;
  final String notes;
  final DateTime timestamp;
  final String userId;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.emotions,
    required this.activities,
    required this.notes,
    required this.timestamp,
    required this.userId,
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
