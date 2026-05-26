class AppwriteConstants {
  static const String databaseId = String.fromEnvironment('APPWRITE_DATABASE_ID', defaultValue: 'mindsarthi_db');

  // Collections
  static const String usersCollectionId = 'users';
  static const String sessionsCollectionId = 'sessions';
  static const String moodsCollectionId = 'moods';
  static const String postsCollectionId = 'posts';
  static const String commentsCollectionId = 'comments';

  // Storage Buckets
  static const String mediaBucketId = 'media_uploads';
}
