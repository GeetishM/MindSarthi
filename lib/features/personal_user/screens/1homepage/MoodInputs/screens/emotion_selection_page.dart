import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/mood.dart';

class EmotionSelectionPage extends StatefulWidget {
  final Mood mood;

  const EmotionSelectionPage({super.key, required this.mood});

  @override
  _EmotionSelectionPageState createState() => _EmotionSelectionPageState();
}

class _EmotionSelectionPageState extends State<EmotionSelectionPage> {
  final List<String> _selectedEmotions = [];
  final TextEditingController _notesController = TextEditingController();
  final List<String> _positiveEmotions = [
    'Happy', 'Proud', 'Calm', 'Confident', 'Content', 'Hopeful', 'Joyful', 'Excited', 'Grateful'
  ];
  final List<String> _negativeEmotions = [
    'Sad', 'Angry', 'Afraid', 'Ashamed', 'Disappointed', 'Lonely', 'Guilty', 'Nervous', 'Upset'
  ];

  Future<void> _saveMood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection("mood_inputs")
        .add({
      'mood': widget.mood.name,
      'emotions': _selectedEmotions,
      'notes': _notesController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _toggleEmotion(String emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else if (_selectedEmotions.length < 3) {
        _selectedEmotions.add(emotion);
      }
    });
  }

  Widget _buildChips(List<String> emotions, Color color) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: emotions.map((emotion) {
        return FilterChip(
          label: Text(emotion),
          selected: _selectedEmotions.contains(emotion),
          onSelected: (_) => _toggleEmotion(emotion),
          selectedColor: color.withOpacity(0.3),
          backgroundColor: Colors.grey.shade200,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Emotions')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(widget.mood.icon, size: 100),
                    const SizedBox(height: 10),
                    Text(widget.mood.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Pick up to 3 emotions in total', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              const Text('Positive emotions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildChips(_positiveEmotions, Colors.blue),
              const SizedBox(height: 20),
              const Text('Negative emotions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildChips(_negativeEmotions, Colors.red),
              const SizedBox(height: 30),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Add notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _selectedEmotions.isNotEmpty ? () async {
                    await _saveMood();
                    Navigator.pop(context);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('CONTINUE', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
