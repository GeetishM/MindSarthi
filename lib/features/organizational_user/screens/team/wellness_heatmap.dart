import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

/// Full-screen wellness heatmap showing department × day grid.
/// Rows = departments, Columns = last 7 days.
/// Cell colour = average wellness score for that dept on that day.
class WellnessHeatmap extends StatefulWidget {
  const WellnessHeatmap({super.key});

  @override
  State<WellnessHeatmap> createState() => _WellnessHeatmapState();
}

class _WellnessHeatmapState extends State<WellnessHeatmap> {
  bool _isLoading = true;

  // dept -> { dateStr -> avgScore }
  final Map<String, Map<String, double>> _heatData = {};
  late List<String> _last7Days;

  @override
  void initState() {
    super.initState();
    _last7Days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('yyyy-MM-dd').format(d);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final depts = ['Engineering', 'Marketing', 'Sales', 'HR'];
      final randomScores = {
        'Engineering': [4.5, 4.2, 3.8, 4.0, 4.1, 4.3, 4.4],
        'Marketing': [4.0, 3.5, 3.8, 4.2, 4.0, 3.9, 4.1],
        'Sales': [3.5, 3.8, 3.2, 3.5, 3.9, 4.0, 4.2],
        'HR': [4.8, 4.6, 4.7, 4.5, 4.6, 4.7, 4.8],
      };

      for (var dept in depts) {
        _heatData[dept] = {};
        final scores = randomScores[dept]!;
        for (int i = 0; i < 7; i++) {
          _heatData[dept]![_last7Days[i]] = scores[i];
        }
      }
    } catch (e) {
      debugPrint('WellnessHeatmap: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Wellness Heatmap',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      _legendItem(
                        theme,
                        'Low (1-2)',
                        theme.colorScheme.error.withValues(alpha: isDark ? 0.4 : 0.25),
                      ),
                      const SizedBox(width: 16),
                      _legendItem(
                        theme,
                        'Mid (3)',
                        AppColors.warning.withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                      const SizedBox(width: 16),
                      _legendItem(
                        theme,
                        'Good (4-5)',
                        AppColors.success.withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                      const Spacer(),
                      _legendItem(
                        theme,
                        'No data',
                        theme.chipTheme.backgroundColor ?? (isDark ? const Color(0xFF32231E) : const Color(0xFFFCFAF9)),
                        hasBorder: true,
                      ),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day headers
                          Row(
                            children: [
                              const SizedBox(width: 100),
                              ..._last7Days.map((d) {
                                final dt = DateTime.parse(d);
                                return SizedBox(
                                  width: 56,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          DateFormat('EEE').format(dt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: theme.textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('d').format(dt),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: theme.textTheme.titleMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Dept rows
                          ..._heatData.keys.map((dept) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      dept,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ..._last7Days.map((date) {
                                    final score = _heatData[dept]?[date];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: Container(
                                        width: 50,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _cellColor(theme, isDark, score),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: score == null
                                              ? Border.all(
                                                  color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                                                  width: 0.5,
                                                )
                                              : null,
                                        ),
                                        child: score != null
                                            ? Center(
                                                child: Text(
                                                  score.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme.textTheme.titleMedium?.color,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Color _cellColor(ThemeData theme, bool isDark, double? score) {
    if (score == null) {
      return theme.chipTheme.backgroundColor ?? (isDark ? const Color(0xFF32231E) : const Color(0xFFFCFAF9));
    }
    if (score <= 2) {
      return theme.colorScheme.error.withValues(alpha: isDark ? 0.4 : 0.25);
    }
    if (score <= 3) {
      return AppColors.warning.withValues(alpha: isDark ? 0.4 : 0.3);
    }
    return AppColors.success.withValues(alpha: isDark ? 0.4 : 0.3);
  }

  Widget _legendItem(ThemeData theme, String label, Color color,
      {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder
                ? Border.all(
                    color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
