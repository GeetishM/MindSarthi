import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  final String heading;
  final String content;
  final String author;
  final String date;
  final VoidCallback onTap;

  const InsightCard({
    super.key,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: 24,
                    child: const Icon(
                      Icons.person,
                      color: Colors.black54,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        heading,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                maxLines: 2, // Limit the number of lines
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if text is longer
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.bookmark_border),
                      SizedBox(width: 8),
                      Icon(Icons.more_horiz),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
