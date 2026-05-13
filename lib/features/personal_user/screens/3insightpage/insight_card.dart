import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class InsightCard extends StatefulWidget {
  final String heading;
  final String content;
  final String author;
  final String date;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const InsightCard({
    super.key,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                  radius: 20,
                  child: Icon(
                    Icons.person_rounded, 
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 20,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.author, 
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.content,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 2,
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
                      onTap: widget.onBookmarkToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isBookmarked 
                              ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight) 
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: widget.isBookmarked 
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary) 
                              : (isDark ? AppColors.darkTextHint : AppColors.textHint),
                          size: 20,
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