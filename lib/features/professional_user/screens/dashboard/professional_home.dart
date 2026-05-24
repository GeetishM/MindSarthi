import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:shimmer/shimmer.dart';

class ProfessionalHome extends ConsumerStatefulWidget {
  const ProfessionalHome({super.key});

  @override
  ConsumerState<ProfessionalHome> createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends ConsumerState<ProfessionalHome> {
  late Future<Map<String, dynamic>> _dataFuture;
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _dataFuture = _fetchStatsAndSessions();
    _nameFuture = _fetchDoctorName();
  }

  Future<String> _fetchDoctorName() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return 'Doctor';
    try {
      final databases = AppwriteService().databases;
      final doc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: user.$id,
      );
      return doc.data['nickname'] ?? doc.data['username'] ?? 'Doctor';
    } catch (_) {
      return 'Doctor';
    }
  }

  Future<Map<String, dynamic>> _fetchStatsAndSessions() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      return {
        'todayCount': 0,
        'totalClients': 0,
        'completedCount': 0,
        'todaySessions': <Map<String, dynamic>>[],
      };
    }

    try {
      final databases = AppwriteService().databases;
      final allResponse = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.sessionsCollectionId,
        queries: [
          Query.equal('professionalUid', user.$id),
          Query.limit(100),
        ],
      );

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int todayCount = 0;
      int completedCount = 0;
      Set<String> clientIds = {};
      final List<Map<String, dynamic>> todaySessions = [];

      for (var doc in allResponse.documents) {
        final data = Map<String, dynamic>.from(doc.data);
        data['id'] = doc.$id;

        if (data['date'] == today) {
          todaySessions.add(data);
          if (data['status'] == 'upcoming') {
            todayCount++;
          }
        }
        if (data['status'] == 'completed') {
          completedCount++;
        }
        if (data['clientUid'] != null) {
          clientIds.add(data['clientUid']);
        }
      }

      todaySessions.sort((a, b) => (a['startTime'] ?? '').compareTo(b['startTime'] ?? ''));

      return {
        'todayCount': todayCount,
        'totalClients': clientIds.length,
        'completedCount': completedCount,
        'todaySessions': todaySessions,
      };
    } catch (e) {
      debugPrint('Error fetching professional home data: $e');
      return {
        'todayCount': 0,
        'totalClients': 0,
        'completedCount': 0,
        'todaySessions': <Map<String, dynamic>>[],
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
          child: CustomScrollView(
            slivers: [
              // ── Header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: FutureBuilder<String>(
                    future: _nameFuture,
                    builder: (context, snap) {
                      final name = snap.data ?? 'Doctor';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dr. $name 👋',
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

              // ── Stats Row ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _dataFuture,
                    builder: (context, snap) {
                      final todayCount = snap.data?['todayCount'] ?? 0;
                      final totalClients = snap.data?['totalClients'] ?? 0;
                      final completedCount = snap.data?['completedCount'] ?? 0;

                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: "Today's Sessions",
                              value: '$todayCount',
                              icon: Icons.today_rounded,
                              color: theme.colorScheme.primary,
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Total Clients',
                              value: '$totalClients',
                              icon: Icons.people_rounded,
                              color: theme.colorScheme.secondary,
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Completed',
                              value: '$completedCount',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Today's Schedule Header ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyLarge?.color,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Today's Sessions Stream ────────────────────────
              _buildTodaySessions(theme, isDark),

              // ── Bottom padding for nav bar ─────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildTodaySessions(ThemeData theme, bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _buildShimmer(theme, isDark));
        }

        final sessions = snap.data?['todaySessions'] as List<Map<String, dynamic>>?;

        if (sessions == null || sessions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 56,
                    color: theme.textTheme.labelSmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions scheduled today',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add sessions from the Sessions tab',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.labelSmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _SessionCard(data: sessions[index], theme: theme, isDark: isDark);
            },
            childCount: sessions.length,
          ),
        );
      },
    );
  }

  Widget _buildShimmer(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor:
            isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
    required this.isDark,
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

// ── Session Card ────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;
  final bool isDark;

  const _SessionCard({required this.data, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'upcoming';
    final statusColor = status == 'completed'
        ? AppColors.success
        : status == 'cancelled'
            ? AppColors.error
            : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Time column
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  data['startTime'] ?? '--:--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  data['endTime'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['clientName'] ?? 'Client',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (data['notes'] != null && data['notes'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data['notes'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
