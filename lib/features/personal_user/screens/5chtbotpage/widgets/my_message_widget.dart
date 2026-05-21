import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/models/message.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/widgets/preview_images_widget.dart';

class MyMessageWidget extends StatelessWidget {
  const MyMessageWidget({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkPrimary, AppColors.primaryDark]
                : [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imagesUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: PreviewImagesWidget(message: message),
              ),
            MarkdownBody(
              selectable: true,
              data: message.message.toString(),
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
                strong: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontStyle: FontStyle.italic,
                ),
                listBullet: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

