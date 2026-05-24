import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/app_dialog.dart';
import 'insight_data.dart';

class InsightCmsPage extends StatefulWidget {
  const InsightCmsPage({super.key});

  @override
  State<InsightCmsPage> createState() => _InsightCmsPageState();
}

class _InsightCmsPageState extends State<InsightCmsPage> {
  final _uuid = const Uuid();

  void _showFormDialog({Insight? insight}) {
    final isEdit = insight != null;
    final headingController = TextEditingController(text: insight?.heading ?? '');
    final authorController = TextEditingController(text: insight?.author ?? 'Team MindSarthi');
    final categoryController = TextEditingController(text: insight?.category ?? '');
    final contentController = TextEditingController(text: insight?.content ?? '');

    showCupertinoDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return CupertinoAlertDialog(
          title: Text(isEdit ? 'Edit Insight' : 'Add Insight'),
          content: Container(
            margin: const EdgeInsets.only(top: 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoTextField(
                    controller: headingController,
                    placeholder: 'Title',
                    placeholderStyle: TextStyle(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: authorController,
                    placeholder: 'Author',
                    placeholderStyle: TextStyle(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: categoryController,
                    placeholder: 'Category (e.g., Panic Attacks, Insomnia)',
                    placeholderStyle: TextStyle(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: contentController,
                    placeholder: 'Content/Body',
                    placeholderStyle: TextStyle(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    maxLines: 5,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final heading = headingController.text.trim();
                final author = authorController.text.trim();
                final category = categoryController.text.trim();
                final content = contentController.text.trim();

                if (heading.isEmpty || content.isEmpty || author.isEmpty) {
                  MindSarthiDialog.show(
                    context: context,
                    title: 'Validation Error',
                    content: 'Title, Author, and Content cannot be empty.',
                    confirmText: 'OK',
                    cancelText: 'Cancel',
                  );
                  return;
                }

                final dateStr = DateFormat.yMMMd().format(DateTime.now());
                final id = isEdit ? insight.id : _uuid.v4();

                final newInsight = Insight(
                  id: id,
                  heading: heading,
                  content: content,
                  author: author,
                  date: dateStr,
                  category: category,
                );

                try {
                  if (isEdit) {
                    await Insight.updateInsight(newInsight);
                  } else {
                    await Insight.addInsight(newInsight);
                  }
                  if (context.mounted) {
                    Navigator.pop(context); // Close form dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Insight updated successfully!' : 'Insight added successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    MindSarthiDialog.show(
                      context: context,
                      title: 'Error',
                      content: 'Failed to save: $e',
                      confirmText: 'OK',
                      cancelText: 'Cancel',
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String id) async {
    final confirm = await MindSarthiDialog.show(
      context: context,
      title: 'Delete Insight?',
      content: 'Are you sure you want to permanently delete this insight? This action cannot be undone.',
      confirmText: 'Yes, Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (confirm == true) {
      try {
        await Insight.deleteInsight(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insight deleted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          await MindSarthiDialog.show(
            context: context,
            title: 'Error',
            content: 'Failed to delete: $e',
            confirmText: 'OK',
            cancelText: 'Cancel',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Insights CMS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showFormDialog(),
            child: Icon(
              CupertinoIcons.add_circled_solid,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<List<Insight>>(
        stream: Insight.insightsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          List<Insight> insights = [];
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            insights = snapshot.data!;
          } else {
            insights = insightsList;
          }

          if (insights.isEmpty) {
            return Center(
              child: Text(
                'No insights found in Firestore.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: insights.length,
            separatorBuilder: (context, index) => Divider(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final insight = insights[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (insight.category.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                insight.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            insight.heading,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'By ${insight.author} • ${insight.date}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      key: ValueKey('edit_${insight.id}'),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showFormDialog(insight: insight),
                      child: Icon(
                        CupertinoIcons.pencil,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        size: 22,
                      ),
                    ),
                    CupertinoButton(
                      key: ValueKey('delete_${insight.id}'),
                      padding: EdgeInsets.zero,
                      onPressed: () => _confirmDelete(insight.id),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.destructiveRed,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
