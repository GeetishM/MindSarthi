import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntryDates extends StatelessWidget {
  final DateTime createdAt;
  final DateTime lastEdited;

  const EntryDates({
    super.key,
    required this.createdAt,
    required this.lastEdited,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "🗓 ${DateFormat('dd MMM yyyy').format(createdAt)}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (lastEdited != createdAt)
          Text(
            "✏️ ${DateFormat('dd MMM').format(lastEdited)}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }
}
