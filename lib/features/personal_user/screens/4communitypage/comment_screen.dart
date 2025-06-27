import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_card.dart';
import 'package:toastification/toastification.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final DocumentSnapshot post;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  String selectedTab = 'Top';
  bool _isProfileComplete = false;
  bool _isCheckingProfile = true;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    final result = await isProfileComplete();
    setState(() {
      _isProfileComplete = result;
      _isCheckingProfile = false;
    });
  }

  Future<bool> isProfileComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    return data != null &&
        data['username'] != null &&
        data['nickname'] != null &&
        data['age'] != null &&
        data['username'].toString().isNotEmpty &&
        data['nickname'].toString().isNotEmpty &&
        data['age'].toString().isNotEmpty;
  }

  Future<void> addComment() async {
    if (!_isProfileComplete) {
      toastification.show(
        context: context,
        title: const Text("Complete your profile to comment"),
        type: ToastificationType.warning,
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final username = userDoc['username'] ?? 'Anonymous';

    if (_commentController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'uid': uid,
        'username': username,
        'text': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
      });
      _commentController.clear();
    }
  }

  Future<void> likeComment(String commentId) async {
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final currentLikes = snapshot['likes'] ?? 0;
      transaction.update(ref, {'likes': currentLikes + 1});
    });
  }

  void showReplyDialog(String commentId) {
    final TextEditingController replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Reply to comment"),
            TextField(controller: replyController),
            ElevatedButton(
              onPressed: () async {
                if (!_isProfileComplete) {
                  toastification.show(
                    context: context,
                    title: const Text("Complete your profile to reply"),
                    type: ToastificationType.warning,
                  );
                  return;
                }

                final uid = FirebaseAuth.instance.currentUser?.uid;
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();
                final username = userDoc['username'] ?? 'Anonymous';

                if (replyController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .collection('replies')
                      .add({
                    'uid': uid,
                    'username': username,
                    'text': replyController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Reply"),
            )
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> getCommentStream() {
    final base = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments');

    if (selectedTab == 'Top') {
      return base.orderBy('likes', descending: true).snapshots();
    } else if (selectedTab == 'Newest') {
      return base.orderBy('timestamp', descending: true).snapshots();
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      return base.where('uid', isEqualTo: uid).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          PostCard(post: widget.post, showCommentIcon: false, isProfileComplete: _isProfileComplete),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: ['Top', 'Newest', 'My'].map((tab) {
                final selected = selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: selected,
                    selectedColor: Colors.pinkAccent,
                    onSelected: (_) => setState(() => selectedTab = tab),
                  ),
                );
              }).toList(),
            ),
          ),

          // Comment List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getCommentStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['username'] ?? 'Anonymous'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['text'] ?? ''),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => likeComment(doc.id),
                                child: const Icon(Icons.favorite_border),
                              ),
                              const SizedBox(width: 4),
                              Text((data['likes'] ?? 0).toString()),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => showReplyDialog(doc.id),
                                child: const Icon(Icons.reply_outlined),
                              ),
                            ],
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.postId)
                                .collection('comments')
                                .doc(doc.id)
                                .collection('replies')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, replySnap) {
                              if (!replySnap.hasData ||
                                  replySnap.data!.docs.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: replySnap.data!.docs.map((replyDoc) {
                                    final reply =
                                        replyDoc.data() as Map<String, dynamic>;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
                                      child: ListTile(
                                        title: Text(reply['username'] ??
                                            'Anonymous'),
                                        subtitle:
                                            Text(reply['text'] ?? ''),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Comment Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration:
                        const InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: addComment,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
