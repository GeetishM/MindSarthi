import 'package:Todo/models/task.dart';

class AnalyticsHelper {
  // 1. Daily task count
  static int dailyTaskCount(List<Task> tasks, DateTime day) {
    return tasks.where((task) => task.date == day).length;
  }

  // 2. % completed
  static double percentCompleted(List<Task> tasks, DateTime day) {
    final todaysTasks = tasks.where((t) => isSameDay(t.date, day)).toList();
    if (todaysTasks.isEmpty) return 0.0;
    final completed = todaysTasks.where((t) => t.isCompleted).length;
    return completed / todaysTasks.length;
  }

  /*
  // 3. Reschedules
  static int reschedules(List<Task> tasks, DateTime day) {
    return tasks
        .where((t) => isSameDay(t.date, day))
        .fold(0, (sum, t) => sum + t.rescheduleCount);
  }

  // 4. Self-care task count
  static int selfCareCount(List<Task> tasks, DateTime day) {
    return tasks
        .where((t) =>
            isSameDay(t.date, day) &&
            t.category.toLowerCase() == 'self-care')
        .length;
  }
*/
  // Example: Count all tasks (no date filtering, since your list doesn't store dates)
  static int dailyTaskCountFromDb(List<List<dynamic>> tasks, DateTime today) {
    return tasks.length;
  }

  // Count completed tasks (where the second element is true)
  static int completedTaskCount(List<List<dynamic>> tasks) {
    return tasks.where((task) => task[1] == true).length;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
