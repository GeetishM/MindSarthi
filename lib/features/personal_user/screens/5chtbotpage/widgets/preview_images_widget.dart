import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/models/message.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class PreviewImagesWidget extends StatelessWidget {
  const PreviewImagesWidget({super.key, this.message});

  final Message? message;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messageToShow =
            message != null ? message!.imagesUrls : chatProvider.imagesFileList;
        if (messageToShow == null || messageToShow.isEmpty) {
          return const SizedBox.shrink();
        }

        final padding =
            message != null
                ? EdgeInsets.zero
                : const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0);

        return Padding(
          padding: padding,
          child: SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: messageToShow.length,
              itemBuilder: (context, index) {
                final filePath = message != null
                    ? message!.imagesUrls[index]
                    : chatProvider.imagesFileList![index].path;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.file(
                            File(filePath),
                            height: 72,
                            width: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (message == null)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: GestureDetector(
                            onTap: () {
                              final newList = List<XFile>.from(chatProvider.imagesFileList!);
                              newList.removeAt(index);
                              chatProvider.setImagesFileList(listValue: newList);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: AppColors.error,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

