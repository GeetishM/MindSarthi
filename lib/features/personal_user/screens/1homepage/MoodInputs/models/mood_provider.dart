import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/core/services/sync_service.dart';
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
      // 1. Load local data first so UI updates instantly
      final moodsBox = Hive.box<MoodEntry>('moodsBox');
      _entries = moodsBox.values.toList();
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();

      // 2. Fetch remote data if logged in
      final user = await AppwriteService().account.get();
      await fetchMoods(user.$id);
    } catch (_) {
      // Not logged in or offline, keeping local entries
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

      final remoteEntries = response.documents.map((doc) => MoodEntry.fromAppwrite(doc.data, doc.$id)).toList();

      // Save/update to Hive
      final moodsBox = Hive.box<MoodEntry>('moodsBox');
      for (var entry in remoteEntries) {
        await moodsBox.put(entry.id, entry);
      }

      // Reload sorted list
      _entries = moodsBox.values.toList();
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  // --- Offline-First Write ---

  Future<void> saveMoodEntry({
    required String mood,
    required List<String> emotions,
    required List<String> activities,
    required String notes,
  }) async {
    String currentUserId = '';
    try {
      final user = await AppwriteService().account.get();
      currentUserId = user.$id;
    } catch (_) {
      // Guest user or offline
    }

    final docId = ID.unique();

    final newEntry = MoodEntry(
      id: docId,
      mood: mood,
      emotions: emotions,
      activities: activities,
      notes: notes,
      timestamp: DateTime.now(),
      userId: currentUserId,
      isSynced: false,
    );

    // Save locally first
    final moodsBox = Hive.box<MoodEntry>('moodsBox');
    await moodsBox.put(docId, newEntry);

    _entries.insert(0, newEntry);
    notifyListeners();

    // Trigger sync in background
    SyncService().syncAll();
  }
}
