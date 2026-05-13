import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/Bookmarked_screen.dart';
import 'bookmark_manager.dart';
import 'insight_card.dart';
import 'insight_data.dart';
import 'insight_details_page.dart';


class InsightPage extends StatefulWidget {
  const InsightPage({super.key});

  @override
  State<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  Set<String> bookmarkedIds = {};
  String selectedTag = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final ids = await BookmarkManager.getBookmarkedIds();
    setState(() {
      bookmarkedIds = ids.toSet();
    });
  }

  void _toggleBookmark(String id) async {
    await BookmarkManager.toggleBookmark(id);
    _loadBookmarks();
  }

  List<Insight> _filterInsights() {
    if (selectedTag == 'ALL') return insightsList;

    // Add your tag filtering logic here. For now, dummy filter:
    return insightsList.where((insight) => insight.heading.contains(selectedTag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredInsights = _filterInsights();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark_border_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkedPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['ALL', 'For You', 'Adult ADHD', 'Insomnia', 'Panic Attacks']
                  .map((tag) => tagChip(tag))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredInsights.length,
              itemBuilder: (context, index) {
                final insight = filteredInsights[index];
                return InsightCard(
                  heading: insight.heading,
                  content: insight.content,
                  author: insight.author,
                  date: insight.date,
                  isBookmarked: bookmarkedIds.contains(insight.id),
                  onBookmarkToggle: () => _toggleBookmark(insight.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InsightDetailPage(
                          heading: insight.heading,
                          content: insight.content,
                          author: insight.author,
                          date: insight.date,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget tagChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedTag == label;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        side: BorderSide(
          color: isSelected 
              ? Colors.transparent 
              : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: TextStyle(
          color: isSelected 
              ? AppColors.white 
              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
        onSelected: (_) {
          setState(() => selectedTag = label);
        },
      ),
    );
  }
}
