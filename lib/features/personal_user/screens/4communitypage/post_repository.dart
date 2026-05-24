import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class PostModel {
  final String id;
  final String uid;
  final String title;
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;
  final bool isAnonymous;
  final int reportsCount;
  final List<String> reportedBy;
  final String? mediaUrl;
  final String? mediaType;

  PostModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.likedBy,
    required this.isAnonymous,
    required this.reportsCount,
    required this.reportedBy,
    this.mediaUrl,
    this.mediaType,
  });

  factory PostModel.fromDocument(models.Document doc) {
    return PostModel(
      id: doc.$id,
      uid: doc.data['uid'] ?? '',
      title: doc.data['title'] ?? '',
      content: doc.data['content'] ?? '',
      timestamp: doc.data['timestamp'] != null
          ? DateTime.parse(doc.data['timestamp'])
          : DateTime.now(),
      likes: doc.data['likes'] ?? 0,
      likedBy: List<String>.from(doc.data['likedBy'] ?? []),
      isAnonymous: doc.data['isAnonymous'] ?? false,
      reportsCount: doc.data['reportsCount'] ?? 0,
      reportedBy: List<String>.from(doc.data['reportedBy'] ?? []),
      mediaUrl: doc.data['mediaUrl'],
      mediaType: doc.data['mediaType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'likedBy': likedBy,
      'isAnonymous': isAnonymous,
      'reportsCount': reportsCount,
      'reportedBy': reportedBy,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String uid;
  final String username;
  final String text;
  final DateTime timestamp;
  final int likes;
  final String? parentCommentId; // null for top-level comments

  CommentModel({
    required this.id,
    required this.postId,
    required this.uid,
    required this.username,
    required this.text,
    required this.timestamp,
    required this.likes,
    this.parentCommentId,
  });

  factory CommentModel.fromDocument(models.Document doc) {
    return CommentModel(
      id: doc.$id,
      postId: doc.data['postId'] ?? '',
      uid: doc.data['uid'] ?? '',
      username: doc.data['username'] ?? '',
      text: doc.data['text'] ?? '',
      timestamp: doc.data['timestamp'] != null
          ? DateTime.parse(doc.data['timestamp'])
          : DateTime.now(),
      likes: doc.data['likes'] ?? 0,
      parentCommentId: doc.data['parentCommentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'uid': uid,
      'username': username,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'parentCommentId': parentCommentId,
    };
  }
}

// ── Repository ──────────────────────────────────────────────────────────────

class PostRepository {
  final Databases _databases;
  final Storage _storage;

  PostRepository(this._databases, this._storage);

  /// Fetches all posts ordered by timestamp descending.
  Future<List<PostModel>> getPosts() async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postsCollectionId,
      queries: [
        Query.orderDesc('timestamp'),
      ],
    );
    return response.documents.map((doc) => PostModel.fromDocument(doc)).toList();
  }

  /// Creates a new post and uploads media if present.
  Future<PostModel> createPost({
    required String uid,
    required String title,
    required String content,
    required bool isAnonymous,
    File? mediaFile,
    String? mediaType,
  }) async {
    String? mediaUrl;

    if (mediaFile != null) {
      final appwrite = AppwriteService();
      final file = await _storage.createFile(
        bucketId: AppwriteConstants.mediaBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: mediaFile.path,
          filename: mediaFile.path.split('/').last,
        ),
      );
      // Generate Appwrite View URL
      mediaUrl = 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.mediaBucketId}/files/${file.$id}/view?project=${appwrite.client.config['project']}';
    }

    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postsCollectionId,
      documentId: ID.unique(),
      data: {
        'uid': uid,
        'title': title,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'likes': 0,
        'likedBy': [],
        'isAnonymous': isAnonymous,
        'reportsCount': 0,
        'reportedBy': [],
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
      },
    );

    return PostModel.fromDocument(doc);
  }

  /// Likes or unlikes a post.
  Future<void> toggleLike(String postId, String userId) async {
    final doc = await _databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postsCollectionId,
      documentId: postId,
    );

    final likedBy = List<String>.from(doc.data['likedBy'] ?? []);
    int likes = doc.data['likes'] ?? 0;

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
      likes = (likes - 1).clamp(0, 999999);
    } else {
      likedBy.add(userId);
      likes++;
    }

    await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postsCollectionId,
      documentId: postId,
      data: {
        'likes': likes,
        'likedBy': likedBy,
      },
    );
  }

  /// Reports a post by incrementing reportsCount and adding userId to reportedBy.
  Future<void> reportPost(String postId, String userId) async {
    final doc = await _databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postsCollectionId,
      documentId: postId,
    );

    final reportedBy = List<String>.from(doc.data['reportedBy'] ?? []);
    int reportsCount = doc.data['reportsCount'] ?? 0;

    if (!reportedBy.contains(userId)) {
      reportedBy.add(userId);
      reportsCount++;
    }

    await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.postsCollectionId,
      documentId: postId,
      data: {
        'reportsCount': reportsCount,
        'reportedBy': reportedBy,
      },
    );
  }

  /// Fetches comments for a specific post.
  Future<List<CommentModel>> getComments(String postId) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.commentsCollectionId,
      queries: [
        Query.equal('postId', postId),
        Query.orderDesc('timestamp'),
      ],
    );
    return response.documents.map((doc) => CommentModel.fromDocument(doc)).toList();
  }

  /// Creates a comment or reply under a post.
  Future<CommentModel> createComment({
    required String postId,
    required String uid,
    required String username,
    required String text,
    String? parentCommentId,
  }) async {
    final doc = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.commentsCollectionId,
      documentId: ID.unique(),
      data: {
        'postId': postId,
        'uid': uid,
        'username': username,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'likes': 0,
        'parentCommentId': parentCommentId,
      },
    );
    return CommentModel.fromDocument(doc);
  }

  /// Likes a specific comment.
  Future<void> likeComment(String commentId) async {
    final doc = await _databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.commentsCollectionId,
      documentId: commentId,
    );

    int likes = doc.data['likes'] ?? 0;
    likes++;

    await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.commentsCollectionId,
      documentId: commentId,
      data: {
        'likes': likes,
      },
    );
  }
}

