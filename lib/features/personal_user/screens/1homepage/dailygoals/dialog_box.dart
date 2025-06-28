import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/my_button.dart';

class DialogBox extends StatelessWidget {
  final controller;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  DialogBox({
    super.key,
    required this.controller,
    required this.onSave,
    required this.onCancel,
  });

  void handleSave() {
    if (controller.text.trim().isEmpty) {
      // Optionally, show a message to the user (e.g., using a SnackBar)
      return;
    }
    onSave();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF4EEFF), // Soft lavender background
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.deepPurpleAccent[100]!,
          width: 1.2,
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add a new task',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.deepPurpleAccent[100]!,
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.deepPurpleAccent[100]!,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.deepPurpleAccent[200]!,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(color: Colors.black87),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => handleSave(),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: MyButton(
                    text: "Save",
                    onPressed: handleSave,
                    color: Colors.deepPurpleAccent[200],
                    icon: Icons.check,
                    textColor: Colors.white,
                    borderRadius: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: MyButton(
                    text: "Cancel",
                    onPressed: onCancel,
                    color: Colors.redAccent,
                    icon: Icons.close,
                    textColor: Colors.white,
                    borderRadius: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
