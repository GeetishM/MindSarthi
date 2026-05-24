import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'mood_entry.dart';

class MoodProvider extends ChangeNotifier {
  List<MoodEntry> _entries = [];
  bool _isLoading = false;

  List<MoodEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  MoodProvider() {
    _loadUserAndFetchMoods();
  }

  Future<void> _loadUserAndFetchMoods() async {
    try {
      final user = await AppwriteService().account.get();
      await fetchMoods(user.$id);
    } catch (_) {
      // Not logged in or error
    }
  }

  Future<void> fetchMoods(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.moodsCollectionId,
        queries: [
          Query.equal('userId', uid),
          Query.orderDesc('timestamp'),
          Query.limit(100),
        ],
      );

      _entries = response.documents.map((doc) => MoodEntry.fromAppwrite(doc.data, doc.$id)).toList();
    } catch (e) {
      debugPrint('Error fetching moods: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearEntries() {
    _entries = [];
    notifyListeners();
  }

  // --- Sentiment and Analytics Math ---

  double get averageMoodScore {
    if (_entries.isEmpty) return 0.0;
    
    double total = 0.0;
    for (var entry in _entries) {
      total += _getMoodValue(entry.mood);
    }
    return total / _entries.length;
  }

  Map<String, int> get moodDistribution {
    final Map<String, int> dist = {
      'Awesome': 0,
      'Good': 0,
      'Okay': 0,
      'Bad': 0,
      'Terrible': 0,
    };
    for (var entry in _entries) {
      if (dist.containsKey(entry.mood)) {
        dist[entry.mood] = dist[entry.mood]! + 1;
      }
    }
    return dist;
  }

  Map<String, int> get activityCounts {
    final Map<String, int> counts = {};
    for (var entry in _entries) {
      for (var activity in entry.activities) {
        counts[activity] = (counts[activity] ?? 0) + 1;
      }
    }
    return counts;
  }

  double _getMoodValue(String mood) {
    switch (mood) {
      case 'Awesome': return 5.0;
      case 'Good': return 4.0;
      case 'Okay': return 3.0;
      case 'Bad': return 2.0;
      case 'Terrible': return 1.0;
      default: return 3.0;
    }
  }

  // --- Appwrite Write ---

  Future<void> saveMoodEntry({
    required String mood,
    required List<String> emotions,
    required List<String> activities,
    required String notes,
  }) async {
    final user = await AppwriteService().account.get();
    final databases = AppwriteService().databases;
    final docId = ID.unique();

    final newEntry = MoodEntry(
      id: docId,
      mood: mood,
      emotions: emotions,
      activities: activities,
      notes: notes,
      timestamp: DateTime.now(),
      userId: user.$id,
    );

    await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.moodsCollectionId,
      documentId: docId,
      data: newEntry.toAppwrite(),
    );

    _entries.insert(0, newEntry);
    notifyListeners();
  }
}
