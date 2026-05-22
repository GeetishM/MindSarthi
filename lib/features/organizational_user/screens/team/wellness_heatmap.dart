import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _uid = FirebaseAuth.instance.currentUser?.uid;
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
      // First get all members to know departments
      final membersSnap = await FirebaseFirestore.instance
          .collection('org_members')
          .doc(_uid)
          .collection('members')
          .get();

      final deptMap = <String, List<String>>{}; // dept -> [uid]
      for (var doc in membersSnap.docs) {
        final dept = (doc.data()['department'] as String?) ?? 'General';
        deptMap.putIfAbsent(dept, () => []).add(doc.id);
      }

      // Get check-ins for last 7 days
      final checkinsSnap = await FirebaseFirestore.instance
          .collection('wellness_checkins')
          .doc(_uid)
          .collection('checkins')
          .where('date', isGreaterThanOrEqualTo: _last7Days.first)
          .get();

      // Build lookup: uid -> dept
      final uidToDept = <String, String>{};
      for (var entry in deptMap.entries) {
        for (var uid in entry.value) {
          uidToDept[uid] = entry.key;
        }
      }

      // Aggregate: dept -> date -> [scores]
      final agg = <String, Map<String, List<double>>>{};
      for (var doc in checkinsSnap.docs) {
        final data = doc.data();
        final memberUid = data['memberUid'] as String? ?? '';
        final date = data['date'] as String? ?? '';
        final score = (data['score'] as num?)?.toDouble() ?? 3;
        final dept = uidToDept[memberUid] ?? 'General';

        agg.putIfAbsent(dept, () => {});
        agg[dept]!.putIfAbsent(date, () => []).add(score);
      }

      // Compute averages
      for (var dept in agg.keys) {
        _heatData[dept] = {};
        for (var date in agg[dept]!.keys) {
          final scores = agg[dept]![date]!;
          _heatData[dept]![date] =
              scores.reduce((a, b) => a + b) / scores.length;
        }
      }

      // If no data yet, add placeholder departments
      if (_heatData.isEmpty) {
        for (var dept in deptMap.keys) {
          _heatData[dept] = {};
        }
      }
      if (_heatData.isEmpty) {
        _heatData['General'] = {};
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