// ── Riverpod Providers ──────────────────────────────────────────────────────

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final appwrite = AppwriteService();
  return PostRepository(appwrite.databases, appwrite.storage);
});

class PostStateNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final PostRepository _repository;
  late final Realtime _realtime;
  RealtimeSubscription? _subscription;

  PostStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPosts();
    _subscribeToRealtime();
  }

  Future<void> loadPosts() async {
    try {
      final posts = await _repository.getPosts();
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _subscribeToRealtime() {
    _realtime = Realtime(AppwriteService().client);
    _subscription = _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.postsCollectionId}.documents'
    ]);

    _subscription!.stream.listen((event) {
      final currentPosts = state.value ?? [];

      final isCreate = event.events.any((e) => e.contains('.create'));
      final isUpdate = event.events.any((e) => e.contains('.update'));
      final isDelete = event.events.any((e) => e.contains('.delete'));

      if (isCreate) {
        final doc = models.Document.fromMap(event.payload);
        final newPost = PostModel.fromDocument(doc);
        if (!currentPosts.any((p) => p.id == newPost.id)) {
          state = AsyncValue.data([newPost, ...currentPosts]);
        }
      } else if (isUpdate) {
        final doc = models.Document.fromMap(event.payload);
        final updatedPost = PostModel.fromDocument(doc);
        state = AsyncValue.data(currentPosts.map((post) {
          return post.id == updatedPost.id ? updatedPost : post;
        }).toList());
      } else if (isDelete) {
        final doc = models.Document.fromMap(event.payload);
        state = AsyncValue.data(currentPosts.where((post) => post.id != doc.$id).toList());
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

final postsProvider = StateNotifierProvider<PostStateNotifier, AsyncValue<List<PostModel>>>((ref) {
  final repo = ref.watch(postRepositoryProvider);
  return PostStateNotifier(repo);
});
