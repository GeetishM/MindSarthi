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
    // Simple best streak calculation (can be improved)
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
}