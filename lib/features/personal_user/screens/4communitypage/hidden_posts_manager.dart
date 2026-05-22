import 'package:shared_preferences/shared_preferences.dart';

class HiddenPostsManager {
  static const _key = 'hidden_posts';

  static Future<List<String>> getHiddenPostIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> hidePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getStringList(_key) ?? [];

    if (!hidden.contains(postId)) {
      hidden.add(postId);
      await prefs.setStringList(_key, hidden);
    }
  }

  static Future<bool> isPostHidden(String postId) async {
    final hidden = await getHiddenPostIds();
    return hidden.contains(postId);
  }

  static Future<void> unhidePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getStringList(_key) ?? [];

    if (hidden.contains(postId)) {
      hidden.remove(postId);
      await prefs.setStringList(_key, hidden);
    }
  }
}
