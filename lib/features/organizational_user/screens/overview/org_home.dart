import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/organizational_user/screens/team/wellness_heatmap.dart';
import 'package:shimmer/shimmer.dart';

class OrgHome extends StatefulWidget {
  const OrgHome({super.key});

  @override
  State<OrgHome> createState() => _OrgHomeState();
}

class _OrgHomeState extends State<OrgHome> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('organizations').doc(_uid).get(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _shimmerHeader(theme, isDark);
                    }

                    final orgName = snap.data?.data() != null
                        ? (snap.data!.data() as Map)['orgName'] ?? 'Organization'
                        : 'Organization';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Organization Dashboard',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          orgName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Stats Row ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildStatsRow(theme, isDark),
              ),
            ),

            // ── Wellness Snapshot Header ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wellness Snapshot',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WellnessHeatmap()),
                      ),
                      child: Text(
                        'View Full →',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Mini Heatmap ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildMiniHeatmap(theme, isDark),
              ),
            ),

            // ── Recent Reports Header ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Text(
                  'Recent Anonymous Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            // ── Recent Reports ─────────────────────────────
            _buildRecentReports(theme, isDark),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('org_members')
                .doc(_uid)
                .collection('members')
                .snapshots(),
            builder: (context, snap) {
              return _StatCard(
                label: 'Members',
                value: '${snap.data?.docs.length ?? 0}',
                icon: Icons.groups_rounded,
                color: theme.colorScheme.primary,
                theme: theme,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('wellness_checkins')
                .doc(_uid)
                .collection('checkins')
                .orderBy('date', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snap) {
              double avg = 0;
              if (snap.hasData && snap.data!.docs.isNotEmpty) {
                final scores = snap.data!.docs
                    .map((d) => (d.data() as Map)['score'] as num? ?? 3)
                    .toList();
                avg = scores.reduce((a, b) => a + b) / scores.length;
              }

              return _StatCard(
                label: 'Avg Wellness',
                value: avg > 0 ? avg.toStringAsFixed(1) : '--',
                icon: Icons.favorite_rounded,
                color: theme.colorScheme.secondary,
                theme: theme,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('anonymous_reports')
                .doc(_uid)
                .collection('reports')
                .where('resolved', isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              return _StatCard(
                label: 'Open Reports',
                value: '${snap.data?.docs.length ?? 0}',
                icon: Icons.report_outlined,
                color: AppColors.warning,
                theme: theme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniHeatmap(ThemeData theme, bool isDark) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final depts = ['Engineering', 'Marketing', 'Sales', 'HR'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          // Day headers
          Row(
            children: [
              const SizedBox(width: 80),
              ...days.map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          // Dept rows
          ...depts.map((dept) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        dept,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...days.map((dayLabel) {
                      // Placeholder scores — will be Firestore-driven
                      final score = (dept.hashCode + dayLabel.hashCode) % 5 + 1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: _scoreColor(score, theme, isDark),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Low', AppColors.error.withValues(alpha: 0.2), theme),
              const SizedBox(width: 12),
              _legendItem('Mid', AppColors.warning.withValues(alpha: 0.25), theme),
              const SizedBox(width: 12),
              _legendItem('Good', AppColors.success.withValues(alpha: 0.25), theme),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score, ThemeData theme, bool isDark) {
    if (score <= 2) return AppColors.error.withValues(alpha: isDark ? 0.3 : 0.2);
    if (score <= 3) return AppColors.warning.withValues(alpha: isDark ? 0.3 : 0.25);
    return AppColors.success.withValues(alpha: isDark ? 0.3 : 0.25);
  }

  Widget _legendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReports(ThemeData theme, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('anonymous_reports')
          .doc(_uid)
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _shimmerCards(theme, isDark));
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reports — all clear!',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data =
                  snap.data!.docs[index].data() as Map<String, dynamic>;
              return _ReportPreviewCard(data: data, theme: theme);
            },
            childCount: snap.data!.docs.length,
          ),
        );
      },
    );
  }

  Widget _shimmerHeader(ThemeData theme, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 22,
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 30,
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerCards(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor: isDark
            ? AppColors.darkShimmerHighlight
            : AppColors.shimmerHighlight,
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 70,
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;

  const _ReportPreviewCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final category = data['category'] ?? 'General';
    final content = data['content'] ?? '';
    final resolved = data['resolved'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: resolved
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              resolved
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: resolved ? AppColors.success : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
