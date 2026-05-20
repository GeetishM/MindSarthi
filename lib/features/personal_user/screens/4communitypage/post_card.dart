import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/comment_input_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/report_dialog.dart';
import 'comment_screen.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;
  final bool showCommentIcon;
  final bool isProfileComplete;
  final bool expandComments;
  final VoidCallback? onCommentTap;

  const PostCard({
    super.key,
    required this.post,
    this.showCommentIcon = true,
    required this.isProfileComplete,
    this.expandComments = false,
    this.onCommentTap,
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
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Unlike post?"),
              content: const Text("Are you sure you want to unlike this post?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
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

  /// Shows the post options bottom sheet (Report or Delete depending on ownership).
  void _showPostOptions(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final isOwner = data['uid'] == currentUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (isOwner) ...[
              // ── Delete option for post owner ────────────────────────
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
                title: Text(
                  'Delete Post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                subtitle: Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Post?'),
                      content: const Text(
                          'Are you sure you want to delete this post?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.white)),
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
              ),
            ] else ...[
              // ── Report option for other users ───────────────────────
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, color: AppColors.error),
                ),
                title: Text(
                  'Report Post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Flag inappropriate or harmful content.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showReportSheet(context, widget.post.id);
                },
              ),
            ],

            // ── Cancel ───────────────────────────────────────────────
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.close_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
              ),
              title: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.post.data() as Map<String, dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                onPressed: () => _showPostOptions(context, data, isDark),
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
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
                    Icons.chat_bubble_outline_rounded,
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
                Icons.ios_share_rounded,
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
                  return const Center(child: CircularProgressIndicator());
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
                                Icons.favorite_border_rounded, 
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
