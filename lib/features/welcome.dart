import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/user_selector/user_selection.dart';
import 'package:provider/provider.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ThemeProvider>(context, listen: false).setRole('personal');
      }
    });
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimaryCol = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondaryCol = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textHintCol = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final primaryLightCol = isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: bgCol,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── 1. Texts ─────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      // Brand chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryLightCol,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primaryCol,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your mental wellness companion',
                              style: TextStyle(
                                color: primaryCol,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main headline
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: size.width * 0.075,
                            fontWeight: FontWeight.w800,
                            color: textPrimaryCol,
                            height: 1.25,
                          ),
                          children: [
                            const TextSpan(text: "Hi, I'm "),
                            TextSpan(
                              text: 'MindSarthi',
                              style: TextStyle(color: primaryCol),
                            ),
                            const TextSpan(text: ' 👋'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Your pocket companion for\neveryday mental wellness.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.width * 0.038,
                          color: textSecondaryCol,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ── 2. SVG illustration ───────────────────────────
              SizedBox(
                height: size.height * 0.30,
                child: SvgPicture.asset(
                  'assets/illustrations/Solidarity-pana.svg',
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(flex: 1),

              // ── 3. CTA button ─────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserSelection()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCol,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: size.width * 0.043,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Free • Private • No judgment',
                      style: TextStyle(
                        fontSize: 12,
                        color: textHintCol,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
