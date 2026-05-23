import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'journal_entry.dart';
import 'journal_edit.dart';
import 'journal_new.dart';
import 'shadow_journal_screen.dart';
import 'entry_dates.dart';
import 'ai_service.dart';
import 'journal_insights.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';
import 'package:mindsarthi/core/widgets/premium_search_bar.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  bool isListView = true;
  late Box<JournalEntry> journalBox;
  late Box journalSettingsBox;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    journalBox = Hive.box<JournalEntry>('journalBox');
    journalSettingsBox = Hive.box('journalSettings');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dialog to prompt the user for their Gemini API Key if missing
  void _showApiKeyDialog() {
    final controller = TextEditingController(
      text: JournalAIService.getApiKey(),
    );
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary;

        return AlertDialog(
          title: Text(
            "Gemini API Key",
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Provide a Gemini API Key to enable voice transcription. Get one for free from Google AI Studio.",
                style: TextStyle(
                  color: textPrimary.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                JournalAIService.saveApiKey(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Gemini API Key saved successfully"),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors
    final primaryColor = Theme.of(context).colorScheme.primary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          context.tr('jr_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.chart_bar_square, color: primaryColor, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalInsightsScreen()),
            ),
            tooltip: context.tr('jr_sentiment'),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.settings, color: primaryColor, size: 20),
            onPressed: _showApiKeyDialog,
            tooltip: 'Configure Gemini API Key',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Premium Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: PremiumSearchBar(
                  controller: _searchController,
                  hintText: 'Search by title, tag, or content...',
                  onChanged: (value) {
                    setState(() => searchQuery = value.toLowerCase());
                  },
                  onClear: () {
                    setState(() => searchQuery = '');
                  },
                ),
              ),
              // Segmented view-picker (iOS sliding segment)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: isListView,
                  backgroundColor: isDark
                      ? AppColors.darkBackground
                      : Colors.grey.shade100,
                  thumbColor: primaryColor,
                  children: {
                    true: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.list_bullet,
                            size: 16,
                            color: isListView ? Colors.white : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "List",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isListView ? Colors.white : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    false: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.square_grid_2x2,
                            size: 16,
                            color: !isListView ? Colors.white : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Grid",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: !isListView ? Colors.white : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() {
                        isListView = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: journalBox.listenable(),
        builder: (context, Box<JournalEntry> box, _) {
          final entries =
              box.values
                  .where(
                    (entry) =>
                        entry.title.toLowerCase().contains(searchQuery) ||
                        entry.content.toLowerCase().contains(searchQuery) ||
                        entry.tag.any(
                          (t) => t.toLowerCase().contains(searchQuery),
                        ) ||
                        entry.createdAt.toString().toLowerCase().contains(
                          searchQuery,
                        ),
                  )
                  .toList()
                ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.book,
                      size: 64,
                      color: textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Your journal is a sanctuary.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Express your feelings, capture memories, and outline your dreams. Tap the mic below to start a Voice-based AI journal entry, or pencil to write.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return isListView
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol, width: 0.8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            entry.title.isEmpty
                                ? "Untitled Entry"
                                : entry.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              if (entry.tag.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: entry.tag
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Divider(color: borderCol, height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  EntryDates(
                                    createdAt: entry.createdAt,
                                    lastEdited: entry.lastEdited,
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: textSecondary.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JournalEdit(
                                  entry: entry,
                                  index: box.keys.toList().indexOf(entry.key),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: entries.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol, width: 0.8),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JournalEdit(
                                entry: entry,
                                index: box.keys.toList().indexOf(entry.key),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title.isEmpty ? "Untitled" : entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  entry.content,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              EntryDates(
                                createdAt: entry.createdAt,
                                lastEdited: entry.lastEdited,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                CupertinoIcons.pencil,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JournalNew()),
              ),
              tooltip: 'Write Entry',
            ),
            Container(width: 1, height: 24, color: Colors.white24),
            IconButton(
              icon: const Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShadowJournalScreen()),
              ),
              tooltip: 'Shadow Journaling',
            ),
            Container(width: 1, height: 24, color: Colors.white24),
            IconButton(
              icon: const Icon(
                CupertinoIcons.mic_fill,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JournalNew(autoStartRecord: true),
                ),
              ),
              tooltip: 'Voice-based AI Entry',
            ),
          ],
        ),
      ),
    );
  }
}
