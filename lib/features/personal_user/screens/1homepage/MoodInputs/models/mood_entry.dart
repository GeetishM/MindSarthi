import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final String mood;
  final List<String> emotions;
  final List<String> activities;
  final String notes;
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.emotions,
    required this.activities,
    required this.notes,
    required this.timestamp,
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return MoodEntry(
      id: doc.id,
      mood: data?['mood'] ?? '',
      emotions: List<String>.from(data?['emotions'] ?? []),
      activities: List<String>.from(data?['activities'] ?? []),
      notes: data?['notes'] ?? '',
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mood': mood,
      'emotions': emotions,
      'activities': activities,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
