import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/new_post.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_card.dart';
import 'package:toastification/toastification.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final List<String> filters = [
    'Popular',
    'My posts',
    'Following',
    'Saved',
    'My comments',
  ];

  String? expandedPostId;
  String selectedFilter = 'Popular';
  final ScrollController _contentScrollController = ScrollController();
  final ScrollController _chipScrollController = ScrollController();
  bool _isScrolled = false;
  bool _isProfileComplete = false;
  bool _isCheckingProfile = true;

  List<GlobalKey> chipKeys = [];

  final uid = FirebaseAuth.instance.currentUser?.uid;

  final Map<String, String> emptyMessages = {
    'Popular': 'Be the first one to share something amazing!',
    'My posts': 'Your thoughts matter. Start sharing!',
    'Following': 'Start following amazing people to see their posts!',
    'Saved': 'You haven\'t saved anything yet. Keep exploring!',
    'My comments': 'Comment on something you love!',
  };

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _contentScrollController.addListener(() {
      setState(() {
        _isScrolled = _contentScrollController.offset > 0;
      });
    });
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

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    return data != null &&
        data['username'] != null &&
        data['nickname'] != null &&
        data['age'] != null &&
        data['username'].toString().isNotEmpty &&
        data['nickname'].toString().isNotEmpty &&
        data['age'].toString().isNotEmpty;
  }

  @override
  void dispose() {
    _chipScrollController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _onNewPostPressed() {
    if (!_isProfileComplete) {
      toastification.show(
        context: context,
        title: const Text("Complete your profile to create posts"),
        type: ToastificationType.warning,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewPostScreen()),
    );
  }

  void _scrollToSelectedChip(int index) {
    if (index >= chipKeys.length) return;
    final keyContext = chipKeys[index].currentContext;
    if (keyContext == null) return;

    final box = keyContext.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position = box.localToGlobal(
      Offset.zero,
      ancestor: context.findRenderObject(),
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final chipCenter = position.dx + box.size.width / 2;
    final scrollOffset =
        _chipScrollController.offset + chipCenter - screenWidth / 2;

    _chipScrollController.animateTo(
      scrollOffset.clamp(
        _chipScrollController.position.minScrollExtent,
        _chipScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    chipKeys = List.generate(filters.length, (_) => GlobalKey());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _SearchWidget(),
              ),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = selectedFilter == filter;
                    return ChoiceChip(
                      key: chipKeys[index],
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                        _scrollToSelectedChip(index);
                      },
                      selectedColor: Colors.pinkAccent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body:
          _isCheckingProfile
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerList();
                  }

                  final posts = snapshot.data?.docs ?? [];

                  if (selectedFilter == 'Popular') {
                    posts.sort((a, b) {
                      final aLikes = a['likes'] ?? 0;
                      final bLikes = b['likes'] ?? 0;
                      final aComments = a['commentCount'] ?? 0;
                      final bComments = b['commentCount'] ?? 0;
                      return ((bLikes + bComments) - (aLikes + aComments));
                    });
                  }

                  if (selectedFilter == 'My posts') {
                    return _buildFilteredPostList(
                      posts.where((doc) => doc['uid'] == uid).toList(),
                    );
                  }

                  if (selectedFilter == 'Following') {
                    return _buildEmptyMessage(
                      "You're not following anyone yet.",
                    );
                  }

                  if (selectedFilter == 'Saved') {
                    return _buildEmptyMessage(
                      "You haven't saved any posts yet.",
                    );
                  }

                  if (selectedFilter == 'My comments') {
                    return FutureBuilder<List<DocumentSnapshot>>(
                      future: _fetchCommentedPosts(posts),
                      builder: (context, snap) {
                        if (!snap.hasData) return _buildShimmerList();
                        if (snap.data!.isEmpty) {
                          return _buildEmptyMessage(
                            "You haven't commented on any posts yet.",
                          );
                        }
                        return _buildFilteredPostList(snap.data!);
                      },
                    );
                  }

                  return _buildFilteredPostList(posts);
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onNewPostPressed,
        label: _isScrolled ? const SizedBox() : const Text("New Post"),
        icon: const Icon(Icons.create_rounded),
        isExtended: !_isScrolled,
      ),
    );
  }

  Widget _buildFilteredPostList(List<DocumentSnapshot> posts) {
    if (posts.isEmpty) {
      return _buildEmptyMessage(
        emptyMessages[selectedFilter] ?? 'No posts yet.',
      );
    }
    return ListView.builder(
      controller: _contentScrollController,
      itemCount: posts.length,
      itemBuilder:
          (_, index) => PostCard(
            post: posts[index],
            showCommentIcon: true,
            isProfileComplete: _isProfileComplete,
            expandComments: expandedPostId == posts[index].id,
            onCommentTap: () {
              setState(() {
                expandedPostId =
                    expandedPostId == posts[index].id ? null : posts[index].id;
              });
            },
          ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(height: 120),
          ),
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchCommentedPosts(
    List<DocumentSnapshot> allPosts,
  ) async {
    List<DocumentSnapshot> result = [];
    for (final post in allPosts) {
      final commentsSnap =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(post.id)
              .collection('comments')
              .where('uid', isEqualTo: uid)
              .limit(1)
              .get();
      if (commentsSnap.docs.isNotEmpty) result.add(post);
    }
    return result;
  }
}

class _SearchWidget extends StatefulWidget {
  const _SearchWidget();

  @override
  State<_SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<_SearchWidget> {
  final List<String> _suggestions = [
    'Flutter',
    'Firebase',
    'Dart',
    'ChatGPT',
    'Supabase',
    'GetX',
    'Riverpod',
  ];
  String selected = '';

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
      suggestionsBuilder: (context, controller) {
        final query = controller.text.toLowerCase();
        final filtered =
            _suggestions
                .where((item) => item.toLowerCase().contains(query))
                .toList();

        return filtered.map((suggestion) {
          return ListTile(
            title: Text(suggestion),
            onTap: () {
              setState(() {
                selected = suggestion;
              });
              controller.closeView(suggestion);
            },
          );
        });
      },
      barHintText: 'Search topics...',
      barLeading: const Icon(Icons.search),
      barTrailing: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              selected = '';
            });
          },
        ),
      ],
    );
  }
}
