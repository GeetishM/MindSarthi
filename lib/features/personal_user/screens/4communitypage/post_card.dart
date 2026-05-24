import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import 'package:share_plus/share_plus.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';
import 'package:mindsarthi/core/widgets/app_dialog.dart';
import 'package:mindsarthi/core/widgets/app_action_sheet.dart';
import 'package:mindsarthi/core/widgets/animated_action_menu.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_repository.dart';
import 'comment_screen.dart';
import 'hidden_posts_manager.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
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
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  int likeCount = 0;
  String? currentUid;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool isFollowing = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    currentUid = ref.read(authStateProvider).value?.$id;
    likeCount = widget.post.likes;
    isLiked = widget.post.likedBy.contains(currentUid);

    // Heart animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_controller);

    _checkRelations();
  }

  Future<void> _checkRelations() async {
    if (currentUid == null) return;
    try {
      final databases = AppwriteService().databases;
      final userDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: currentUid!,
      );

      final following = List<String>.from(userDoc.data['following'] ?? []);
      final savedPosts = List<String>.from(userDoc.data['savedPosts'] ?? []);

      if (mounted) {
        setState(() {
          isFollowing = following.contains(widget.post.uid);
          isSaved = savedPosts.contains(widget.post.id);
        });
      }
    } catch (e) {
      debugPrint('Error loading user relations in PostCard: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> toggleLike() async {
    if (currentUid == null) return;

    if (!isLiked) {
      await _controller.forward();
      await _controller.reverse();

      setState(() {
        isLiked = true;
        likeCount += 1;
      });
    } else {
      final confirm = await MindSarthiDialog.show(
        context: context,
        title: "Unlike post?",
        content: "Are you sure you want to unlike this post?",
        confirmText: "Yes, Unlike",
        cancelText: "Cancel",
        isDestructive: true,
      );

      if (!(confirm ?? false)) return;

      setState(() {
        isLiked = false;
        likeCount -= 1;
      });
    }

    try {
      await ref.read(postRepositoryProvider).toggleLike(widget.post.id, currentUid!);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> toggleFollow() async {
    if (currentUid == null) return;

    final databases = AppwriteService().databases;
    try {
      final userDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: currentUid!,
      );

      final following = List<String>.from(userDoc.data['following'] ?? []);
      if (isFollowing) {
        following.remove(widget.post.uid);
      } else {
        following.add(widget.post.uid);
      }

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: currentUid!,
        data: {'following': following},
      );

      setState(() {
        isFollowing = !isFollowing;
      });

      if (mounted) {
        AppToast.success(context, isFollowing ? 'Followed user' : 'Unfollowed user');
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
  }

  Future<void> toggleSave() async {
    if (currentUid == null) return;

    final databases = AppwriteService().databases;
    try {
      final userDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: currentUid!,
      );

      final savedPosts = List<String>.from(userDoc.data['savedPosts'] ?? []);
      if (isSaved) {
        savedPosts.remove(widget.post.id);
      } else {
        savedPosts.add(widget.post.id);
      }

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: currentUid!,
        data: {'savedPosts': savedPosts},
      );

      setState(() {
        isSaved = !isSaved;
      });

      if (mounted) {
        AppToast.success(context, isSaved ? 'Saved post' : 'Removed from Saved');
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
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

  void _showPostOptions(BuildContext context) {
    final isOwner = widget.post.uid == currentUid;
    final actions = <ActionSheetItem>[];
    final databases = AppwriteService().databases;

    if (isOwner || widget.isModerator) {
      actions.add(ActionSheetItem(
        label: 'Delete Post',
        icon: CupertinoIcons.trash,
        isDestructive: true,
        onTap: () async {
          final confirm = await MindSarthiDialog.show(
            context: context,
            title: 'Delete Post?',
            content: 'Are you sure you want to delete this post? This action cannot be undone.',
            confirmText: 'Yes, Delete',
            cancelText: 'Cancel',
            isDestructive: true,
          );
          if (confirm == true) {
            await databases.deleteDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.postsCollectionId,
              documentId: widget.post.id,
            );
            if (mounted) {
              AppToast.success(context, 'Post deleted');
              if (widget.onPostHidden != null) {
                widget.onPostHidden!();
              }
            }
          }
        },
      ));
    }

    if (!widget.post.isAnonymous) {
      actions.add(ActionSheetItem(
        label: 'Hide Post',
        icon: CupertinoIcons.eye_slash,
        onTap: () async {
          await HiddenPostsManager.hidePost(widget.post.id);
          if (widget.onPostHidden != null) {
            widget.onPostHidden!();
          }
          if (context.mounted) {
            AppToast.success(context, 'Post hidden');
          }
        },
      ));
    }

    MindSarthiActionSheet.show(
      context: context,
      title: 'Post Options',
      subtitle: widget.post.isAnonymous ? 'Anonymous Friendly Space' : null,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwner = currentUid == widget.post.uid;

    return NeumorphicContainer(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.post.isAnonymous) ...[
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
                FutureBuilder<models.Document>(
                  future: AppwriteService().databases.getDocument(
                    databaseId: AppwriteConstants.databaseId,
                    collectionId: AppwriteConstants.usersCollectionId,
                    documentId: widget.post.uid,
                  ),
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

                    final userData = snapshot.data?.data;

                    if (userData == null || userData['name'] == null) {
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
                            'User',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      );
                    }

                    final name = userData['name'].toString();
                    final profileInitial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                          child: Text(
                            profileInitial,
                            style: TextStyle(
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (!isOwner) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: toggleFollow,
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing 
                                    ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                                    : (isDark ? AppColors.darkPrimary : AppColors.primary),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],

              const Spacer(),
              if (!widget.post.isAnonymous || isOwner)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _showPostOptions(context),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (widget.post.title.trim().isNotEmpty) ...[
            Text(
              widget.post.title.trim(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
          ],

          MarkdownBody(
            data: widget.post.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                height: 1.4,
              ),
              strong: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              em: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              listBullet: TextStyle(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
              h1: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              h2: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              h3: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              code: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: isDark ? AppColors.accent : AppColors.primaryDark,
                backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
              ),
              codeblockDecoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8),
              ),
              blockquote: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
          if (widget.post.mediaUrl != null && widget.post.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    widget.post.mediaUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                        child: Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                  if (widget.post.mediaType == 'video')
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          Row(
            children: [
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
                FutureBuilder<List<CommentModel>>(
                  future: ref.read(postRepositoryProvider).getComments(widget.post.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
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

              if (widget.post.isAnonymous) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final textToShare = 'Anonymous Post: "${widget.post.content}"\nShared via MindSarthi';
                    try {
                      await Share.share(textToShare);
                    } catch (e) {
                      await Clipboard.setData(ClipboardData(text: textToShare));
                      if (context.mounted) {
                        AppToast.success(context, 'Link copied to clipboard!');
                      }
                    }
                  },
                  child: Icon(
                    CupertinoIcons.share,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    size: 22,
                  ),
                ),
              ] else ...[
                const Spacer(),
                AnimatedActionMenu(
                  children: [
                    GestureDetector(
                      onTap: toggleSave,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                          color: isSaved 
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : (isDark ? AppColors.darkTextHint : AppColors.textHint),
                          size: 22,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final textToShare = 'Post: "${widget.post.content}"\nShared via MindSarthi';
                        try {
                          await Share.share(textToShare);
                        } catch (e) {
                          await Clipboard.setData(ClipboardData(text: textToShare));
                          if (context.mounted) {
                            AppToast.success(context, 'Link copied to clipboard!');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          CupertinoIcons.share,
                          color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
