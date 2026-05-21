import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/comment_input_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/report_dialog.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/hidden_posts_manager.dart';
import 'comment_screen.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;
  final bool showCommentIcon;
  final bool isProfileComplete;
  final bool expandComments;
  final bool isModerator;
  final VoidCallback? onCommentTap;
  final VoidCallback? onPostHidden;

  const PostCard({
    super.key,
    required this.post,
    this.showCommentIcon = true,
    required this.isProfileComplete,
    this.expandComments = false,
    this.isModerator = false,
    this.onCommentTap,
    this.onPostHidden,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  int likeCount = 0;
  String? currentUid;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser?.uid;

    final data = widget.post.data() as Map<String, dynamic>;
    likeCount = data['likes'] ?? 0;
    final List<dynamic> likedBy = data['likedBy'] ?? [];
    isLiked = likedBy.contains(currentUid);

    // Heart animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> toggleLike() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id);

    if (!isLiked) {
      // Animate and like
      await _controller.forward();
      await _controller.reverse();

      setState(() {
        isLiked = true;
        likeCount += 1;
      });

      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUid]),
      });
    } else {
      final confirm = await showCupertinoDialog<bool>(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text("Unlike post?"),
              content: const Text("Are you sure you want to unlike this post?"),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Unlike"),
                ),
              ],
            ),
      );

      if (confirm ?? false) {
        setState(() {
          isLiked = false;
          likeCount -= 1;
        });

        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUid]),
        });
      }
    }
  }

  String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  void openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CommentScreen(postId: widget.post.id, post: widget.post),
      ),
    );
  }

  /// Shows the Cupertino Action Sheet for post options (Report, Hide, Delete).
  void _showPostOptions(BuildContext context, Map<String, dynamic> data) {
    final isOwner = data['uid'] == currentUid;
    final isAnonymous = data['isAnonymous'] == true;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Post Options'),
        message: isAnonymous ? const Text('Anonymous Friendly Space') : null,
        actions: <CupertinoActionSheetAction>[
          // Owner delete option
          if (isOwner)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Delete Post?'),
                    content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.post.id)
                      .delete();
                  if (context.mounted) {
                    AppToast.success(context, 'Post deleted');
                  }
                }
              },
              child: const Text('Delete Post'),
            ),

          // Moderator delete option
          if (!isOwner && widget.isModerator)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Delete Post (Moderator)?'),
                    content: const Text('Are you sure you want to delete this post as a moderator? This action cannot be undone.'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.post.id)
                      .delete();
                  if (context.mounted) {
                    AppToast.success(context, 'Post deleted by moderator');
                  }
                }
              },
              child: const Text('Delete Post (Moderator)'),
            ),

          // Hide post option (only for public posts)
          if (!isAnonymous)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await HiddenPostsManager.hidePost(widget.post.id);
                if (context.mounted) {
                  AppToast.success(context, 'Post hidden');
                  if (widget.onPostHidden != null) {
                    widget.onPostHidden!();
                  }
                }
              },
              child: const Text('Hide Post'),
            ),

          // Report post option (only for public posts, and not owner)
          if (!isAnonymous && !isOwner)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                showReportSheet(context, widget.post.id);
              },
              child: const Text('Report Post'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.post.data() as Map<String, dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAnonymous = data['isAnonymous'] == true;
    final isOwner = data['uid'] == currentUid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Username + Options
          Row(
            children: [
              if (isAnonymous) ...[
                // Anonymous Avatar & User Details
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.background,
                  child: Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Anonymous Mind',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ] else ...[
                // Standard Public User
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['uid'])
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.border,
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 80,
                            height: 14,
                            color: isDark ? AppColors.darkSurface2 : AppColors.border,
                          ),
                        ],
                      );
                    }

                    final userData = snapshot.data?.data() as Map<String, dynamic>?;

                    if (userData == null || userData['username'] == null) {
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      );
                    }

                    final profileInitial = userData['profileInitial'] ?? '';
                    final username = userData['username'];

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                          child: Text(
                            profileInitial.isNotEmpty
                                ? profileInitial
                                : username[0].toUpperCase(),
                            style: TextStyle(
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],

              const Spacer(),
              // Show options button only for:
              // 1. Non-anonymous posts (which use the moderation system)
              // 2. Owner of anonymous posts (to let them delete it)
              // 3. Moderators (to moderate public posts, note: anonymous posts are unmoderated)
              if (!isAnonymous || isOwner)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _showPostOptions(context, data),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Post Content
          Text(
            data['content'] ?? '',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Actions
          Row(
            children: [
              // Like button
              GestureDetector(
                onTap: toggleLike,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Icon(
                    isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: isLiked ? AppColors.accent : (isDark ? AppColors.darkTextHint : AppColors.textHint),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatCount(likeCount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),

              // Comment icon and count
              if (widget.showCommentIcon) ...[
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: widget.onCommentTap ?? openComments,
                  child: Icon(
                    CupertinoIcons.bubble_left,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.post.id)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      formatCount(count),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],

              const Spacer(),
              Icon(
                CupertinoIcons.share,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                size: 22,
              ),
            ],
          ),

          // Inline Comments (Quora style)
          if (widget.expandComments) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Add a comment prompt
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommentInputScreen(postId: widget.post.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Add a comment...",
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.post.id)
                  .collection('comments')
                  .orderBy('likes', descending: true)
                  .limit(2)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No comments yet.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['username'] ?? 'Anonymous') + '  ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.heart, 
                                size: 14,
                                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (data['likes'] ?? 0).toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // View all comments link
            GestureDetector(
              onTap: widget.onCommentTap ?? openComments,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'View all comments',
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
