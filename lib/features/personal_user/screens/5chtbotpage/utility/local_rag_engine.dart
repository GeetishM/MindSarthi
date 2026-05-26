import 'package:hive/hive.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/knowledge_article.dart';

class LocalRagEngine {
  static String? retrieveContext(String userQuery) {
    try {
      final cleanQuery = userQuery.toLowerCase().trim();
      if (!Hive.isBoxOpen('knowledgeBase')) {
        return null;
      }
      
      final box = Hive.box<KnowledgeArticle>('knowledgeBase');
      KnowledgeArticle? matchedArticle;
      int maxMatchCount = 0;

      for (var article in box.values) {
        int matches = 0;
        for (var keyword in article.keywords) {
          if (cleanQuery.contains(keyword.toLowerCase())) {
            matches++;
          }
        }
        if (matches > maxMatchCount) {
          maxMatchCount = matches;
          matchedArticle = article;
        }
      }

      if (matchedArticle != null && maxMatchCount > 0) {
        return 'LOCAL COPING GUIDANCE (Category: ${matchedArticle.category}): '
               '${matchedArticle.content} '
               'Suggested App Feature/Action (suggest this subtly as an companion recommendation): ${matchedArticle.appSuggestion}';
      }
    } catch (e) {
      // Fail silently and let the base prompt handle it
    }
    return null;
  }
}
