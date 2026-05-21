import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'journal_entry.dart';
import 'ai_service.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class JournalInsightsScreen extends StatefulWidget {
  const JournalInsightsScreen({super.key});

  @override
  State<JournalInsightsScreen> createState() => _JournalInsightsScreenState();
}

class _JournalInsightsScreenState extends State<JournalInsightsScreen> {
  bool _isLoadingAnalysis = false;

  Future<void> _generatePatternAnalysis(List<JournalEntry> entries) async {
    setState(() {
      _isLoadingAnalysis = true;
    });

    try {
      final analysis = await JournalAIService.performRecursivePatternAnalysis(entries);
      if (analysis != null) {
        final box = Hive.box('journalSettings');
        await box.put('pattern_analysis_text', analysis);
        await box.put('pattern_analysis_timestamp', DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint("Pattern analysis failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalysis = false;
        });
      }
    }
  }

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

                // ── Recursive Pattern Analysis ─────────────────────
                _buildPatternAnalysisSection(
                  context,
                  analyzedEntries,
                  primaryColor,
                  surfaceColor,
                  textPrimary,
                  textSecondary,
                  borderCol,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatternAnalysisSection(
    BuildContext context,
    List<JournalEntry> entries,
    Color primaryColor,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
  ) {
    final settingsBox = Hive.box('journalSettings');
    final cachedText = settingsBox.get('pattern_analysis_text') as String?;
    final cachedTimestampStr = settingsBox.get('pattern_analysis_timestamp') as String?;
    
    DateTime? lastUpdated;
    if (cachedTimestampStr != null) {
      lastUpdated = DateTime.tryParse(cachedTimestampStr);
    }

    final hasEnoughEntries = entries.length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          "Recursive Pattern Analysis",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.sparkles, color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MindSarthi Pattern Analyst",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (lastUpdated != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              "Last updated: ${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year} ${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasEnoughEntries)
                Text(
                  "Not enough entries for pattern analysis yet. Write or reflect at least 3 journal entries so MindSarthi can analyze your weekly emotional and behavioral trends.",
                  style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
                )
              else if (_isLoadingAnalysis)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          "Analyzing historical journal patterns...",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (cachedText != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownText(text: cachedText),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _generatePatternAnalysis(entries),
                        icon: const Icon(CupertinoIcons.refresh, size: 16),
                        label: const Text("Refresh Patterns Analysis"),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reveal behavioral, emotional, and cognitive patterns across your past entries.",
                      style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _generatePatternAnalysis(entries),
                        icon: const Icon(CupertinoIcons.sparkles, size: 16),
                        label: const Text("Run Patterns Analysis"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MarkdownText extends StatelessWidget {
  final String text;

  const MarkdownText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final children = <Widget>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      if (trimmed.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            trimmed.substring(4),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: -0.2,
            ),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            trimmed.substring(3),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: -0.3,
            ),
          ),
        ));
      } else if (trimmed.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(
            trimmed.substring(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: -0.4,
            ),
          ),
        ));
      } else if (trimmed.startsWith('- ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              Expanded(
                child: RichText(
                  text: _parseInlineStyles(trimmed.substring(2), textPrimary),
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: RichText(
            text: _parseInlineStyles(trimmed, textPrimary),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  TextSpan _parseInlineStyles(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (var match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.4),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: baseColor,
          fontSize: 13.5,
          height: 1.4,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.4),
      ));
    }

    return TextSpan(children: spans);
  }
}
