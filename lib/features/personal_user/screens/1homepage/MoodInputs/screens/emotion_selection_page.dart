import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
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
  bool _isSaving = false;

  final List<String> _positiveEmotions = [
    'Happy', 'Proud', 'Calm', 'Confident', 'Content', 'Hopeful', 'Joyful', 'Excited', 'Grateful'
  ];
  final List<String> _negativeEmotions = [
    'Sad', 'Angry', 'Afraid', 'Ashamed', 'Disappointed', 'Lonely', 'Guilty', 'Nervous', 'Upset'
  ];

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);
    try {
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mood tracked successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleEmotion(String emotion) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else if (_selectedEmotions.length < 3) {
        _selectedEmotions.add(emotion);
      }
    });
  }

  Widget _buildEmotionSection(String title, List<String> emotions, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: emotions.map((emotion) {
            final isSelected = _selectedEmotions.contains(emotion);
            return GestureDetector(
              onTap: () => _toggleEmotion(emotion),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.2) 
                      : (isDark ? AppColors.darkSurface2 : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : [],
                ),
                child: Text(
                  emotion,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected 
                        ? color 
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: widget.mood.color,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.mood.color,
                      widget.mood.color.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'mood_icon_${widget.mood.name}',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.mood.icon, size: 64, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.mood.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'What emotions describe this?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_selectedEmotions.length}/3',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedEmotions.length == 3 ? AppColors.success : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildEmotionSection('Positive Vibes', _positiveEmotions, AppColors.success, isDark),
                  const SizedBox(height: 32),
                  _buildEmotionSection('Challenging Emotions', _negativeEmotions, AppColors.error, isDark),
                  const SizedBox(height: 32),
                  Text(
                    'Anything else to add?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe your thoughts...',
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface2 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_selectedEmotions.isNotEmpty && !_isSaving) ? _saveMood : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.mood.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: widget.mood.color.withOpacity(0.4),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'COMPLETE ENTRY',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
