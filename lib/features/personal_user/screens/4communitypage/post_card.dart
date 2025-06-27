import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/comment_input_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final data = widget.post.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Username + Options
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(data['uid'])
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Show shimmer while loading
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 80,
                            height: 14,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      );
                    }

                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;

                    if (userData == null || userData['username'] == null) {
                      return const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Unknown',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    }

                    final profileInitial = userData['profileInitial'] ?? '';
                    final username = userData['username'];

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.pinkAccent,
                          child: Text(
                            profileInitial.isNotEmpty
                                ? profileInitial
                                : username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),

            const SizedBox(height: 10),

            // Post Content
            Text(data['content'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            // Bottom Actions
            Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: toggleLike,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(formatCount(likeCount)),

                // Comment icon and count
                if (widget.showCommentIcon) ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onCommentTap ?? openComments,
                    child: const Icon(
                      Icons.comment_outlined,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('posts')
                            .doc(widget.post.id)
                            .collection('comments')
                            .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(formatCount(count));
                    },
                  ),
                ],

                const Spacer(),
                const Icon(Icons.send, color: Colors.black),
              ],
            ),

            // Inline Comments (Quora style)
            if (widget.expandComments) ...[
              const SizedBox(height: 12),
              // Add a comment prompt
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CommentInputScreen(postId: widget.post.id),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    "Add a comment...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
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
                    return const Text(
                      'No comments yet.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  return Column(
                    children:
                        snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(data['username'] ?? 'Anonymous'),
                            subtitle: Text(data['text'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite_border, size: 18),
                                const SizedBox(width: 4),
                                Text((data['likes'] ?? 0).toString()),
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
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'View all comments',
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
