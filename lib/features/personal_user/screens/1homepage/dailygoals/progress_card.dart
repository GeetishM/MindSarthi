import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final String title;

  const ProgressCard({
    super.key,
    required this.completed,
    required this.total,
    this.title = "Daily Progress",
  });

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : completed / total;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color.fromARGB(255, 94, 92, 92),
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            // Display the progress text
            Text(
              total == 0
                  ? "No goals for today! Add a task to get started."
                  : "$completed of $total goals completed",
              style: TextStyle(
                color: total == 0
                    ? const Color.fromARGB(255, 251, 49, 201)
                    : completed == 0
                    ? Colors.red
                    : completed < total
                    ? const Color.fromARGB(255, 247, 113, 56)
                    : const Color.fromARGB(255, 10, 145, 14),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add motivational message below the progress text
            const SizedBox(height: 10),
            Text(
              total == 0
                  ? "Tap + to add your first goal for today!"
                  : completed == 0
                  ? "Every journey begins with a single step!"
                  : completed < total
                  ? "You're making great progress—one step at a time!"
                  : "You did it! Celebrate your wins! 🎉",
              style: TextStyle(
                color: total == 0
                    ? const Color.fromARGB(255, 185, 49, 244)
                    : completed == 0
                    ? Colors.red
                    : completed < total
                    ? const Color.fromARGB(255, 247, 113, 56)
                    : const Color.fromARGB(255, 10, 145, 14),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
