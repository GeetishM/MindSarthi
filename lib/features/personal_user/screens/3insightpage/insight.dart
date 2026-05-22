import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/Bookmarked_screen.dart';
import 'package:mindsarthi/core/widgets/premium_search_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'bookmark_manager.dart';
import 'insight_card.dart';
import 'insight_data.dart';
import 'insight_details_page.dart';
import 'insight_cms.dart';

class InsightPage extends StatefulWidget {
  const InsightPage({super.key});

  @override
  State<InsightPage> createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  Set<String> bookmarkedIds = {};
  String selectedTag = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Insight> _applyFilter(List<Insight> insights) {
    List<Insight> results = insights;

    // Apply tag/category filter
    if (selectedTag != 'ALL' && selectedTag != 'For You') {
      results = results
          .where((i) => i.category.toLowerCase() == selectedTag.toLowerCase())
          .toList();
    }

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results
          .where((i) =>
              i.heading.toLowerCase().contains(query) ||
              i.category.toLowerCase().contains(query) ||
              i.content.toLowerCase().contains(query))
          .toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'DISCOVER',
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
          if (Insight.isTestingMode)
            IconButton(
              key: const ValueKey('cms_nav_button'),
              icon: Icon(
                CupertinoIcons.pencil_ellipsis_rectangle,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const InsightCmsPage()),
                );
                setState(() {});
              },
            ),
          IconButton(
            key: const ValueKey('bookmarks_nav_button'),
            icon: Icon(
              CupertinoIcons.bookmark,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const BookmarkedPage()),
              );
              _loadBookmarks();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Cupertino Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PremiumSearchBar(
              controller: _searchController,
              hintText: 'Search topics, categories, articles...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // StreamBuilder for real-time Firestore feed + dynamic categories
          Expanded(
            child: StreamBuilder<List<Insight>>(
              stream: Insight.insightsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerList(isDark);
                }

                // Determine active tags dynamically
                final List<String> tags = ['ALL', 'For You'];
                List<Insight> insights = [];

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  insights = snapshot.data!;
                  
                  final dbTags = insights
                      .map((i) => i.category.trim())
                      .where((c) => c.isNotEmpty)
                      .toSet()
                      .toList();
                  dbTags.sort();
                  tags.addAll(dbTags);
                } else {
                  insights = insightsList;
                  tags.addAll(['Adult ADHD', 'Insomnia', 'Panic Attacks']);
                }

                final filtered = _applyFilter(insights);

                return Column(
                  children: [
                    // Premium category tag pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: tags.map((tag) => _tagChip(tag, isDark)).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.search,
                                    size: 56,
                                    color: isDark
                                        ? AppColors.darkTextHint
                                        : AppColors.textHint,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No matching insights found.',
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
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final insight = filtered[index];
                                return InsightCard(
                                  heading: insight.heading,
                                  content: insight.content,
                                  author: insight.author,
                                  date: insight.date,
                                  category: insight.category,
                                  isBookmarked: bookmarkedIds.contains(insight.id),
                                  onBookmarkToggle: () => _toggleBookmark(insight.id),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (_) => InsightDetailPage(
                                          id: insight.id,
                                          heading: insight.heading,
                                          content: insight.content,
                                          author: insight.author,
                                          date: insight.date,
                                          category: insight.category,
                                        ),
                                      ),
                                    );
                                    _loadBookmarks();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, bool isDark) {
    final isSelected = selectedTag == label;

    return GestureDetector(
      key: ValueKey('tag_$label'),
      onTap: () {
        setState(() => selectedTag = label);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    final shimmerBase =
        isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase;
    final shimmerHighlight =
        isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight;

    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: shimmerBase,
          highlightColor: shimmerHighlight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Title
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                // Content lines
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 240,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
