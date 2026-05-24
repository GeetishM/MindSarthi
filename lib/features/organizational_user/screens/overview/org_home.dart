import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/organizational_user/screens/team/wellness_heatmap.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:shimmer/shimmer.dart';

class OrgHome extends ConsumerStatefulWidget {
  const OrgHome({super.key});

  @override
  ConsumerState<OrgHome> createState() => _OrgHomeState();
}

class _OrgHomeState extends ConsumerState<OrgHome> {
  late Future<Map<String, dynamic>> _orgDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _orgDataFuture = _fetchOrgData();
  }

  Future<Map<String, dynamic>> _fetchOrgData() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      return {
        'orgName': 'Organization',
        'memberCount': 0,
        'avgWellness': 3.5,
        'openReports': 0,
        'reports': <Map<String, dynamic>>[],
      };
    }

    try {
      final databases = AppwriteService().databases;
      
      // 1. Fetch Org Name
      String orgName = 'Organization';
      try {
        final doc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: user.$id,
        );
        orgName = doc.data['orgName'] ?? doc.data['nickname'] ?? doc.data['username'] ?? 'Organization';
      } catch (_) {}

      // 2. Fetch Members (users where orgId == user.$id)
      int memberCount = 0;
      try {
        final membersRes = await databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          queries: [
            Query.equal('orgId', user.$id),
            Query.limit(100),
          ],
        );
        memberCount = membersRes.total;
      } catch (_) {
        memberCount = 12; 
      }

      // 3. Wellness Checkins / Moods
      double avgWellness = 4.2;

      // 4. Reports
      final List<Map<String, dynamic>> mockReports = [
        {
          'category': 'Workload',
          'content': 'We need more realistic deadlines for the upcoming sprint. Teams are working overtime.',
          'resolved': false,
        },
        {
          'category': 'Mental Health',
          'content': 'Would appreciate having weekly guided meditation sessions in the office.',
          'resolved': true,
        },
      ];

      return {
        'orgName': orgName,
        'memberCount': memberCount,
        'avgWellness': avgWellness,
        'openReports': mockReports.where((r) => r['resolved'] == false).length,
        'reports': mockReports,
      };
    } catch (e) {
      debugPrint('Error fetching org data: $e');
      return {
        'orgName': 'Organization',
        'memberCount': 12,
        'avgWellness': 4.2,
        'openReports': 1,
        'reports': [
          {
            'category': 'Workload',
            'content': 'We need more realistic deadlines for the upcoming sprint. Teams are working overtime.',
            'resolved': false,
          }
        ],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _refreshData();
            });
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: _orgDataFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(theme, isDark);
              }

              final data = snap.data ?? {};
              final orgName = data['orgName'] ?? 'Organization';

              return CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
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
                      ),
                    ),
                  ),

                  // ── Stats Row ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Members',
                              value: '${data['memberCount'] ?? 0}',
                              icon: Icons.groups_rounded,
                              color: theme.colorScheme.primary,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Avg Wellness',
                              value: data['avgWellness'] != null
                                  ? (data['avgWellness'] as double).toStringAsFixed(1)
                                  : '--',
                              icon: Icons.favorite_rounded,
                              color: theme.colorScheme.secondary,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Open Reports',
                              value: '${data['openReports'] ?? 0}',
                              icon: Icons.report_outlined,
                              color: AppColors.warning,
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
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
                  _buildRecentReportsList(data['reports'] as List<Map<String, dynamic>>?, theme, isDark),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _shimmerHeader(theme, isDark),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _shimmerCards(theme, isDark),
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

  Widget _buildRecentReportsList(List<Map<String, dynamic>>? reports, ThemeData theme, bool isDark) {
    if (reports == null || reports.isEmpty) {
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
          final data = reports[index];
          return _ReportPreviewCard(data: data, theme: theme);
        },
        childCount: reports.length,
      ),
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
