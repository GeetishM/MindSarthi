import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;

  const MyButton({
    super.key, 
    required this.text, 
    required this.onPressed, 
    this.color,
    this.icon, required Color textColor, required int borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: color ?? Colors.pinkAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color.fromARGB(255, 249, 245, 244)),
            SizedBox(width: 8),
          ],
          Text(text, style: TextStyle(color: const Color.fromARGB(255, 242, 220, 212), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
