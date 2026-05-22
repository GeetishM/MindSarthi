import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class PremiumShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String? title;
  final String description;
  final ShapeBorder? targetShapeBorder;
  final Color? tooltipBackgroundColor;
  final Widget child;

  const PremiumShowcase({
    super.key,
    required this.showcaseKey,
    this.title,
    required this.description,
    this.targetShapeBorder,
    this.tooltipBackgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Choose dynamic background color:
    // If tooltipBackgroundColor is provided, use it. Otherwise, use primary color of current theme.
    final bg = tooltipBackgroundColor ?? theme.colorScheme.primary;

    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      targetShapeBorder: targetShapeBorder ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tooltipBackgroundColor: bg,
      tooltipBorderRadius: BorderRadius.circular(24),
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      showArrow: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: -0.2,
      ),
      descTextStyle: const TextStyle(
        color: Color(0xE6FFFFFF), // Softer white text (90% opacity) for description
        fontSize: 13,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      child: child,
    );
  }
}
