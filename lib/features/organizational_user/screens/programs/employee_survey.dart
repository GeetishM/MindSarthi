import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

class EmployeeSurveyPage extends ConsumerStatefulWidget {
  const EmployeeSurveyPage({super.key});

  @override
  ConsumerState<EmployeeSurveyPage> createState() => _EmployeeSurveyPageState();
}

class _EmployeeSurveyPageState extends ConsumerState<EmployeeSurveyPage> {
  late Future<List<Map<String, dynamic>>> _surveysFuture;

  @override
  void initState() {
    super.initState();
    _refreshSurveys();
  }

  void _refreshSurveys() {
    setState(() {
      _surveysFuture = _fetchSurveys();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSurveys() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return _getMockSurveys();

    try {
      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.surveysCollectionId,
        queries: [
          Query.equal('orgId', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      if (response.documents.isEmpty) {
        return _getMockSurveys();
      }

      return response.documents
          .map((doc) => {
                'id': doc.$id,
                'title': doc.data['title'] ?? 'Survey',
                'questions': List<String>.from(doc.data['questions'] ?? []),
                'responses': List<String>.from(doc.data['responses'] ?? []),
                'createdAt': doc.data['createdAt'] ?? '',
                'status': doc.data['status'] ?? 'active',
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching surveys: $e');
      return _getMockSurveys();
    }
  }

  List<Map<String, dynamic>> _getMockSurveys() {
    return [
      {
        'id': 'srv_1',
        'title': 'Q2 Work Wellness & Stress Check-in',
        'questions': [
          jsonEncode({'text': 'On a scale of 1-5, how would you rate your work-life balance?', 'type': 'scale'}),
          jsonEncode({'text': 'On a scale of 1-5, how supported do you feel by your manager?', 'type': 'scale'}),
          jsonEncode({'text': 'What is the biggest source of work-related stress currently?', 'type': 'text'}),
        ],
        'responses': [
          jsonEncode({'answers': ['4', '5', 'High workload in sprints']}),
          jsonEncode({'answers': ['2', '3', 'Lack of clear communication']}),
          jsonEncode({'answers': ['3', '4', 'Unrealistic deadlines']}),
          jsonEncode({'answers': ['5', '5', 'Everything is going great']}),
          jsonEncode({'answers': ['4', '4', 'Too many meetings']}),
        ],
        'createdAt': '2026-05-10',
        'status': 'active',
      },
      {
        'id': 'srv_2',
        'title': 'Workplace Environment & Ergonomics',
        'questions': [
          jsonEncode({'text': 'How satisfied are you with the hybrid office space setup?', 'type': 'scale'}),
          jsonEncode({'text': 'Any suggestions for office improvements?', 'type': 'text'}),
        ],
        'responses': [
          jsonEncode({'answers': ['4', 'Better office chairs']}),
          jsonEncode({'answers': ['3', 'Noise cancelling headphones would help']}),
          jsonEncode({'answers': ['5', 'No complaints']}),
        ],
        'createdAt': '2026-04-15',
        'status': 'closed',
      }
    ];
  }

  void _navigateToCreateSurvey() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSurveyScreen()),
    ).then((_) => _refreshSurveys());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => _refreshSurveys(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _surveysFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final surveys = snap.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: surveys.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: _navigateToCreateSurvey,
                      icon: const Icon(Icons.poll_outlined),
                      label: const Text('Launch Employee Survey'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  );
                }

                final survey = surveys[index - 1];
                return _buildSurveyCard(context, survey);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSurveyCard(BuildContext context, Map<String, dynamic> survey) {
    final theme = Theme.of(context);
    final title = survey['title'] ?? 'Survey';
    final date = survey['createdAt'] ?? '';
    final status = survey['status'] ?? 'active';
    final questions = survey['questions'] as List<dynamic>? ?? [];
    final responses = survey['responses'] as List<dynamic>? ?? [];

    final isActive = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SurveyDashboard(survey: survey),
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
                        color: isActive ? AppColors.success.withValues(alpha: 0.1) : theme.hintColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.success : theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created on $date',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.quiz_outlined, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      '${questions.length} Questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Icon(Icons.people_alt_outlined, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      '${responses.length} Submissions',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View Results →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    )
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

class SurveyDashboard extends StatelessWidget {
  final Map<String, dynamic> survey;

  const SurveyDashboard({super.key, required this.survey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = survey['title'] ?? 'Survey Dashboard';
    final questionsRaw = survey['questions'] as List<dynamic>? ?? [];
    final responsesRaw = survey['responses'] as List<dynamic>? ?? [];

    // Parse structures
    final List<Map<String, dynamic>> questions = questionsRaw.map((q) => Map<String, dynamic>.from(jsonDecode(q as String))).toList();
    final List<Map<String, dynamic>> responses = responsesRaw.map((r) => Map<String, dynamic>.from(jsonDecode(r as String))).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Survey Insights'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anonymous feedback analysis dashboard based on ${responses.length} responses.',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildMetricTile(context, 'Questions', '${questions.length}', Icons.help_outline),
                      const SizedBox(width: 16),
                      _buildMetricTile(context, 'Submissions', '${responses.length}', Icons.how_to_reg),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Question statistics
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final question = questions[index];
                  final qText = question['text'] ?? '';
                  final qType = question['type'] ?? 'scale';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                qText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.titleMedium?.color,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        if (qType == 'scale')
                          _buildScaleAnalytics(context, index, responses)
                        else
                          _buildTextAnalytics(context, index, responses),
                      ],
                    ),
                  );
                },
                childCount: questions.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.tertiary,
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScaleAnalytics(BuildContext context, int qIndex, List<Map<String, dynamic>> responses) {
    final theme = Theme.of(context);
    if (responses.isEmpty) {
      return const Center(child: Text('No response data yet.'));
    }

    // Tally options 1 to 5
    final tallies = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double sum = 0;
    int count = 0;

    for (var r in responses) {
      final answers = r['answers'] as List<dynamic>? ?? [];
      if (answers.length > qIndex) {
        final answerVal = int.tryParse(answers[qIndex].toString()) ?? 0;
        if (tallies.containsKey(answerVal)) {
          tallies[answerVal] = tallies[answerVal]! + 1;
          sum += answerVal;
          count++;
        }
      }
    }

    final double avg = count > 0 ? sum / count : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rating Distribution',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.hintColor),
            ),
            Text(
              'Average: ${avg.toStringAsFixed(1)} / 5.0',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (idx) {
          final star = 5 - idx;
          final votes = tallies[star] ?? 0;
          final pct = count > 0 ? votes / count : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextAnalytics(BuildContext context, int qIndex, List<Map<String, dynamic>> responses) {
    final theme = Theme.of(context);
    final answers = responses
        .map((r) {
          final ansList = r['answers'] as List<dynamic>? ?? [];
          return ansList.length > qIndex ? ansList[qIndex].toString() : '';
        })
        .where((ans) => ans.trim().isNotEmpty)
        .toList();

    if (answers.isEmpty) {
      return const Text('No feedback responses yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anonymous Comments (${answers.length})',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.hintColor),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: answers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        answers[idx],
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CreateSurveyScreen extends ConsumerStatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  ConsumerState<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends ConsumerState<CreateSurveyScreen> {
  final _titleCtrl = TextEditingController();
  bool _isCreating = false;
  final List<Map<String, String>> _questions = [
    {'text': 'How would you rate your overall stress level today? (1: High, 5: Low)', 'type': 'scale'}
  ];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchSurvey() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      AppToast.error(context, 'Please add at least one question');
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      AppToast.error(context, 'You must be logged in to create surveys');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final databases = AppwriteService().databases;
      final qList = _questions.map((q) => jsonEncode(q)).toList();

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.surveysCollectionId,
        documentId: ID.unique(),
        data: {
          'orgId': user.$id,
          'title': _titleCtrl.text.trim(),
          'questions': qList,
          'responses': <String>[],
          'createdAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'status': 'active',
        },
      );

      if (mounted) {
        AppToast.success(context, 'Survey launched successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to launch survey', description: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Survey'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (!_isCreating)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _launchSurvey,
                child: const Text('Launch', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: _isCreating
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Survey Title',
                      hintText: 'e.g., Q2 Workplace Climate Survey',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _questions.add({'text': '', 'type': 'scale'});
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_questions.length, (index) {
                    final question = _questions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: question['type'],
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down_rounded),
                                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13),
                                  items: const [
                                    DropdownMenuItem(value: 'scale', child: Text('1-5 Rating Scale')),
                                    DropdownMenuItem(value: 'text', child: Text('Free Text response')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _questions[index]['type'] = val);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _questions.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: question['text'],
                            decoration: const InputDecoration(
                              hintText: 'Enter question text',
                            ),
                            onChanged: (val) => _questions[index]['text'] = val,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter question text' : null,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
