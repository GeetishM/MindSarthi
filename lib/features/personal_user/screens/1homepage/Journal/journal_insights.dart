import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'journal_entry.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class JournalInsightsScreen extends StatelessWidget {
  const JournalInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Sentiment Insights",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceColor,
      ),
      body: ValueListenableBuilder<Box<JournalEntry>>(
        valueListenable: Hive.box<JournalEntry>('journalBox').listenable(),
        builder: (context, box, _) {
          final entries = box.values.toList().reversed.toList();
          final analyzedEntries = entries.where((e) => e.sentimentScore != null).toList();

          if (analyzedEntries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined, size: 64, color: textSecondary.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      "No analyzed entries yet",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Write or record a new journal entry. MindSarthi AI will automatically analyze your sentiment!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate average score
          final totalScore = analyzedEntries.fold<double>(0, (sum, e) => sum + (e.sentimentScore ?? 0));
          final averageScore = totalScore / analyzedEntries.length;

          // Extract emotions
          final emotionCounts = <String, int>{};
          for (var entry in analyzedEntries) {
            if (entry.sentimentEmotions != null) {
              for (var emotion in entry.sentimentEmotions!) {
                emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
              }
            }
          }
          final sortedEmotions = emotionCounts.keys.toList()
            ..sort((a, b) => emotionCounts[b]!.compareTo(emotionCounts[a]!));

          // Custom feedback text based on mood average
          String moodText = "Balanced";
          Color moodColor = AppColors.primary;
          if (averageScore >= 8) {
            moodText = "Joyful & Energetic";
            moodColor = Colors.green;
          } else if (averageScore >= 6) {
            moodText = "Peaceful & Content";
            moodColor = AppColors.primary;
          } else if (averageScore >= 4) {
            moodText = "Reflective & Anxious";
            moodColor = AppColors.accent;
          } else {
            moodText = "Distressed / Low Energy";
            moodColor = AppColors.error;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary Score Card ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: moodColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            averageScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: moodColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Overall Mood Index",
                              style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              moodText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Based on ${analyzedEntries.length} entries",
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Emotional Tags Distribution ────────────────────
                if (sortedEmotions.isNotEmpty) ...[
                  Text(
                    "Dominant Emotions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedEmotions.map((emotion) {
                      final count = emotionCounts[emotion] ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.15), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              emotion,
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$count",
                                style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Logs of Recommendations ────────────────────────
                Text(
                  "Self-Care Recommendations",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: analyzedEntries.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = analyzedEntries[index];
                    final dateStr = "${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}";

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.title,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Mood: ${entry.sentimentScore?.toStringAsFixed(0)}/10",
                                  style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                          if (entry.sentimentRecommendation != null) ...[
                            const SizedBox(height: 10),
                            Divider(color: borderCol, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.favorite_rounded, color: AppColors.accent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.sentimentRecommendation!,
                                    style: TextStyle(fontSize: 13, color: textPrimary, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
