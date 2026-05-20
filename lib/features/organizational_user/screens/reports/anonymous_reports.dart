import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/organizational_user/screens/reports/submit_report.dart';
import 'package:shimmer/shimmer.dart';

class AnonymousReports extends StatefulWidget {
  const AnonymousReports({super.key});

  @override
  State<AnonymousReports> createState() => _AnonymousReportsState();
}

class _AnonymousReportsState extends State<AnonymousReports>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reports',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          labelColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubmitReport()),
        ),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Submit Report',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportTab(false, isDark),
          _buildReportTab(true, isDark),
        ],
      ),
    );
  }

  Widget _buildReportTab(bool resolved, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('anonymous_reports')
          .doc(_uid)
          .collection('reports')
          .where('resolved', isEqualTo: resolved)
          .orderBy('timestamp', descending: true)
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
                  resolved
                      ? Icons.check_circle_outline_rounded
                      : Icons.inbox_rounded,
                  size: 56,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  resolved ? 'No resolved reports' : 'No open reports',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
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
            final doc = snap.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _ReportCard(
              data: data,
              docId: doc.id,
              orgId: _uid!,
              isDark: isDark,
              isResolved: resolved,
            );
          },
        );
      },
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor: isDark
            ? AppColors.darkShimmerHighlight
            : AppColors.shimmerHighlight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String orgId;
  final bool isDark;
  final bool isResolved;

  const _ReportCard({
    required this.data,
    required this.docId,
    required this.orgId,
    required this.isDark,
    required this.isResolved,
  });

  @override
  Widget build(BuildContext context) {
    final category = data['category'] ?? 'General';
    final content = data['content'] ?? '';

    final categoryColors = {
      'Harassment': AppColors.error,
      'Workload': AppColors.warning,
      'Management': AppColors.accent,
      'Environment': isDark ? AppColors.darkPrimary : AppColors.primary,
      'Other': isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
    };

    final color = categoryColors[category] ??
        (isDark ? AppColors.darkPrimary : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.shield_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                'Anonymous',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (!isResolved) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _resolve(context),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Mark Resolved'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _resolve(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('anonymous_reports')
        .doc(orgId)
        .collection('reports')
        .doc(docId)
        .update({'resolved': true});

    if (context.mounted) {
      AppToast.success(context, 'Report marked as resolved');
    }
  }
}
