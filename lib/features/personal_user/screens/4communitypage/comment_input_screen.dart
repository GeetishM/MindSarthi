import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_repository.dart';

class CommentInputScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommentInputScreen({super.key, required this.postId});

  @override
  ConsumerState<CommentInputScreen> createState() => _CommentInputScreenState();
}

class _CommentInputScreenState extends ConsumerState<CommentInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final uid = ref.read(authStateProvider).value?.$id;
      if (uid != null) {
        final userDoc = await AppwriteService().databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: uid,
        );
        final username = userDoc.data['username'] ?? 'Anonymous';

        await ref.read(postRepositoryProvider).createComment(
          postId: widget.postId,
          uid: uid,
          username: username,
          text: _controller.text.trim(),
        );

        _controller.clear();
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
    } finally {
      setState(() {
        _isPosting = false;
      });
      if (mounted) {
        Navigator.pop(context); // Close comment input screen
      }
    }
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
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          autofocus: true,
        ),
      ),
    );
  }
}
