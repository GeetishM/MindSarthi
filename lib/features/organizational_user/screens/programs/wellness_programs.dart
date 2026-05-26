import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/features/organizational_user/screens/programs/employee_survey.dart';

class WellnessProgramsPage extends ConsumerStatefulWidget {
  const WellnessProgramsPage({super.key});

  @override
  ConsumerState<WellnessProgramsPage> createState() => _WellnessProgramsPageState();
}

class _WellnessProgramsPageState extends ConsumerState<WellnessProgramsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshPrograms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshPrograms() {
    setState(() {
      _programsFuture = _fetchPrograms();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPrograms() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return _getMockPrograms();

    try {
      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.wellnessProgramsCollectionId,
        queries: [
          Query.equal('orgId', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      if (response.documents.isEmpty) {
        return _getMockPrograms();
      }

      return response.documents
          .map((doc) => {
                'id': doc.$id,
                'title': doc.data['title'] ?? 'Program',
                'description': doc.data['description'] ?? '',
                'startDate': doc.data['startDate'] ?? '',
                'endDate': doc.data['endDate'] ?? '',
                'participants': List<String>.from(doc.data['participants'] ?? []),
                'status': doc.data['status'] ?? 'active',
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching wellness programs: $e');
      return _getMockPrograms();
    }
  }

  List<Map<String, dynamic>> _getMockPrograms() {
    return [
      {
        'id': 'prog_1',
        'title': 'Mindful Mondays Meditation',
        'description': 'Weekly guided mindfulness session for engineering teams to reduce stress and anxiety.',
        'startDate': '2026-05-01',
        'endDate': '2026-08-31',
        'participants': ['All Engineering'],
        'status': 'active',
      },
      {
        'id': 'prog_2',
        'title': 'Sleep Hygiene workshop',
        'description': 'Interactive workshop teaching sleep optimization strategies and digital detox guidelines.',
        'startDate': '2026-06-15',
        'endDate': '2026-06-16',
        'participants': ['Marketing', 'Sales', 'HR'],
        'status': 'upcoming',
      },
      {
        'id': 'prog_3',
        'title': 'De-stress Walk Challenge',
        'description': 'Encouraging daily 15-minute walks during lunchtime with team leaderboard.',
        'startDate': '2026-04-01',
        'endDate': '2026-04-30',
        'participants': ['All Employees'],
        'status': 'completed',
      },
    ];
  }

  Future<void> _createProgram(String title, String desc, DateTime start, DateTime end, List<String> target) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (mounted) {
        AppToast.error(context, 'You must be logged in to create programs');
      }
      return;
    }

    try {
      final databases = AppwriteService().databases;
      final now = DateTime.now();
      String status = 'active';
      if (start.isAfter(now)) {
        status = 'upcoming';
      } else if (end.isBefore(now)) {
        status = 'completed';
      }

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.wellnessProgramsCollectionId,
        documentId: ID.unique(),
        data: {
          'orgId': user.$id,
          'title': title,
          'description': desc,
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end),
          'participants': target,
          'status': status,
        },
      );

      if (mounted) {
        AppToast.success(context, 'Wellness program created successfully');
      }
      _refreshPrograms();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to create program', description: e.toString());
      }
    }
  }

  void _showCreateProgramDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    List<String> targetDepts = ['All Employees'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'New Wellness Program',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Program Title',
                          hintText: 'e.g., Meditation Workshop',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'What is this program about?',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description' : null,
                      ),
                      const SizedBox(height: 16),
                      // Date selectors
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                );
                                if (selected != null) {
                                  setDialogState(() {
                                    startDate = selected;
                                    if (endDate.isBefore(startDate)) {
                                      endDate = startDate.add(const Duration(days: 7));
                                    }
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Start: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                );
                                if (selected != null) {
                                  setDialogState(() => endDate = selected);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'End: ${DateFormat('yyyy-MM-dd').format(endDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Target department
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Target Audience',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: targetDepts.first,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All Employees', child: Text('All Employees')),
                          DropdownMenuItem(value: 'Engineering', child: Text('Engineering')),
                          DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                          DropdownMenuItem(value: 'Sales', child: Text('Sales')),
                          DropdownMenuItem(value: 'HR', child: Text('HR')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => targetDepts = [val]);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _createProgram(
                        titleCtrl.text,
                        descCtrl.text,
                        startDate,
                        endDate,
                        targetDepts,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Programs & Surveys',
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Wellness Programs'),
            Tab(text: 'Employee Surveys'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Wellness Programs
          RefreshIndicator(
            onRefresh: () async => _refreshPrograms(),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _programsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final programs = snap.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  itemCount: programs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          onPressed: _showCreateProgramDialog,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Launch Wellness Program'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                          ),
                        ),
                      );
                    }

                    final program = programs[index - 1];
                    return _buildProgramCard(context, program);
                  },
                );
              },
            ),
          ),
          // Tab 2: Employee Surveys
          const EmployeeSurveyPage(),
        ],
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, Map<String, dynamic> program) {
    final theme = Theme.of(context);
    final status = program['status'] ?? 'active';
    final start = program['startDate'] ?? '';
    final end = program['endDate'] ?? '';
    final title = program['title'] ?? '';
    final desc = program['description'] ?? '';
    final targets = (program['participants'] as List<dynamic>?)?.join(', ') ?? 'All Employees';

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'upcoming':
        statusColor = theme.colorScheme.primary;
        break;
      default:
        statusColor = theme.hintColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // View Program Detail dialog
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      desc,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '$start to $end',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Audience: $targets',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      '$start — $end',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.groups_outlined, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      targets,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
