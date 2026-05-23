import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/new_post.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_card.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/hidden_posts_manager.dart';
import 'package:mindsarthi/core/widgets/premium_search_bar.dart';
import 'package:mindsarthi/core/widgets/animated_action_menu.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _selectedSegment = 0; // 0 for Public Feed, 1 for Anonymous Space
  String selectedFilter = 'Popular';
  String _searchQuery = '';
  Set<String> _hiddenPostIds = {};

  final ScrollController _contentScrollController = ScrollController();
  final ScrollController _chipScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isScrolled = false;
  bool _isProfileComplete = false;
  bool _isCheckingProfile = true;
  bool _isModerator = false;

  List<GlobalKey> chipKeys = [];

  final uid = FirebaseAuth.instance.currentUser?.uid;

  StreamSubscription? _followingSubscription;
  StreamSubscription? _savedPostsSubscription;
  Set<String> _followingUids = {};
  Set<String> _savedPostIds = {};

  List<String> get activeFilters {
    if (_selectedSegment == 0) {
      return ['Popular', 'My posts', 'Following', 'Saved', 'My comments'];
    } else {
      return ['Popular', 'All', 'My posts'];
    }
  }

  final Map<String, String> emptyMessages = {
    'Popular': 'Be the first one to share something amazing!',
    'My posts': 'Your thoughts matter. Start sharing!',
    'Following': 'Start following amazing people to see their posts!',
    'Saved': 'You haven\'t saved anything yet. Keep exploring!',
    'My comments': 'Comment on something you love!',
    'All': 'Be the first to share an anonymous thought!',
  };

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _loadHiddenPosts();
    _setupFollowingAndSavedListeners();
    _contentScrollController.addListener(() {
      if (_contentScrollController.hasClients) {
        setState(() {
          _isScrolled = _contentScrollController.offset > 0;
        });
      }
    });
  }

  void _setupFollowingAndSavedListeners() {
    final currentUid = uid;
    if (currentUid == null) return;

    _followingSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('following')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _followingUids = snapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    }, onError: (e) {
      debugPrint('Error listening to following: $e');
    });

    _savedPostsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('saved_posts')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _savedPostIds = snapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    }, onError: (e) {
      debugPrint('Error listening to saved posts: $e');
    });
  }

  Future<void> _loadHiddenPosts() async {
    final ids = await HiddenPostsManager.getHiddenPostIds();
    if (mounted) {
      setState(() {
        _hiddenPostIds = ids.toSet();
      });
    }
  }

  Future<void> _checkProfileStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (mounted && data != null) {
        final isComplete = data['username'] != null &&
            data['nickname'] != null &&
            data['age'] != null &&
            data['username'].toString().isNotEmpty &&
            data['nickname'].toString().isNotEmpty &&
            data['age'].toString().isNotEmpty;

        final isMod = data['isModerator'] == true || data['userRole'] == 'moderator';

        setState(() {
          _isProfileComplete = isComplete;
          _isModerator = isMod;
          _isCheckingProfile = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isCheckingProfile = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile status: $e');
      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _followingSubscription?.cancel();
    _savedPostsSubscription?.cancel();
    _chipScrollController.dispose();
    _contentScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNewPostPressed() {
    if (!_isProfileComplete) {
      AppToast.warning(
        context,
        'Complete your profile to post',
        description: 'Go to your profile and fill in all details first.',
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
    final filtersList = activeFilters;
    chipKeys = List.generate(filtersList.length, (_) => GlobalKey());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Text(
          'CONNECT',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: AnimatedActionMenu(
                expandLeft: true,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSegment = 0;
                        selectedFilter = 'Saved';
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToSelectedChip(3);
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.bookmark,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.bell,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(164),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Control (Public Feed vs. Anonymous Space)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedSegment,
                    backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                    thumbColor: isDark ? AppColors.darkPrimary : AppColors.white,
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Public Feed',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _selectedSegment == 0
                                ? (isDark ? AppColors.darkBackground : AppColors.primaryDark)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Anonymous Space',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _selectedSegment == 1
                                ? (isDark ? AppColors.darkBackground : AppColors.primaryDark)
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSegment = val;
                          selectedFilter = 'Popular';
                        });
                      }
                    },
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: PremiumSearchBar(
                  controller: _searchController,
                  hintText: 'Search topics...',
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                    });
                  },
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 50,
                child: ListView.separated(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtersList.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filtersList[index];
                    final isSelected = selectedFilter == filter;
                    return ChoiceChip(
                      key: chipKeys[index],
                      label: Text(filter),
                      selected: isSelected,
                      showCheckmark: false,
                      pressElevation: 0,
                      elevation: 0,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                        _scrollToSelectedChip(index);
                      },
                      selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected 
                            ? AppColors.white 
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.background,
                      side: BorderSide(
                        color: isSelected 
                            ? Colors.transparent 
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
      body: _isCheckingProfile
          ? const Center(child: CupertinoActivityIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerList();
                }

                final rawPosts = snapshot.data?.docs ?? [];
                final posts = rawPosts.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return true;

                  // 1. Filter out locally hidden posts
                  if (_hiddenPostIds.contains(doc.id)) return false;

                  // 2. Filter out posts with 5 or more reports
                  final reportsCount = data['reportsCount'] ?? 0;
                  if (reportsCount >= 5) return false;

                  // 3. Filter out posts reported by the current user
                  final reportedBy = data['reportedBy'];
                  if (reportedBy is List && reportedBy.contains(uid)) {
                    return false;
                  }

                  // 4. Filter by Segmented Control selection (isAnonymous)
                  final isAnon = data['isAnonymous'] == true;
                  if (_selectedSegment == 0) {
                    if (isAnon) return false;
                  } else {
                    if (!isAnon) return false;
                  }

                  // 5. Search filtering
                  if (_searchQuery.isNotEmpty) {
                    final content = (data['content'] ?? '').toString().toLowerCase();
                    if (!content.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (selectedFilter == 'Popular') {
                  posts.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>?;
                    final bData = b.data() as Map<String, dynamic>?;
                    final aLikes = aData?['likes'] ?? 0;
                    final bLikes = bData?['likes'] ?? 0;
                    final aComments = aData?['commentCount'] ?? 0;
                    final bComments = bData?['commentCount'] ?? 0;
                    return ((bLikes + bComments) - (aLikes + aComments));
                  });
                }

                if (selectedFilter == 'My posts') {
                  return _buildFilteredPostList(
                    posts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data?['uid'] == uid;
                    }).toList(),
                  );
                }

                if (selectedFilter == 'Following') {
                  final followingPosts = posts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final postUid = data?['uid'];
                    return _followingUids.contains(postUid);
                  }).toList();
                  return _buildFilteredPostList(followingPosts);
                }

                if (selectedFilter == 'Saved') {
                  final savedPosts = posts.where((doc) {
                    return _savedPostIds.contains(doc.id);
                  }).toList();
                  return _buildFilteredPostList(savedPosts);
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onNewPostPressed,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _isScrolled ? 16 : 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.pencil, color: Colors.white),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(
                        width: _isScrolled ? 0 : null,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            'New Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
            isModerator: _isModerator,
            onPostHidden: _loadHiddenPosts,
            expandComments: false, // Turn off expanded comments by default in main list
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
              CupertinoIcons.chat_bubble,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase =
        isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase;
    final shimmerHighlight =
        isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight;

    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: shimmerBase,
          highlightColor: shimmerHighlight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.border,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      final commentsSnap = await FirebaseFirestore.instance
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
