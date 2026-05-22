import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:share_plus/share_plus.dart';


class InsightCard extends StatefulWidget {
  final String heading;
  final String content;
  final String author;
  final String date;
  final String category;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const InsightCard({
    super.key,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
    this.category = '',
    required this.onTap,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate dynamic reading time based on content length
    final wordCount = widget.content.split(RegExp(r'\s+')).length;
    final readTime = (wordCount / 180).ceil().clamp(1, 15);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Reading Time Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? (widget.category.isNotEmpty ? AppColors.darkPrimaryLight : AppColors.darkSurface2) 
                        : (widget.category.isNotEmpty ? AppColors.primaryLight : AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.category.isNotEmpty ? widget.category.toUpperCase() : 'INSIGHT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: widget.category.isNotEmpty 
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•  $readTime min read',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Author and Heading Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                  radius: 18,
                  child: Icon(
                    CupertinoIcons.person_fill, 
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.heading, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.author, 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.content,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.date, 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
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
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.share,
                          color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onBookmarkToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isBookmarked 
                              ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight) 
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isBookmarked
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorder : AppColors.border),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          widget.isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                          color: widget.isBookmarked 
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary) 
                              : (isDark ? AppColors.darkTextHint : AppColors.textHint),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}