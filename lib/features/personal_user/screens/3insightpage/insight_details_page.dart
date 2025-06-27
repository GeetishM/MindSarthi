import 'package:flutter/material.dart';

class InsightDetailPage extends StatelessWidget {
  final String heading;
  final String content;
  final String author;
  final String date;
  const InsightDetailPage({
    super.key,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
    });

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(heading),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
