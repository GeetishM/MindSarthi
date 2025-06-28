import 'package:flutter/material.dart';
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
  List<Insight> bookmarkedInsights = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarkedInsights();
  }

  Future<void> _loadBookmarkedInsights() async {
    final ids = await BookmarkManager.getBookmarkedIds();
    setState(() {
      bookmarkedInsights =
          insightsList.where((insight) => ids.contains(insight.id)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarked Insights')),
      body: ListView.builder(
        itemCount: bookmarkedInsights.length,
        itemBuilder: (context, index) {
          final insight = bookmarkedInsights[index];
          return InsightCard(
            heading: insight.heading,
            content: insight.content,
            author: insight.author,
            date: insight.date,
            isBookmarked: true,
            onBookmarkToggle: () async {
              await BookmarkManager.toggleBookmark(insight.id);
              _loadBookmarkedInsights();
            },
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InsightDetailPage(
                  heading: insight.heading,
                  content: insight.content,
                  author: insight.author,
                  date: insight.date,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
