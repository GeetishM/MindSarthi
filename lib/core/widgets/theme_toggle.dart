import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// Animated pill-shaped day/night theme toggle.
/// Shows a sun (light mode) or crescent moon (dark mode) sliding thumb
/// on a gradient track that transitions between a warm-sky and deep-night look.
class ThemeToggleSwitch extends StatefulWidget {
  const ThemeToggleSwitch({super.key});

  @override
  State<ThemeToggleSwitch> createState() => _ThemeToggleSwitchState();
}

class _ThemeToggleSwitchState extends State<ThemeToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _rotateAnim;

  // Track dimensions
  static const double _trackW = 72.0;
  static const double _trackH = 36.0;
  static const double _thumbR = 14.0; // thumb radius
  static const double _thumbPad = 4.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slideAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _rotateAnim = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Sync initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDark = context.read<ThemeProvider>().isDark;
      if (isDark) {
        _controller.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(ThemeProvider provider) {
    if (provider.isDark) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    provider.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: () => _toggle(provider),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Track gradient interpolates day → night
              final t = _controller.value;

              // Day colors: warm sky amber + light teal
              final dayStart = const Color(0xFFFDD835);  // warm yellow
              final dayEnd   = const Color(0xFF80DEEA);  // sky cyan

              // Night colors: deep navy + deep teal
              final nightStart = const Color(0xFF0D1F1E);
              final nightEnd   = const Color(0xFF1B3A3D);

              final trackStart = Color.lerp(dayStart, nightStart, t)!;
              final trackEnd   = Color.lerp(dayEnd, nightEnd, t)!;

              // Thumb slides from left (sun) to right (moon)
              final thumbLeft = _thumbPad + (_trackW - _thumbPad * 2 - _thumbR * 2) * t;

              return Container(
                width: _trackW,
                height: _trackH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_trackH / 2),
                  gradient: LinearGradient(
                    colors: [trackStart, trackEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (t > 0.5
                              ? AppColors.darkPrimary
                              : AppColors.primary)
                          .withValues(alpha:  0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ── Background stars (dark mode) ──────────────────
                    if (t > 0.3)
                      Opacity(
                        opacity: ((t - 0.3) / 0.7).clamp(0, 1),
                        child: const _StarField(),
                      ),

                    // ── Thumb (sun → moon) ────────────────────────────
                    Positioned(
                      left: thumbLeft,
                      top: _trackH / 2 - _thumbR,
                      child: Transform.rotate(
                        angle: _rotateAnim.value,
                        child: Container(
                          width: _thumbR * 2,
                          height: _thumbR * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t > 0.5
                                ? const Color(0xFFE8F5F3)  // light teal-white moon
                                : const Color(0xFFFFF9C4), // warm yellow sun
                            boxShadow: [
                              BoxShadow(
                                color: t > 0.5
                                    ? Colors.white.withValues(alpha:  0.3)
                                    : const Color(0xFFFDD835).withValues(alpha:  0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: t > 0.5
                                ? _CrescentMoon(opacity: ((t - 0.5) * 2).clamp(0, 1))
                                : _SunIcon(opacity: (1 - t * 2).clamp(0, 1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Sun icon drawn with CustomPaint ───────────────────────────────────────
class _SunIcon extends StatelessWidget {
  final double opacity;
  const _SunIcon({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: CustomPaint(
        size: const Size(18, 18),
        painter: _SunPainter(),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;

    // Core circle
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFA000)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final inner = r + 2;
      final outer = r + 4.5;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * inner, cy + math.sin(angle) * inner),
        Offset(cx + math.cos(angle) * outer, cy + math.sin(angle) * outer),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Crescent moon drawn with CustomPaint ──────────────────────────────────
class _CrescentMoon extends StatelessWidget {
  final double opacity;
  const _CrescentMoon({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: CustomPaint(
        size: const Size(16, 16),
        painter: _MoonPainter(),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3DB8AA)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2 + 1;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    // Full moon circle
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    // Cutout circle to create crescent
    final cutPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(cx + r * 0.45, cy - r * 0.1),
        radius: r * 0.82,
      ));

    final crescent = Path.combine(PathOperation.difference, moonPath, cutPath);
    canvas.drawPath(crescent, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Tiny star field for dark track ────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 36),
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> _stars = const [
    Offset(8, 8), Offset(14, 20), Offset(22, 12),
    Offset(30, 26), Offset(18, 30), Offset(5, 28),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha:  0.7)
      ..style = PaintingStyle.fill;

    for (final s in _stars) {
      canvas.drawCircle(s, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
