import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class PinInputWidget extends StatelessWidget {
  final void Function(String) onCompleted;
  final String title;

  const PinInputWidget({
    super.key,
    required this.onCompleted,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Pinput(
          obscureText: true,
          length: 4,
          autofocus: true,
          onCompleted: onCompleted,
        ),
      ],
    );
  }
}
