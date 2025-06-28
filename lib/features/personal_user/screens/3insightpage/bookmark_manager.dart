import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'insight_data.dart';

class BookmarkManager {
  static const _key = 'bookmarked_insights';

  static Future<List<String>> getBookmarkedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> toggleBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_key) ?? [];

    if (bookmarks.contains(id)) {
      bookmarks.remove(id);
    } else {
      bookmarks.add(id);
    }
    await prefs.setStringList(_key, bookmarks);
  }

  static Future<bool> isBookmarked(String id) async {
    final bookmarks = await getBookmarkedIds();
    return bookmarks.contains(id);
  }
}
