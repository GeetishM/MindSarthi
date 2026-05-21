import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/bookmark_manager.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_card.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_data.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_details_page.dart';

class BookmarkedPage extends StatefulWidget {
  const BookmarkedPage({super.key});

  @override
  State<BookmarkedPage> createState() => _BookmarkedPageState();
}

class _BookmarkedPageState extends State<BookmarkedPage> {
  Set<String> bookmarkedIds = {};
  bool _isLoadingIds = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedIds();
  }

  Future<void> _loadBookmarkedIds() async {
    final ids = await BookmarkManager.getBookmarkedIds();
    if (mounted) {
      setState(() {
        bookmarkedIds = ids.toSet();
        _isLoadingIds = false;
      });
    }
  }

  void _toggleBookmark(String id) async {
    await BookmarkManager.toggleBookmark(id);
    _loadBookmarkedIds();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bookmarked Insights',
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
      ),
      body: _isLoadingIds
          ? const Center(child: CupertinoActivityIndicator())
          : StreamBuilder<List<Insight>>(
              stream: Insight.insightsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                List<Insight> allInsights = [];
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  allInsights = snapshot.data!;
                } else {
                  allInsights = insightsList;
                }

                final bookmarkedInsights = allInsights
                    .where((insight) => bookmarkedIds.contains(insight.id))
                    .toList();

                if (bookmarkedInsights.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.bookmark,
                          size: 56,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bookmarked insights yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: bookmarkedInsights.length,
                  itemBuilder: (context, index) {
                    final insight = bookmarkedInsights[index];
                    return InsightCard(
                      heading: insight.heading,
                      content: insight.content,
                      author: insight.author,
                      date: insight.date,
                      category: insight.category,
                      isBookmarked: true,
                      onBookmarkToggle: () => _toggleBookmark(insight.id),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => InsightDetailPage(
                              heading: insight.heading,
                              content: insight.content,
                              author: insight.author,
                              date: insight.date,
                              category: insight.category,
                            ),
                          ),
                        );
                        _loadBookmarkedIds();
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
