import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../screens/emotion_selection_page.dart';

class MoodTrackerHomePage extends StatelessWidget {
  const MoodTrackerHomePage({super.key});

  final List<Mood> moods = const [
    Mood('Awesome', Icons.sentiment_very_satisfied),
    Mood('Good', Icons.sentiment_satisfied),
    Mood('Okay', Icons.sentiment_neutral),
    Mood('Bad', Icons.sentiment_dissatisfied),
    Mood('Terrible', Icons.sentiment_very_dissatisfied),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('How is your mood today?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: moods
                      .map((mood) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: _buildMoodButton(context, mood),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(BuildContext context, Mood mood) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EmotionSelectionPage(mood: mood)),
      ),
      child: Column(
        children: [
          Icon(mood.icon, size: 50),
          Text(mood.name, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
