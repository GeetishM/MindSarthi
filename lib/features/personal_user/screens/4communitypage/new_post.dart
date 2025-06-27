import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _postController = TextEditingController();
  bool _isPosting = false;

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final content = _postController.text.trim();

    if (user == null || content.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [], // <-- required for tracking user likes
      });

      Navigator.pop(context); // Return to CommunityPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e')),
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPosting ? null : _submitPost,
              child: _isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
