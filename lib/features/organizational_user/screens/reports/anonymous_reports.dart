import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/organizational_user/screens/reports/submit_report.dart';

class AnonymousReports extends StatefulWidget {
  const AnonymousReports({super.key});

  @override
  State<AnonymousReports> createState() => _AnonymousReportsState();
}

class _AnonymousReportsState extends State<AnonymousReports>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local list of mock reports to drive the UI
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'rep_1',
      'category': 'Workload',
      'content': 'We need more realistic deadlines for the upcoming sprint. Teams are working overtime.',
      'resolved': false,
    },
    {
      'id': 'rep_2',
      'category': 'Environment',
      'content': 'The air conditioning in the open office area is way too cold, making it hard to focus.',
      'resolved': false,
    },
    {
      'id': 'rep_3',
      'category': 'Management',
      'content': 'Would appreciate having weekly 1-on-1 check-ins with managers to align on expectations.',
      'resolved': true,
    },
  ];

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

  void _resolveReport(String reportId) {
    setState(() {
      final index = _reports.indexWhere((r) => r['id'] == reportId);
      if (index != -1) {
        _reports[index]['resolved'] = true;
      }
    });
    AppToast.success(context, 'Report marked as resolved');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reports',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyLarge?.color,
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
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
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
        ).then((_) {
          // If we added a report, simulate adding it here
        }),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Submit Report',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportTab(false, theme, isDark),
          _buildReportTab(true, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildReportTab(bool resolved, ThemeData theme, bool isDark) {
    final filteredReports = _reports.where((r) => r['resolved'] == resolved).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              resolved
                  ? Icons.check_circle_outline_rounded
                  : Icons.inbox_rounded,
              size: 56,
              color: theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              resolved ? 'No resolved reports' : 'No open reports',
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
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final data = filteredReports[index];
        return _ReportCard(
          data: data,
          docId: data['id'],
          theme: theme,
          isResolved: resolved,
          onResolve: () => _resolveReport(data['id']),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final ThemeData theme;
  final bool isResolved;
  final VoidCallback onResolve;

  const _ReportCard({
    required this.data,
    required this.docId,
    required this.theme,
    required this.isResolved,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final category = data['category'] ?? 'General';
    final content = data['content'] ?? '';

    final categoryColors = {
      'Harassment': AppColors.error,
      'Workload': AppColors.warning,
      'Management': theme.colorScheme.secondary,
      'Environment': theme.colorScheme.primary,
      'Other': theme.textTheme.bodyMedium?.color ?? Colors.grey,
    };

    final color = categoryColors[category] ?? theme.colorScheme.primary;

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
                color: theme.hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Anonymous',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.5,
            ),
          ),
          if (!isResolved) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onResolve,
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
}
