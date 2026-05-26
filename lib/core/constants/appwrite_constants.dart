class AppwriteConstants {
  static const String databaseId = String.fromEnvironment('APPWRITE_DATABASE_ID', defaultValue: 'mindsarthi_db');

  // Collections
  static const String usersCollectionId = 'users';
  static const String sessionsCollectionId = 'sessions';
  static const String moodsCollectionId = 'moods';
  static const String postsCollectionId = 'posts';
  static const String commentsCollectionId = 'comments';
  static const String journalsCollectionId = 'journals';
  static const String tasksCollectionId = 'tasks';
  static const String chatsCollectionId = 'chats';
  static const String messagesCollectionId = 'messages';
  static const String professionalProfilesCollectionId = 'professional_profiles';
  static const String certificatesCollectionId = 'certificates';
  static const String notificationsCollectionId = 'notifications';
  static const String communityNotificationsCollectionId = 'community_notifications';
  static const String wellnessProgramsCollectionId = 'wellness_programs';
  static const String surveysCollectionId = 'surveys';

  // Storage Buckets
  static const String mediaBucketId = 'media_uploads';
  static const String certificatesBucketId = 'certificates_bucket';
}
