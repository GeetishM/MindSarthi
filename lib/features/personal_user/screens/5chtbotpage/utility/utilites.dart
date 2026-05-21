import 'package:flutter/cupertino.dart';

void showMyAnimatedDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String actionText,
  required Function(bool) onActionPressed,
}) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(content),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            onActionPressed(false);
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: actionText.toLowerCase() == 'delete',
          onPressed: () {
            onActionPressed(true);
            Navigator.of(context).pop();
          },
          child: Text(actionText),
        ),
      ],
    ),
  );
}

