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
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12, left: 8),
        child: message.isEmpty
            ? SpinKitThreeBounce(
                color: isDark ? AppColors.darkPrimary : AppColors.primary, 
                size: 20.0,
              )
            : MarkdownBody(
                selectable: true, 
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
      ),
    );
  }
}
