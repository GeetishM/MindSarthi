import 'package:flutter/material.dart';
import 'package:Todo/util/my_button.dart';

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
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE0C3FC), // soft lavender
              Color(0xFF8EC5FC), // pastel blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add a new task',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => handleSave(),
              ),
            ),
            Row(
              mainAxisSize:
                  MainAxisSize.min, // Prevents Row from stretching too much
              children: [
                Flexible(
                  child: MyButton(
                    text: "Save",
                    onPressed: handleSave,
                    color: const Color.fromARGB(255, 32, 223, 38),
                    icon: Icons.check,
                  ),
                ),
                const SizedBox(width: 10), // Slightly reduced spacing
                Flexible(
                  child: MyButton(
                    text: "Cancel",
                    onPressed: onCancel,
                    color: const Color.fromARGB(255, 244, 73, 61),
                    icon: Icons.close,
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
