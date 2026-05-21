import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class AssistantMessageWidget extends StatelessWidget {
  const AssistantMessageWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12, left: 8),
        child: message.isEmpty
            ? Center(
                widthFactor: 1.0,
                child: SizedBox(
                  width: 50,
                  height: 20,
                  child: SpinKitThreeBounce(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 18.0,
                  ),
                ),
              )
            : MarkdownBody(
                selectable: true,
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                  strong: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
      ),
    );
  }
}

