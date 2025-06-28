  import 'package:flutter/material.dart';

  class InsightCard extends StatefulWidget {
  final String heading;
  final String content;
  final String author;
  final String date;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;

  const InsightCard({
    super.key,
    required this.heading,
    required this.content,
    required this.author,
    required this.date,
    required this.onTap,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
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
                    child: const Icon(Icons.person, color: Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.author, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      Text(widget.heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.date, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: widget.onBookmarkToggle,
                      ),
                      const Icon(Icons.more_horiz),
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