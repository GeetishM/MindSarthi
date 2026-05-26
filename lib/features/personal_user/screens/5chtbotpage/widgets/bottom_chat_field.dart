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
    textFieldFocus.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    textController.removeListener(_onTextChanged);
    textFieldFocus.removeListener(_onFocusChanged);
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

    final isFocused = textFieldFocus.hasFocus;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final borderColor = isFocused
        ? primaryColor
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: isFocused ? 12 : 6,
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
                  size: 22,
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
                  placeholder: 'Ask Sarthi about your day...',
                  placeholderStyle: TextStyle(
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 14.5,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 14.0),
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
                      ? primaryColor
                      : (isDark
                          ? AppColors.darkTextHint.withValues(alpha: 0.3)
                          : AppColors.textHint.withValues(alpha: 0.3)),
                  size: 32,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }
}

