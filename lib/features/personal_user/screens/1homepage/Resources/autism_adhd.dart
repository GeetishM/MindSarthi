import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class AutismAdhdScreen extends StatefulWidget {
  const AutismAdhdScreen({super.key});

  @override
  State<AutismAdhdScreen> createState() => _AutismAdhdScreenState();
}

class _AutismAdhdScreenState extends State<AutismAdhdScreen> with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Bubble Pop, 1: Ambient Wash, 2: Sensory Guide, 3: Noise Player
  
  // Color wash animation
  late AnimationController _colorController;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_colorController);
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: const Text('Neurodivergent support'),
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
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.info_circle,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            onPressed: () => _showSensoryInfoDialog(context, isDark),
          )
        ],
      ),
      body: Column(
        children: [
          // iOS Segmented Control
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: isDark ? AppColors.darkSurface : AppColors.white,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _activeTab,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.primaryLight.withValues(alpha: 0.5),
              thumbColor: isDark ? AppColors.darkPrimaryLight : AppColors.white,
              children: {
                0: _buildTabHeader('Fidget Pop', CupertinoIcons.circle_grid_hex, isDark, 0),
                1: _buildTabHeader('Color Wash', CupertinoIcons.color_filter, isDark, 1),
                2: _buildTabHeader('Checklist', CupertinoIcons.square_list, isDark, 2),
                3: _buildTabHeader('Noise', CupertinoIcons.waveform, isDark, 3),
              },
              onValueChanged: (value) {
                if (value != null) {
                  HapticFeedback.lightImpact();
                  setState(() => _activeTab = value);
                }
              },
            ),
          ),
          
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildActiveTabContent(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(String label, IconData icon, bool isDark, int index) {
    final isSelected = _activeTab == index;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 0:
        return const BubblePopGame();
      case 1:
        return _buildColorWashTab(isDark);
      case 2:
        return const SensoryChecklistTab();
      case 3:
        return const WhiteNoiseTab();
      default:
        return const BubblePopGame();
    }
  }

  Widget _buildColorWashTab(bool isDark) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        final double t = _colorAnimation.value;
        
        // Cycle colors smoothly
        final c1 = Color.lerp(const Color(0xFFE0F2F1), const Color(0xFFE8EAF6), t)!;
        final c2 = Color.lerp(const Color(0xFFFFF0EB), const Color(0xFFE3F2FD), t)!;
        final c3 = Color.lerp(const Color(0xFFFFF8E1), const Color(0xFFF1F8E9), t)!;

        final darkC1 = Color.lerp(const Color(0xFF0F2624), const Color(0xFF13172E), t)!;
        final darkC2 = Color.lerp(const Color(0xFF2C1E18), const Color(0xFF0F1E29), t)!;
        final darkC3 = Color.lerp(const Color(0xFF242217), const Color(0xFF121F0F), t)!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [darkC1, darkC2, darkC3] : [c1, c2, c3],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.eye,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Visual Decompression',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rest your eyes on this screen. Let the shifting colors slow your breathing and calm your sensory receptors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSensoryInfoDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(CupertinoIcons.sparkles, color: isDark ? AppColors.darkPrimary : AppColors.primary),
            const SizedBox(width: 8),
            const Text('Sensory relief tools'),
          ],
        ),
        content: Text(
          'These tools are designed to support individuals with Autism, ADHD, or sensory processing differences during overload.\n\n'
          '• Fidget Pop: Interactive tactile simulation to channel stimming urges.\n'
          '• Color Wash: Calm, changing light display to relax hyper-arousal.\n'
          '• Checklist: Cognitive scaffolding during moments of overwhelm.\n'
          '• Noise Player: Audio masking to filter out disruptive ambient environments.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

// ── 1. BUBBLE POP GAME ──────────────────────────────────────────

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({super.key});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  final List<BubbleData> _bubbles = [];
  final List<PopParticle> _particles = [];
  final math.Random _random = math.Random();
  
  bool _colorMatchMode = false;
  late Color _targetColor;
  int _score = 0;
  
  final List<Color> _bubbleColors = [
    Colors.pink.shade300,
    Colors.teal.shade300,
    Colors.indigo.shade300,
    Colors.amber.shade300,
    Colors.purple.shade300,
    Colors.orange.shade300,
  ];

  final List<String> _colorNames = [
    'Pink',
    'Teal',
    'Indigo',
    'Amber',
    'Purple',
    'Orange',
  ];

  @override
  void initState() {
    super.initState();
    _targetColor = _bubbleColors[0];
    // Start animation loop for floating bubbles and particles
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateGame();
    });
  }

  void _generateBubbles(double width, double height) {
    while (_bubbles.length < 12 && width > 0 && height > 0) {
      final colorIndex = _random.nextInt(_bubbleColors.length);
      final size = 45.0 + _random.nextDouble() * 35.0;
      final speedX = (_random.nextDouble() - 0.5) * 1.5;
      final speedY = -0.5 - _random.nextDouble() * 1.5;
      
      _bubbles.add(
        BubbleData(
          id: DateTime.now().microsecondsSinceEpoch + _random.nextInt(1000) + _bubbles.length,
          x: _random.nextDouble() * (width - size),
          y: height + size,
          size: size,
          color: _bubbleColors[colorIndex],
          colorName: _colorNames[colorIndex],
          speedX: speedX,
          speedY: speedY,
          pulseOffset: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _updateGame() {
    setState(() {
      // Update particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.alpha -= 0.04;
        if (p.alpha <= 0) {
          _particles.removeAt(i);
        }
      }

      // Update bubbles
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final b = _bubbles[i];
        b.x += b.speedX;
        b.y += b.speedY;
        
        // Bounce off walls
        if (b.x <= 0 || b.x >= 350) { // arbitrary max width fallback
          b.speedX = -b.speedX;
        }

        // Float out of screen bounds
        if (b.y < -b.size) {
          _bubbles.removeAt(i);
        }
      }
    });
  }

  void _popBubble(BubbleData bubble) {
    HapticFeedback.mediumImpact();
    
    // Spawn burst particles
    final int particleCount = 12 + _random.nextInt(8);
    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 2.0 + _random.nextDouble() * 4.0;
      _particles.add(
        PopParticle(
          x: bubble.x + bubble.size / 2,
          y: bubble.y + bubble.size / 2,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 3.0 + _random.nextDouble() * 5.0,
          color: bubble.color,
        ),
      );
    }

    setState(() {
      _bubbles.removeWhere((b) => b.id == bubble.id);
      
      if (_colorMatchMode) {
        if (bubble.color == _targetColor) {
          _score += 10;
          // select new target color
          final nextColorIndex = _random.nextInt(_bubbleColors.length);
          _targetColor = _bubbleColors[nextColorIndex];
        } else {
          _score = math.max(0, _score - 5);
        }
      } else {
        _score++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep populating bubbles
        _generateBubbles(constraints.maxWidth, constraints.maxHeight);
        
        // Target color instructions for matching mode
        final targetColorIndex = _bubbleColors.indexOf(_targetColor);
        final targetColorName = targetColorIndex != -1 ? _colorNames[targetColorIndex] : 'Teal';

        return Column(
          children: [
            // Game Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              color: isDark ? AppColors.darkSurface : AppColors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _colorMatchMode ? 'Target: ' : 'Pops: ',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (_colorMatchMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _targetColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _targetColor, width: 1),
                          ),
                          child: Text(
                            targetColorName,
                            style: TextStyle(
                              color: _targetColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Text(
                          '$_score',
                          style: TextStyle(
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                  
                  // Toggle Mode
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _colorMatchMode = !_colorMatchMode;
                        _score = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _colorMatchMode ? CupertinoIcons.gamecontroller_fill : CupertinoIcons.infinite,
                            size: 14,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _colorMatchMode ? 'Color Match' : 'Free Pop',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Interactive Board
            Expanded(
              child: ClipRect(
                child: Stack(
                  children: [
                    // Background Guide Text
                    Center(
                      child: Opacity(
                        opacity: 0.15,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 64,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _colorMatchMode ? 'Pop the matching colors!' : 'Tap bubbles to pop them',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Active Floating Bubbles
                    ..._bubbles.map((bubble) {
                      // Apply pulsating breathing animation offset
                      final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
                      final double scale = 1.0 + 0.05 * math.sin(time * 3 + bubble.pulseOffset);
                      
                      return Positioned(
                        left: bubble.x,
                        top: bubble.y,
                        child: GestureDetector(
                          onTapDown: (_) => _popBubble(bubble),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: bubble.size,
                              height: bubble.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.7),
                                    bubble.color.withValues(alpha: 0.5),
                                    bubble.color.withValues(alpha: 0.8),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                  center: const Alignment(-0.3, -0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: bubble.color.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Custom Painter for popping splash particles
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: ParticlePainter(_particles),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BubbleData {
  final int id;
  double x;
  double y;
  final double size;
  final Color color;
  final String colorName;
  double speedX;
  double speedY;
  final double pulseOffset;

  BubbleData({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.colorName,
    required this.speedX,
    required this.speedY,
    required this.pulseOffset,
  });
}

class PopParticle {
  double x;
  double y;
  final double vx;
  final double vy;
  double size;
  double alpha = 1.0;
  final Color color;

  PopParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<PopParticle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── 2. SENSORY CHECKLIST TAB ────────────────────────────────────

class SensoryChecklistTab extends StatefulWidget {
  const SensoryChecklistTab({super.key});

  @override
  State<SensoryChecklistTab> createState() => _SensoryChecklistTabState();
}

class _SensoryChecklistTabState extends State<SensoryChecklistTab> {
  final List<CopingTask> _tasks = [
    CopingTask(title: 'Put on noise-cancelling headphones', category: 'Audio'),
    CopingTask(title: 'Find a dim, dark, or quiet space', category: 'Visual'),
    CopingTask(title: 'Wrap in a weighted blanket or hug a pillow', category: 'Tactile'),
    CopingTask(title: 'Take 5 slow breaths (Inhale 4s, Exhale 6s)', category: 'Breathing'),
    CopingTask(title: 'Drink a cold glass of water slowly', category: 'System'),
    CopingTask(title: 'Focus on one steady physical object nearby', category: 'Focus'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Calming checklist',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'During periods of sensory overload, follow these simple steps to help de-escalate anxiety and focus your nervous system.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Card(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: task.isCompleted
                            ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.4))
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            task.isCompleted = !task.isCompleted;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isCompleted
                                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                : Colors.transparent,
                            border: Border.all(
                              color: task.isCompleted
                                  ? Colors.transparent
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              width: 2,
                            ),
                          ),
                          child: task.isCompleted
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? (isDark ? AppColors.darkTextHint : AppColors.textHint)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CopingTask {
  final String title;
  final String category;
  bool isCompleted;

  CopingTask({
    required this.title,
    required this.category,
    this.isCompleted = false,
  });
}

// ── 3. WHITE/PINK/BROWN NOISE TAB ──────────────────────────────

class WhiteNoiseTab extends StatefulWidget {
  const WhiteNoiseTab({super.key});

  @override
  State<WhiteNoiseTab> createState() => _WhiteNoiseTabState();
}

class _WhiteNoiseTabState extends State<WhiteNoiseTab> {
  late final WebViewController _webviewController;
  bool _isPlaying = false;
  bool _isLoading = true;
  String _activeNoise = 'brown'; // 'brown', 'pink', 'white'
  
  // YouTube video IDs for loop streams of white, pink, and brown noise
  final Map<String, String> _youtubeIds = {
    'brown': 'hX3j0sQ7as8', // 10 hour real brown noise
    'pink': '8ShG3N2S6sE',  // 10 hour real pink noise
    'white': 'q76bMs-NwRk', // 10 hour pure white noise
  };

  final Map<String, String> _noiseLabels = {
    'brown': 'Brown Noise (Deep & Heavy)',
    'pink': 'Pink Noise (Balanced & Soft)',
    'white': 'White Noise (Bright & Steady)',
  };

  final Map<String, Color> _noiseColors = {
    'brown': Colors.brown.shade400,
    'pink': Colors.pink.shade300,
    'white': Colors.blueGrey.shade300,
  };

  @override
  void initState() {
    super.initState();
    
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webviewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setOnConsoleMessage((JavaScriptConsoleMessage consoleMessage) {
        debugPrint('== NOISE WEBVIEW JS == ${consoleMessage.level.name}: ${consoleMessage.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('== NOISE WEBVIEW ERROR ==: ${error.description} (code: ${error.errorCode})');
          },
          onPageFinished: (_) {
            debugPrint('== NOISE WEBVIEW PAGE FINISHED ==');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('== NOISE WEBVIEW CHANNEL MESSAGE ==: ${message.message}');
          try {
            final Map<String, dynamic> data = jsonDecode(message.message);
            final String? event = data['event'];
            if (event == 'ready') {
              setState(() {
                _isLoading = false;
              });
            } else if (event == 'stateChange') {
              final int? state = data['state'];
              if (state == 1) { // PLAYING
                setState(() {
                  _isLoading = false;
                  _isPlaying = true;
                });
              } else if (state == 2 || state == 0) { // PAUSED or ENDED
                setState(() {
                  _isPlaying = false;
                });
              }
            } else if (event == 'error') {
              setState(() {
                _isLoading = false;
              });
            }
          } catch (e) {
            debugPrint('== Error parsing channel message ==: $e');
          }
        },
      );

    if (_webviewController.platform is AndroidWebViewController) {
      (_webviewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    final initialHtml = _buildPlayerHtml(_youtubeIds[_activeNoise]!, autoplay: false);
    _webviewController.loadHtmlString(initialHtml, baseUrl: 'https://www.youtube-nocookie.com');
  }

  String _buildPlayerHtml(String initialVideoId, {required bool autoplay}) {
    final autoplayVal = autoplay ? 'true' : 'false';
    final autoplayParam = autoplay ? '1' : '0';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background-color: #000; }
    #player { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    var player;
    var currentVideoId = '$initialVideoId';
    var isReady = false;

    function onYouTubeIframeAPIReady() {
      console.log("YT API Loading...");
      player = new YT.Player('player', {
        height: '100%',
        width: '100%',
        videoId: currentVideoId,
        host: 'https://www.youtube-nocookie.com',
        playerVars: {
          'playsinline': 1,
          'autoplay': $autoplayParam,
          'controls': 0,
          'rel': 0,
          'showinfo': 0,
          'mute': 0,
          'loop': 1,
          'origin': 'https://www.youtube-nocookie.com',
          'playlist': currentVideoId
        },
        events: {
          'onReady': onPlayerReady,
          'onStateChange': onPlayerStateChange,
          'onError': onPlayerError
        }
      });
    }

    function onPlayerReady(event) {
      console.log("Player Ready");
      isReady = true;
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({event: 'ready'}));
      }
      
      if ($autoplayVal) {
        // Auto-play attempt
        event.target.playVideo();
        
        // Safety check: if autoplay is blocked, mute, play, and unmute
        setTimeout(function() {
          if (player.getPlayerState() !== 1) {
            console.log("Autoplay blocked. Retrying with mute-unmute cycle...");
            player.mute();
            player.playVideo();
            setTimeout(function() {
              player.unMute();
              player.playVideo();
              console.log("Unmuted playback active.");
            }, 300);
          }
        }, 500);
      }
    }

    function onPlayerStateChange(event) {
      console.log("Player State Change: " + event.data);
      if (event.data === YT.PlayerState.ENDED) {
        player.playVideo(); // Loop support
      }
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({event: 'stateChange', state: event.data}));
      }
    }

    function onPlayerError(event) {
      console.error("Player Error: " + event.data);
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({event: 'error', error: event.data}));
      }
    }

    function playVideo() {
      console.log("Play commanded");
      if (player) {
        player.playVideo();
        setTimeout(function() {
          if (player.getPlayerState() !== 1) {
            console.log("Play failed. Running mute-unmute bypass...");
            player.mute();
            player.playVideo();
            setTimeout(function() {
              player.unMute();
              player.playVideo();
            }, 300);
          }
        }, 300);
      }
    }

    function pauseVideo() {
      console.log("Pause commanded");
      if (player) {
        player.pauseVideo();
      }
    }

    function loadVideo(videoId) {
      console.log("Loading Video: " + videoId);
      currentVideoId = videoId;
      if (player) {
        player.loadVideoById({
          videoId: videoId,
          suggestedQuality: 'small'
        });
        // Wait and ensure it plays
        setTimeout(playVideo, 300);
      }
    }
  </script>
</body>
</html>
''';
  }

  void _loadNoise(String type) {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeNoise = type;
      _isLoading = true;
      _isPlaying = true;
    });
    
    // Load new URL
    _webviewController.runJavaScript('loadVideo("${_youtubeIds[type]}");');
  }

  void _togglePlay() {
    HapticFeedback.mediumImpact();
    if (_isPlaying) {
      _webviewController.runJavaScript('pauseVideo();');
      setState(() {
        _isPlaying = false;
      });
    } else {
      _webviewController.runJavaScript('playVideo();');
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = _noiseColors[_activeNoise]!;
    
    return Stack(
      children: [
        // Covered onscreen WebView for Audio Background Streaming
        Positioned(
          left: 50,
          top: 50,
          width: 200,
          height: 200,
          child: WebViewWidget(controller: _webviewController),
        ),
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.background,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ambient masking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Play continuous, masking frequencies to isolate sound and eliminate sensory overload caused by busy environments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Sound Wave / Vinyl Cover representation
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated Outer Ring
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            width: _isPlaying ? 190 : 160,
                            height: _isPlaying ? 190 : 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor.withValues(alpha: 0.1),
                              border: Border.all(color: activeColor.withValues(alpha: 0.2), width: 2),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: _isPlaying ? 160 : 140,
                            height: _isPlaying ? 160 : 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor.withValues(alpha: 0.15),
                            ),
                          ),
                          
                          // Main Core Button
                          GestureDetector(
                            onTap: _isLoading ? null : _togglePlay,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isLoading ? activeColor.withValues(alpha: 0.5) : activeColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(
                                        _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Center(
                    child: Text(
                      _noiseLabels[_activeNoise]!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Selector Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNoiseButton('brown', 'BROWN', Colors.brown, isDark),
                      _buildNoiseButton('pink', 'PINK', Colors.pink, isDark),
                      _buildNoiseButton('white', 'WHITE', Colors.blueGrey, isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoiseButton(String type, String label, Color color, bool isDark) {
    final isSelected = _activeNoise == type;
    
    return GestureDetector(
      onTap: () => _loadNoise(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
