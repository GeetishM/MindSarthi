import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/Bookmarked_screen.dart';
import 'package:shimmer/shimmer.dart';
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

  static const _tags = ['ALL', 'For You', 'Adult ADHD', 'Insomnia', 'Panic Attacks'];

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

  List<Insight> _applyFilter(List<Insight> insights) {
    if (selectedTag == 'ALL') return insights;
    if (selectedTag == 'For You') return insights; // personalisation hook
    return insights
        .where((i) =>
            i.category.toLowerCase() == selectedTag.toLowerCase() ||
            i.heading.toLowerCase().contains(selectedTag.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
          // ── Tag filter chips ───────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _tags.map((tag) => _tagChip(tag, isDark)).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Firestore stream ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('insights')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading shimmer
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerList(isDark);
                }

                // Build list from Firestore or fallback to static list
                List<Insight> insights;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  insights = snapshot.data!.docs
                      .map((doc) => Insight.fromFirestore(doc))
                      .toList();
                } else {
                  // Firestore collection empty → use static fallback
                  insights = insightsList;
                }

                final filtered = _applyFilter(insights);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_off_rounded,
                          size: 56,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No insights for this topic yet.',
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
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final insight = filtered[index];
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
