import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/features/professional_user/screens/sessions/add_session_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class SessionList extends ConsumerStatefulWidget {
  const SessionList({super.key});

  @override
  ConsumerState<SessionList> createState() => _SessionListState();
}

class _SessionListState extends ConsumerState<SessionList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sessions',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.headlineSmall?.color ?? theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddSession(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Session',
              style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionTab('upcoming', isDark),
          _buildSessionTab('completed', isDark),
          _buildSessionTab('cancelled', isDark),
        ],
      ),
    );
  }

  void _showAddSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSessionSheet(),
    ).then((_) {
      setState(() {});
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSessions(String status) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return [];

    try {
      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.sessionsCollectionId,
        queries: [
          Query.equal('professionalUid', user.$id),
          Query.equal('status', status),
          Query.orderDesc('date'),
          Query.limit(100),
        ],
      );
      return response.documents.map((doc) {
        final data = Map<String, dynamic>.from(doc.data);
        data['id'] = doc.$id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupSessionsByDate(List<Map<String, dynamic>> sessions) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var session in sessions) {
      final dateStr = session['date'] as String? ?? 'No Date';
      String groupHeader = dateStr;
      try {
        final dt = DateTime.parse(dateStr);
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
          groupHeader = 'Today';
        } else if (dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day) {
          groupHeader = 'Tomorrow';
        } else {
          groupHeader = DateFormat('EEEE, MMM d, yyyy').format(dt);
        }
      } catch (_) {}

      if (!groups.containsKey(groupHeader)) {
        groups[groupHeader] = [];
      }
      groups[groupHeader]!.add(session);
    }
    return groups;
  }

  Widget _buildSessionTab(String status, bool isDark) {
    final theme = Theme.of(context);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSessions(status),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildShimmer(isDark);
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'upcoming'
                          ? Icons.calendar_month_rounded
                          : status == 'completed'
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No ${status[0].toUpperCase() + status.substring(1)} Sessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status == 'upcoming'
                        ? 'Schedule a new counselling session to get started.'
                        : 'Completed sessions will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  if (status == 'upcoming') ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddSession(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final sessions = snap.data!;
        final grouped = _groupSessionsByDate(sessions);
        final List<dynamic> items = [];
        grouped.forEach((date, sessionList) {
          items.add(date);
          items.addAll(sessionList);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is String) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                child: Text(
                  item.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              );
            }

            final data = item as Map<String, dynamic>;
            final docId = data['id'];
            return _SessionCard(
              data: data,
              docId: docId,
              isDark: isDark,
              onStatusChange: status == 'upcoming'
                  ? (newStatus) => _updateStatus(docId, newStatus)
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      final databases = AppwriteService().databases;
      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.sessionsCollectionId,
        documentId: docId,
        data: {'status': newStatus},
      );
      setState(() {});
      if (mounted) {
        AppToast.success(context, 'Session marked as $newStatus');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to update status', description: e.toString());
      }
    }
  }

  Widget _buildShimmer(bool isDark) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (_, index) => Shimmer.fromColors(
        baseColor: AppTheme.getShimmerBaseColor(context),
        highlightColor: AppTheme.getShimmerHighlightColor(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isDark;
  final void Function(String)? onStatusChange;

  const _SessionCard({
    required this.data,
    required this.docId,
    required this.isDark,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = data['status'] ?? 'upcoming';
    final statusColor = status == 'completed'
        ? AppColors.success
        : status == 'cancelled'
            ? AppColors.error
            : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.tertiary,
                child: Text(
                  (data['clientName'] ?? 'C')[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      '${data['date'] ?? ''} • ${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          if (onStatusChange != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onStatusChange!('completed'),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Complete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => onStatusChange!('cancelled'),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
