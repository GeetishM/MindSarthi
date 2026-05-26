import 'package:hive/hive.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';

class StreakModel {
  final Set<DateTime> completedDays;

  StreakModel({required this.completedDays});

  int get currentStreak {
    int streak = 0;
    DateTime today = DateTime.now();
    while (completedDays.contains(DateTime(today.year, today.month, today.day).subtract(Duration(days: streak)))) {
      streak++;
    }
    return streak;
  }

  int get bestStreak {
    List<DateTime> sorted = completedDays.toList()..sort();
    int best = 0, current = 0;
    DateTime? prev;
    for (final day in sorted) {
      if (prev == null || day.difference(prev).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
      prev = day;
    }
    return best;
  }

  static int calculateJournalStreak(Box<JournalEntry> journalBox) {
    if (journalBox.isEmpty) return 0;
    final Set<DateTime> journalDates = journalBox.values
        .map((entry) => DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day))
        .toSet();

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    if (!journalDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!journalDates.contains(checkDate)) {
        return 0;
      }
    }

    while (journalDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int calculateBestJournalStreak(Box<JournalEntry> journalBox) {
    if (journalBox.isEmpty) return 0;
    final Set<DateTime> journalDates = journalBox.values
        .map((entry) => DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day))
        .toSet();

    List<DateTime> sorted = journalDates.toList()..sort();
    int best = 0, current = 0;
    DateTime? prev;
    for (final day in sorted) {
      if (prev == null || day.difference(prev).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
      prev = day;
    }
    return best;
  }
}