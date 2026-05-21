import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/spotify_screen.dart';

class Anxity extends StatefulWidget {
  const Anxity({super.key});

  @override
  State<Anxity> createState() => _AnxityState();
}

class _AnxityState extends State<Anxity> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: const Text('Anxiety & panic relief'),
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
              // Welcome / Intro Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkPrimaryLight, AppColors.darkSurface2]
                        : [const Color(0xFFE0F2F1), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkPrimary.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BREATHE IN CALM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You are safe here.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a tool below to calm your body and slow racing thoughts.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.heart_circle,
                      size: 48,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Guided Tools Section Header
              Text(
                'THERAPEUTIC TOOLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Breathing Exercise
              _buildIOSCard(
                icon: CupertinoIcons.wind,
                title: 'Guided Breathing',
                subtitle: 'Practice 4-7-8 box breathing',
                color: const Color(0xFF00796B),
                isDark: isDark,
                onTap: () => _showBreathingDialog(context, isDark),
              ),

              // 5-4-3-2-1 Grounding Method
              _buildIOSCard(
                icon: CupertinoIcons.eye_solid,
                title: '5-4-3-2-1 Grounding',
                subtitle: 'Re-anchor yourself to the present',
                color: Colors.teal.shade700,
                isDark: isDark,
                onTap: () => _showGroundingSheet(context, isDark),
              ),

              // Relaxation Music
              _buildIOSCard(
                icon: CupertinoIcons.music_note_list,
                title: 'Relaxation Music',
                subtitle: 'Continuous soothing ambient streams',
                color: Colors.indigo,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpotifyPlayerScreen(
                        playlistId: '0eU3ubPAnqeSMi9K3YKVpC',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              
              // Urgent SOS Helpline
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C1914) : const Color(0xFFFFF2EE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.phone_fill, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Need Immediate Help?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you are having a severe panic attack or medical emergency, you can call the emergency crisis hotline instantly.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _callHotline(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.phone, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Call Crisis Helpline (988)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callHotline() async {
    final Uri url = Uri.parse('tel:988');
    if (await launchUrl(url)) {
      HapticFeedback.mediumImpact();
    }
  }

  // ── BREATHING GUIDANCE DIALOG ────────────────────────────────

  void _showBreathingDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => _BreathingGuideDialog(isDark: isDark),
    );
  }

  // ── 5-4-3-2-1 GROUNDING TECHNIQUE SHEET ───────────────────────

  void _showGroundingSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroundingSheet(isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BREATHING DIALOG COMPONENT
// ─────────────────────────────────────────────────────────────────────────────

class _BreathingGuideDialog extends StatefulWidget {
  final bool isDark;
  const _BreathingGuideDialog({required this.isDark});

  @override
  State<_BreathingGuideDialog> createState() => _BreathingGuideDialogState();
}

class _BreathingGuideDialogState extends State<_BreathingGuideDialog> {
  int _secondsRemaining = 4;
  String _currentPhase = 'Inhale';
  int _phaseIndex = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  late Timer _timer;

  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  final List<int> _durations = [4, 7, 8, 4];
  final List<Color> _colors = [
    AppColors.primary,
    const Color(0xFFFFB300),
    Colors.teal.shade300,
    const Color(0xFFFFB300)
  ];
  final List<String> _tips = [
    'Breathe in slowly through your nose...',
    'Hold your breath comfortably...',
    'Exhale slowly and completely through your mouth...',
    'Pause, rest your mind...',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _phaseIndex = (_phaseIndex + 1) % 4;
          _currentPhase = _phases[_phaseIndex];
          _secondsRemaining = _durations[_phaseIndex];
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _colors[_phaseIndex];
    // Scale animation factor based on breathing state
    double scale = 1.0;
    if (_phaseIndex == 0) { // Inhaling: expands
      scale = 1.0 + (0.5 * (1.0 - (_secondsRemaining / _durations[_phaseIndex])));
    } else if (_phaseIndex == 1) { // Holding: stays expanded
      scale = 1.5;
    } else if (_phaseIndex == 2) { // Exhaling: deflates
      scale = 1.0 + (0.5 * (_secondsRemaining / _durations[_phaseIndex]));
    } // Holding empty: stays at 1.0

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Box Breathing (4-7-8)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.clear_circled, size: 22),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            // Pulsating Visual circle
            SizedBox(
              height: 220,
              child: Center(
                child: AnimatedScale(
                  scale: scale,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outward shadow ring
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      // Core bubble
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentColor,
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ]
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_secondsRemaining',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              _currentPhase.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: currentColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            
            Text(
              _tips[_phaseIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  5-4-3-2-1 GROUNDING TECHNIQUE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _GroundingSheet extends StatefulWidget {
  final bool isDark;
  const _GroundingSheet({required this.isDark});

  @override
  State<_GroundingSheet> createState() => _GroundingSheetState();
}

class _GroundingSheetState extends State<_GroundingSheet> {
  int _currentStep = 0; // Steps 0 to 4
  
  final List<GroundingStepData> _steps = [
    GroundingStepData(
      number: '5',
      sensoryType: 'SEE',
      instruction: 'Acknowledge FIVE things you see around you.',
      hint: 'Look around: a light, a chair, a plant, a picture, or a pen. Let your eyes focus on them.',
      icon: CupertinoIcons.eye_fill,
      color: Colors.blue,
    ),
    GroundingStepData(
      number: '4',
      sensoryType: 'TOUCH',
      instruction: 'Acknowledge FOUR things you can touch.',
      hint: 'Feel your clothes, the hard desk, the texture of your phone, or a cold metallic coin.',
      icon: CupertinoIcons.hand_draw_fill,
      color: Colors.orange,
    ),
    GroundingStepData(
      number: '3',
      sensoryType: 'HEAR',
      instruction: 'Acknowledge THREE things you hear.',
      hint: 'Listen closely: traffic outside, hum of a fan, birds chirping, or distant murmurs.',
      icon: CupertinoIcons.waveform,
      color: Colors.teal,
    ),
    GroundingStepData(
      number: '2',
      sensoryType: 'SMELL',
      instruction: 'Acknowledge TWO things you can smell.',
      hint: 'Try to sniff: soap, coffee, wood, perfume, or take a deep smell of fresh outdoor air.',
      icon: CupertinoIcons.wind,
      color: Colors.amber,
    ),
    GroundingStepData(
      number: '1',
      sensoryType: 'TASTE',
      instruction: 'Acknowledge ONE thing you can taste.',
      hint: 'Focus on your tongue: taste toothpaste, water, coffee, or a mint candy. If empty, notice saliva.',
      icon: CupertinoIcons.drop_fill,
      color: Colors.pink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / 5.0;
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag bar
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5-4-3-2-1 Grounding',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                'Step ${_currentStep + 1} of 5',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              color: step.color,
              backgroundColor: widget.isDark ? AppColors.darkBorder : AppColors.border,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),
          
          // Step visual representation
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: step.color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                // Big Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: step.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(step.icon, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${step.number} • ${step.sensoryType}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  step.instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Navigation button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: step.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (_currentStep < 4) {
                setState(() => _currentStep++);
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Well done. You are re-anchored in the present moment.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text(
              _currentStep < 4 ? 'I noticed this' : 'Complete Grounding',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class GroundingStepData {
  final String number;
  final String sensoryType;
  final String instruction;
  final String hint;
  final IconData icon;
  final Color color;

  GroundingStepData({
    required this.number,
    required this.sensoryType,
    required this.instruction,
    required this.hint,
    required this.icon,
    required this.color,
  });
}
