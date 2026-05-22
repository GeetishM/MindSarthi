import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

/// A single action item in the [MindSarthiActionSheet].
class ActionSheetItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const ActionSheetItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// A themed bottom action sheet that matches the neumorphic design language.
///
/// Use [MindSarthiActionSheet.show] to display it.
class MindSarthiActionSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<ActionSheetItem> actions;

  const MindSarthiActionSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.actions,
  });

  /// Shows the action sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    String? title,
    String? subtitle,
    required List<ActionSheetItem> actions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MindSarthiActionSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title section
          if (title != null) ...[
            const SizedBox(height: 20),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action items
          ...actions.map((action) {
            final color =
                action.isDestructive ? AppColors.error : textPrimary;
            final iconBgColor = action.isDestructive
                ? AppColors.error.withValues(alpha: 0.1)
                : primaryColor.withValues(alpha: 0.1);
            final iconColor =
                action.isDestructive ? AppColors.error : primaryColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    action.onTap();
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface2
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderCol.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              action.icon,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              action.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: color,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
