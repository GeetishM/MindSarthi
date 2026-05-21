import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/widgets/preview_images_widget.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField({super.key, required this.chatProvider});

  final ChatProvider chatProvider;

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> {
  // controller for the input field
  final TextEditingController textController = TextEditingController();

  // focus node for the input field
  final FocusNode textFieldFocus = FocusNode();

  // initialize image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // listen to text changes to update send button active/disabled state
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    textController.removeListener(_onTextChanged);
    textController.dispose();
    textFieldFocus.dispose();
    super.dispose();
  }

  Future<void> sendChatMessage({
    required String message,
    required ChatProvider chatProvider,
    required bool isTextOnly,
  }) async {
    try {
      await chatProvider.sentMessage(message: message, isTextOnly: isTextOnly);
    } catch (e) {
      log('error : $e');
    } finally {
      textController.clear();
      widget.chatProvider.setImagesFileList(listValue: []);
      textFieldFocus.unfocus();
    }
  }

  // pick an image
  void pickImage() async {
    try {
      final pickedImages = await _picker.pickMultiImage(
        maxHeight: 800,
        maxWidth: 800,
        imageQuality: 95,
      );
      if (pickedImages.isNotEmpty) {
        widget.chatProvider.setImagesFileList(listValue: pickedImages);
      }
    } catch (e) {
      log('error : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImages = widget.chatProvider.imagesFileList != null &&
        widget.chatProvider.imagesFileList!.isNotEmpty;

    final hasText = textController.text.trim().isNotEmpty;
    final isSendEnabled = (hasText || hasImages) && !widget.chatProvider.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImages) const PreviewImagesWidget(),
          Row(
            children: [
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: pickImage,
                child: Icon(
                  CupertinoIcons.photo,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CupertinoTextField(
                  focusNode: textFieldFocus,
                  controller: textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: widget.chatProvider.isLoading
                      ? null
                      : (String value) {
                          if (isSendEnabled) {
                            sendChatMessage(
                              message: textController.text,
                              chatProvider: widget.chatProvider,
                              isTextOnly: !hasImages,
                            );
                          }
                        },
                  placeholder: 'Enter a prompt...',
                  placeholderStyle: TextStyle(
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    fontSize: 15,
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(4.0),
                onPressed: isSendEnabled
                    ? () {
                        sendChatMessage(
                          message: textController.text,
                          chatProvider: widget.chatProvider,
                          isTextOnly: !hasImages,
                        );
                      }
                    : null,
                child: Icon(
                  CupertinoIcons.arrow_up_circle_fill,
                  color: isSendEnabled
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark
                          ? AppColors.darkTextHint.withValues(alpha: 0.3)
                          : AppColors.textHint.withValues(alpha: 0.3)),
                  size: 34,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}

