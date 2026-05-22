import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/professional_user/screens/sessions/add_session_sheet.dart';
import 'package:shimmer/shimmer.dart';

class SessionList extends StatefulWidget {
  const SessionList({super.key});

  @override
  State<SessionList> createState() => _SessionListState();
}

class _SessionListState extends State<SessionList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSession(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Session',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
    );
  }

  Widget _buildSessionTab(String status, bool isDark) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('professionalUid', isEqualTo: _uid)
          .where('status', isEqualTo: status)
          .orderBy('date', descending: status == 'completed')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildShimmer(isDark);
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'upcoming'
                      ? Icons.event_available_rounded
                      : status == 'completed'
                          ? Icons.task_alt_rounded
                          : Icons.event_busy_rounded,
                  size: 56,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4) ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status sessions',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snap.data!.docs[index].data() as Map<String, dynamic>;
            final docId = snap.data!.docs[index].id;
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
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(docId)
        .update({'status': newStatus});
    if (mounted) {
      AppToast.success(context, 'Session marked as $newStatus');
    }
  }

  Widget _buildShimmer(bool isDark) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (_, index) => Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor: isDark
            ? AppColors.darkShimmerHighlight
            : AppColors.shimmerHighlight,
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
