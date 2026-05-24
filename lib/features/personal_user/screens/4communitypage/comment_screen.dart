import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_repository.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_card.dart';

class CommentScreen extends ConsumerStatefulWidget {
  final String postId;
  final PostModel post;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  ConsumerState<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends ConsumerState<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  String selectedTab = 'Top';
  bool _isProfileComplete = false;
  List<CommentModel> _allComments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await ref.read(postRepositoryProvider).getComments(widget.postId);
      if (mounted) {
        setState(() {
          _allComments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkProfileStatus() async {
    final result = await isProfileComplete();
    if (!mounted) return;
    setState(() {
      _isProfileComplete = result;
    });
  }

  Future<bool> isProfileComplete() async {
    final uid = ref.read(authStateProvider).value?.$id;
    if (uid == null) return false;

    try {
      final doc = await AppwriteService().databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: uid,
      );
      final data = doc.data;

      return data['username'] != null &&
          data['nickname'] != null &&
          data['age'] != null &&
          data['username'].toString().isNotEmpty &&
          data['nickname'].toString().isNotEmpty &&
          data['age'].toString().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> addComment() async {
    if (!_isProfileComplete) {
      AppToast.warning(
        context,
        "Complete your profile to comment",
        description: "Go to your profile and fill in all details first.",
      );
      return;
    }

    final uid = ref.read(authStateProvider).value?.$id;
    if (uid == null) return;

    try {
      final userDoc = await AppwriteService().databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: uid,
      );
      final username = userDoc.data['username'] ?? 'Anonymous';

      final text = _commentController.text.trim();
      if (text.isNotEmpty) {
        await ref.read(postRepositoryProvider).createComment(
          postId: widget.postId,
          uid: uid,
          username: username,
          text: text,
        );
        _commentController.clear();
        _fetchComments(); // Refresh list
        if (mounted) {
          AppToast.success(context, 'Comment added');
        }
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      await ref.read(postRepositoryProvider).likeComment(commentId);
      _fetchComments(); // Refresh list
    } catch (e) {
      debugPrint('Error liking comment: $e');
    }
  }

  void showReplyDialog(String commentId) {
    final TextEditingController replyController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:  0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Reply to comment",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: replyController,
                  maxLines: 3,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Write a reply...",
                    hintStyle: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_isProfileComplete) {
                    AppToast.warning(
                      context,
                      "Complete profile to reply",
                      description: "Please complete your profile details first.",
                    );
                    return;
                  }

                  final uid = ref.read(authStateProvider).value?.$id;
                  if (uid == null) return;

                  try {
                    final userDoc = await AppwriteService().databases.getDocument(
                      databaseId: AppwriteConstants.databaseId,
                      collectionId: AppwriteConstants.usersCollectionId,
                      documentId: uid,
                    );
                    final username = userDoc.data['username'] ?? 'Anonymous';

                    final text = replyController.text.trim();
                    if (text.isNotEmpty) {
                      await ref.read(postRepositoryProvider).createComment(
                        postId: widget.postId,
                        uid: uid,
                        username: username,
                        text: text,
                        parentCommentId: commentId,
                      );
                      _fetchComments(); // Refresh list
                      if (mounted) {
                        Navigator.pop(context);
                        AppToast.success(context, 'Reply posted');
                      }
                    }
                  } catch (e) {
                    debugPrint('Error adding reply: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Post Reply",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<CommentModel> getFilteredComments() {
    final uid = ref.read(authStateProvider).value?.$id;
    final topLevel = _allComments.where((c) => c.parentCommentId == null || c.parentCommentId!.isEmpty).toList();

    if (selectedTab == 'Top') {
      topLevel.sort((a, b) => b.likes.compareTo(a.likes));
    } else if (selectedTab == 'Newest') {
      topLevel.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      return topLevel.where((c) => c.uid == uid).toList();
    }
    return topLevel;
  }

  List<CommentModel> getReplies(String commentId) {
    return _allComments.where((c) => c.parentCommentId == commentId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    final displayedComments = getFilteredComments();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Comments",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PostCard(
                    post: widget.post, 
                    showCommentIcon: false, 
                    isProfileComplete: _isProfileComplete,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: ['Top', 'Newest', 'My'].map((tab) {
                        final selected = selectedTab == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(tab),
                            selected: selected,
                            showCheckmark: false,
                            pressElevation: 0,
                            elevation: 0,
                            onSelected: (_) => setState(() => selectedTab = tab),
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              color: selected 
                                  ? Colors.white 
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            ),
                            backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.border.withValues(alpha:  0.2),
                            side: BorderSide(
                              color: selected 
                                  ? Colors.transparent 
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                _isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    : displayedComments.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.chat_bubble_2,
                                      size: 48,
                                      color: isDark ? Colors.grey[700] : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No comments here yet.',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final comment = displayedComments[index];
                                final replies = getReplies(comment.id);

                                return _CommentTile(
                                  comment: comment,
                                  isDark: isDark,
                                  onLike: () => likeComment(comment.id),
                                  onReply: () => showReplyDialog(comment.id),
                                  repliesWidget: replies.isEmpty
                                      ? const SizedBox.shrink()
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: replies.map((reply) {
                                            return _ReplyTile(reply: reply, isDark: isDark);
                                          }).toList(),
                                        ),
                                );
                              },
                              childCount: displayedComments.length,
                            ),
                          ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(color: borderCol, width: 1.2),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderCol, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: textColor),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: addComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.paperplane_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final Widget? repliesWidget;
  final bool isDark;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    this.repliesWidget,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final username = comment.username.isNotEmpty ? comment.username : 'Anonymous';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              comment.text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.heart,
                      size: 18,
                      color: hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment.likes.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: onReply,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.reply,
                      size: 18,
                      color: hintColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (repliesWidget != null) repliesWidget!,
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final CommentModel reply;
  final bool isDark;

  const _ReplyTile({
    required this.reply,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final username = reply.username.isNotEmpty ? reply.username : 'Anonymous';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bubbleBg = isDark ? AppColors.darkSurface2 : AppColors.background;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(left: 24, top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isDark ? AppColors.darkPrimary.withValues(alpha:  0.2) : AppColors.primary.withValues(alpha:  0.1),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              reply.text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
