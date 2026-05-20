import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'mood_entry.dart';

class MoodProvider extends ChangeNotifier {
  List<MoodEntry> _entries = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _moodSubscription;

  List<MoodEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  MoodProvider() {
    _initListener();
  }

  void _initListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListening(user.uid);
      } else {
        _stopListening();
      }
    });
  }

  void _startListening(String uid) {
    _stopListening();
    _isLoading = true;
    notifyListeners();

    _moodSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mood_inputs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      _entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('MoodProvider error: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  void _stopListening() {
    _moodSubscription?.cancel();
    _moodSubscription = null;
    _entries = [];
    _isLoading = false;
  }

  @override
  void dispose() {
    _moodSubscription?.cancel();
    super.dispose();
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

  // --- Firestore Write ---

  Future<void> saveMoodEntry({
    required String mood,
    required List<String> emotions,
    required List<String> activities,
    required String notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User must be logged in to track mood");
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mood_inputs')
        .doc();

    final newEntry = MoodEntry(
      id: docRef.id,
      mood: mood,
      emotions: emotions,
      activities: activities,
      notes: notes,
      timestamp: DateTime.now(),
    );

    // Save to Firestore. Offline cache will instantly write locally.
    await docRef.set(newEntry.toFirestore());
  }
}
