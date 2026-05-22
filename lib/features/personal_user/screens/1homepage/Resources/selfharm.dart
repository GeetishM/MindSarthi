import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/app_dialog.dart';


class SelfHarm extends StatefulWidget {
  const SelfHarm({super.key});

  @override
  State<SelfHarm> createState() => _SelfHarmState();
}

class _SelfHarmState extends State<SelfHarm> {
  // Safety Delay Timer variables
  Timer? _timer;
  int _secondsRemaining = 900; // 15 minutes
  bool _isTimerRunning = false;
  
  // Dynamic coping tips while timer runs
  final List<String> _timerPrompts = [
    "Take a slow, deep breath. Focus on the sensation of air filling your lungs.",
    "Place your feet flat on the floor. Feel the support beneath you. You are grounded.",
    "Remember: an urge is like a wave. It peaks, but it will eventually pass. Ride it out.",
    "Can you wait just one more minute? You are stronger than this feeling.",
    "Try holding a cold ice cube in your hand, or splash cold water on your face.",
    "Try wrapping yourself tightly in a warm blanket. Comfort your body.",
    "Call or text someone you trust, or dial 988. You do not have to carry this alone.",
    "Give yourself credit for taking this pause. You are keeping yourself safe right now."
  ];
  int _promptIndex = 0;
  Timer? _promptTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _promptTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTimerRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
          _secondsRemaining = 900; // Reset
          _showSafetySuccessDialog();
        }
      });
    });

    // Cycle supportive prompts every 30 seconds
    _promptTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _promptIndex = (_promptIndex + 1) % _timerPrompts.length;
      });
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _promptTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _promptTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = 900;
      _promptIndex = 0;
    });
  }

  void _showSafetySuccessDialog() {
    MindSarthiDialog.show(
      context: context,
      title: 'Wonderful Job ❤️',
      content: 'You completed the 15-minute challenge. By pausing and delaying, you have taken a powerful step in keeping yourself safe. Be proud of yourself.',
      confirmText: 'Close',
      cancelText: 'Cancel',
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: const Text('Crisis support'),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/navbar');
          },
          icon: Icon(
            CupertinoIcons.back,
            size: 22,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SOS Hotlines (High priority / Prominent)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C1914) : const Color(0xFFFFF2EE),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.phone_fill, color: AppColors.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IMMEDIATE SUPPORT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Connect to safety instantly',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you are in danger of hurting yourself, please reach out. Support is free, confidential, and available 24/7.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _textCrisisLine(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.chat_bubble_text, size: 16),
                                SizedBox(width: 8),
                                Text('Text HOME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _callCrisisLine(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.phone, size: 16),
                                SizedBox(width: 8),
                                Text('Call 988', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. 15-Minute Safety Delay Timer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '15-Minute Delay Urge Challenge',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        Icon(CupertinoIcons.stopwatch, size: 18, color: Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Circular Timer representation
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 130,
                          width: 130,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / 900.0,
                            strokeWidth: 8,
                            color: Colors.teal.shade400,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(_secondsRemaining),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'remaining',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    
                    // Coping Tip Text
                    Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      alignment: Alignment.center,
                      child: Text(
                        _timerPrompts[_promptIndex],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isTimerRunning)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: _startTimer,
                            child: const Text('Start Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        else ...[
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: BorderSide(color: Colors.teal.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _pauseTimer,
                            child: const Text('Pause'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _resetTimer,
                            child: const Text('Reset'),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Coping & Distractions Section Header
              Text(
                'SAFE DISTRACTION IDEAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Coping cards list
              _buildDistractionExpansionTile(
                icon: CupertinoIcons.wind,
                title: 'Physical coping strategies',
                color: Colors.teal,
                isDark: isDark,
                children: const [
                  _DistractionItem(text: 'Hold an ice cube in your hand until it melts. Focus on the cold sensation.'),
                  _DistractionItem(text: 'Snap a rubber band gently against your wrist when the urge rises.'),
                  _DistractionItem(text: 'Tear up a piece of scrap paper or cardboard into tiny shreds.'),
                  _DistractionItem(text: 'Draw on your skin with a soft marker or paint where you want to hurt yourself.'),
                ],
              ),
              _buildDistractionExpansionTile(
                icon: CupertinoIcons.sparkles,
                title: 'Mental coping strategies',
                color: Colors.orange,
                isDark: isDark,
                children: const [
                  _DistractionItem(text: 'Count backwards from 100 in decrements of 7 (100, 93, 86, 79...).'),
                  _DistractionItem(text: 'Spell long words backwards, or name one animal for every letter of the alphabet.'),
                  _DistractionItem(text: 'Describe everything in the room around you in clinical detail (colors, textures, shapes).'),
                ],
              ),
              

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistractionExpansionTile({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: children,
          ),
        ),
      ),
    );
  }


  void _callCrisisLine() async {
    final Uri url = Uri.parse('tel:988');
    if (await launchUrl(url)) {
      HapticFeedback.mediumImpact();
    }
  }

  void _textCrisisLine() async {
    final Uri url = Uri.parse('sms:741741?body=HOME');
    if (await launchUrl(url)) {
      HapticFeedback.mediumImpact();
    }
  }
}

class _DistractionItem extends StatelessWidget {
  final String text;
  const _DistractionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            size: 6,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
