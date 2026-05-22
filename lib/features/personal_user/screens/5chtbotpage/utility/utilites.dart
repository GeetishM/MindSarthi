import 'package:flutter/material.dart';
import 'package:mindsarthi/core/widgets/app_dialog.dart';

void showMyAnimatedDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String actionText,
  required Function(bool) onActionPressed,
}) async {
  final isDestructive = actionText.toLowerCase().contains('delete') ||
      actionText.toLowerCase().contains('remove') ||
      actionText.toLowerCase().contains('clear');
      
  final result = await MindSarthiDialog.show(
    context: context,
    title: title,
    content: content,
    confirmText: actionText,
    cancelText: 'Cancel',
    isDestructive: isDestructive,
  );
  onActionPressed(result == true);
}


