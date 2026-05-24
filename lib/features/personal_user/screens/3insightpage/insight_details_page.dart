import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'bookmark_manager.dart';

class InsightDetailPage extends StatefulWidget {
  final String id;
  final String heading;
  final String content;
  final String author;
  final String date;
  final String category;

  const InsightDetailPage({
    super.key,
    required this.id,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
    this.category = '',
  });

  @override
  State<InsightDetailPage> createState() => _InsightDetailPageState();
}

class _InsightDetailPageState extends State<InsightDetailPage> {
  bool _hasRated = false;
  int _userRating = 0;
  bool _isBookmarked = false;
  bool _isShareClicked = false;

  @override
  void initState() {
    super.initState();
    _checkIfRated();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    final status = await BookmarkManager.isBookmarked(widget.id);
    if (mounted) {
      setState(() {
        _isBookmarked = status;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    await BookmarkManager.toggleBookmark(widget.id);
    _loadBookmarkStatus();
  }

  Future<void> _checkIfRated() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasRated = prefs.getBool('rated_${widget.id}') ?? false;
      _userRating = prefs.getInt('rating_val_${widget.id}') ?? 0;
    });
  }

  Future<void> _submitRating(int rating) async {
    if (_hasRated) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rated_${widget.id}', true);
    await prefs.setInt('rating_val_${widget.id}', rating);
    setState(() {
      _hasRated = true;
      _userRating = rating;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for rating this article!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(widget.author);

    // Calculate dynamic reading time based on content length
    final wordCount = widget.content.split(RegExp(r'\s+')).length;
    final readTime = (wordCount / 180).ceil().clamp(1, 15);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Cupertino SliverAppBar
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: Icon(
                CupertinoIcons.back,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            actions: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleBookmark,
                child: Icon(
                  _isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                  color: _isBookmarked
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  setState(() {
                    _isShareClicked = true;
                  });
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (mounted) {
                      setState(() {
                        _isShareClicked = false;
                      });
                    }
                  });

                  final shareText = 'Read this insightful article: "${widget.heading}" by ${widget.author} on MindSarthi!';
                  try {
                    await Share.share(shareText);
                  } catch (e) {
                    await Clipboard.setData(ClipboardData(text: shareText));
                    if (context.mounted) {
                      AppToast.success(
                        context,
                        'Link copied to clipboard!',
                        description: 'Sharing fallback: Copied description to clipboard.',
                      );
                    }
                  }
                },
                child: Icon(
                  CupertinoIcons.share,
                  color: _isShareClicked
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Article Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge & Reading Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.category.isNotEmpty ? widget.category.toUpperCase() : 'INSIGHT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  $readTime min read',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Heading/Title
                  Text(
                    widget.heading,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Author Header (Initials Avatar + Info)
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [AppColors.darkPrimary, AppColors.darkPrimary.withValues(alpha: 0.7)] 
                                : [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.author,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Divider
                  Divider(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    thickness: 1.2,
                  ),
                  const SizedBox(height: 24),
                  
                  // Article Content Body
                  Text(
                    widget.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      height: 1.65,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Interactive Ratings Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : Colors.grey[200]!,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'How helpful was this article?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Current Average Rating display (mocked offline value or user's rating)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(5, (index) {
                              final starValue = index + 1;
                              const avgRating = 4.8;
                              if (starValue <= avgRating.floor()) {
                                return const Icon(Icons.star_rounded, color: Colors.amber, size: 22);
                              } else if (starValue - 0.5 <= avgRating) {
                                return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 22);
                              } else {
                                return const Icon(Icons.star_border_rounded, color: Colors.amber, size: 22);
                              }
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '4.8 (12 reviews)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: isDark ? AppColors.darkBorder : Colors.grey[200]!,
                          thickness: 1,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hasRated ? 'Your Rating' : 'Tap a star to rate',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Interactive Star Rating row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starVal = index + 1;
                            final isActive = _hasRated ? (_userRating >= starVal) : false;
                            return GestureDetector(
                              onTap: _hasRated ? null : () => _submitRating(starVal),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  _hasRated 
                                      ? (isActive ? Icons.star_rounded : Icons.star_border_rounded)
                                      : Icons.star_border_rounded,
                                  color: _hasRated 
                                      ? (isActive ? Colors.amber : Colors.grey[600])
                                      : Colors.grey[400],
                                  size: 32,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
