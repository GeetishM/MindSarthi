import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:mindsarthi/core/theme/app_theme.dart';
import '../models/mood_provider.dart';
import '../models/mood_entry.dart';

class MoodInsightsPage extends StatelessWidget {
  const MoodInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodProvider = Provider.of<MoodProvider>(context);

    // Get last 7 days entries in chronological order for the chart
    final chartEntries = moodProvider.entries.take(7).toList().reversed.toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mood Analytics',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: moodProvider.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : moodProvider.entries.isEmpty
              ? _buildEmptyState(context, isDark)
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Section 1: Weekly Trend Chart ---
                        Text(
                          'Weekly Trend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildChartCard(chartEntries, isDark),
                        const SizedBox(height: 32),

                        // --- Section 2: Stats & Analytics ---
                        Text(
                          'Summary & Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatsSummary(moodProvider, isDark),
                        const SizedBox(height: 32),

                        // --- Section 3: Activities Correlation ---
                        if (moodProvider.activityCounts.isNotEmpty) ...[
                          Text(
                            'Activity Influences',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActivitiesInfluence(moodProvider, isDark),
                          const SizedBox(height: 32),
                        ],

                        // --- Section 4: History Log ---
                        Text(
                          'Recent Logs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryList(moodProvider.entries, isDark),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurface : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Icon(
                CupertinoIcons.graph_square,
                size: 64,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No logs yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log your mood on the home screen to unlock personalized insights and trend lines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(List<MoodEntry> chartEntries, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Fluctuations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                'Last 7 entries',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (chartEntries.length < 2)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Log at least 2 entries to display trend graphs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: MoodLineChartPainter(
                  entries: chartEntries,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(MoodProvider provider, bool isDark) {
    final average = provider.averageMoodScore;
    String moodName = 'Okay';
    Color moodColor = AppColors.primary;
    if (average >= 4.5) {
      moodName = 'Awesome';
      moodColor = const Color(0xFFFFB300);
    } else if (average >= 3.5) {
      moodName = 'Good';
      moodColor = AppColors.success;
    } else if (average >= 2.5) {
      moodName = 'Okay';
      moodColor = AppColors.primary;
    } else if (average >= 1.5) {
      moodName = 'Bad';
      moodColor = AppColors.accent;
    } else if (average > 0) {
      moodName = 'Terrible';
      moodColor = AppColors.error;
    }

    // Determine dominant emotion
    final Map<String, int> emotionCounts = {};
    for (var entry in provider.entries) {
      for (var emotion in entry.emotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }
    String dominantEmotion = 'None';
    int maxCount = 0;
    emotionCounts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        dominantEmotion = key;
      }
    });

    return Row(
      children: [
        // Average Mood Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Mood',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      average.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      ' / 5',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    moodName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: moodColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Dominant Emotion Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Feeling',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dominantEmotion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  dominantEmotion != 'None'
                      ? 'Logged $maxCount times'
                      : 'Not enough data',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesInfluence(MoodProvider provider, bool isDark) {
    // Sort activities by frequency
    final sortedActivities = provider.activityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedActivities.take(3).map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActivityIcon(entry.key),
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entry.value} logs',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList(List<MoodEntry> entries, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final formattedDate = DateFormat('MMM d, h:mm a').format(entry.timestamp);

        // Get mood configuration colors
        Color moodColor = AppColors.primary;
        IconData moodIcon = Icons.sentiment_neutral_rounded;
        if (entry.mood == 'Awesome') {
          moodColor = const Color(0xFFFFB300);
          moodIcon = Icons.sentiment_very_satisfied_rounded;
        } else if (entry.mood == 'Good') {
          moodColor = AppColors.success;
          moodIcon = Icons.sentiment_satisfied_rounded;
        } else if (entry.mood == 'Okay') {
          moodColor = AppColors.primary;
          moodIcon = Icons.sentiment_neutral_rounded;
        } else if (entry.mood == 'Bad') {
          moodColor = AppColors.accent;
          moodIcon = Icons.sentiment_dissatisfied_rounded;
        } else if (entry.mood == 'Terrible') {
          moodColor = AppColors.error;
          moodIcon = Icons.sentiment_very_dissatisfied_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(moodIcon, size: 22, color: moodColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.mood,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (entry.emotions.isNotEmpty || entry.activities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...entry.emotions.map((emotion) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            emotion,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        )),
                    ...entry.activities.map((activity) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface2 : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getActivityIcon(activity),
                                size: 10,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activity,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ],
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  entry.notes,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getActivityIcon(String name) {
    switch (name) {
      case 'Sleep':
        return CupertinoIcons.bed_double;
      case 'Work':
        return CupertinoIcons.briefcase;
      case 'Study':
        return CupertinoIcons.book;
      case 'Health':
        return CupertinoIcons.heart;
      case 'Exercise':
        return CupertinoIcons.sportscourt;
      case 'Friends':
        return CupertinoIcons.person_2;
      case 'Family':
        return CupertinoIcons.house;
      case 'Hobbies':
        return CupertinoIcons.gamecontroller;
      case 'Food':
        return CupertinoIcons.cart;
      case 'Weather':
        return CupertinoIcons.cloud_sun;
      default:
        return CupertinoIcons.bookmark;
    }
  }
}

// --- Custom Line Chart Painter ---
class MoodLineChartPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final bool isDark;

  MoodLineChartPainter({required this.entries, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 24.0;
    final double paddingRight = 16.0;
    final double paddingTop = 16.0;
    final double paddingBottom = 24.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    final int maxVal = 5;
    final int minVal = 1;

    // Draw Grid Lines (horizontal)
    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.border).withOpacity(0.4)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 5; i++) {
      final double y = paddingTop + (height / 4) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Coordinates points list
    final List<Offset> points = [];
    final double stepX = width / (entries.length - 1);

    for (int i = 0; i < entries.length; i++) {
      final double x = paddingLeft + stepX * i;
      final double val = _getMoodValue(entries[i].mood);
      // Map 1..5 values to height..0 coordinate range
      final double normalizedVal = (val - minVal) / (maxVal - minVal);
      final double y = paddingTop + height * (1.0 - normalizedVal);
      points.add(Offset(x, y));
    }

    // Draw Line and Gradient Fill Underneath
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        // Curve coordinates calculations
        final double prevX = points[i - 1].dx;
        final double prevY = points[i - 1].dy;
        final double currX = points[i].dx;
        final double currY = points[i].dy;
        final double controlX1 = prevX + (currX - prevX) / 2;
        final double controlY1 = prevY;
        final double controlX2 = prevX + (currX - prevX) / 2;
        final double controlY2 = currY;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, currX, currY);
      }

      // Draw Gradient fill path
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, paddingTop + height)
        ..lineTo(points.first.dx, paddingTop + height)
        ..close();

      final fillShader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
          AppColors.primary.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, width, height));

      canvas.drawPath(fillPath, Paint()..shader = fillShader);

      // Draw Main Line
      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);

      // Draw glowing circles on points
      final pointPaint = Paint()..color = AppColors.primary;
      final glowPaint = Paint()..color = AppColors.primary.withOpacity(0.2);

      for (var pt in points) {
        canvas.drawCircle(pt, 7.0, glowPaint);
        canvas.drawCircle(pt, 4.0, pointPaint);
      }
    }

    // Draw bottom date labels
    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
    );

    for (int i = 0; i < entries.length; i++) {
      final double x = paddingLeft + stepX * i;
      final label = DateFormat('E').format(entries[i].timestamp);
      
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 8),
      );
    }
  }

  double _getMoodValue(String mood) {
    switch (mood) {
      case 'Awesome':
        return 5.0;
      case 'Good':
        return 4.0;
      case 'Okay':
        return 3.0;
      case 'Bad':
        return 2.0;
      case 'Terrible':
        return 1.0;
      default:
        return 3.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
