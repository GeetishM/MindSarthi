// comment_input_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentInputScreen extends StatefulWidget {
  final String postId;

  const CommentInputScreen({super.key, required this.postId});

  @override
  State<CommentInputScreen> createState() => _CommentInputScreenState();
}

class _CommentInputScreenState extends State<CommentInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final username = userDoc['username'] ?? 'Anonymous';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'uid': uid,
      'username': username,
      'text': _controller.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    });

    _controller.clear();
    setState(() {
      _isPosting = false;
    });

    Navigator.pop(context); // Close comment input screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add a comment...'),
        actions: [
          TextButton(
            onPressed: _postComment,
            child: const Text('Post', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Add a comment...',
            border: InputBorder.none,
          ),
          autofocus: true,
        ),
      ),
    );
  }
}
