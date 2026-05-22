import 'package:flutter/material.dart';

class NeumorphicTheme {
  static Color getDarkShadow(Color background, bool isDark) {
    if (isDark) {
      // Deeper black-toned shadow for dark mode depth
      return Color.lerp(background, Colors.black, 0.75) ?? Colors.black;
    } else {
      // Soft grey-toned shadow for light mode depth
      return Color.lerp(background, const Color(0xFF000000), 0.12) ?? Colors.grey;
    }
  }

  static Color getLightShadow(Color background, bool isDark) {
    if (isDark) {
      // Subtle highlight reflection for dark mode
      return Color.lerp(background, const Color(0xFFFFFFFF), 0.08) ?? Colors.white10;
    } else {
      // Clean white highlight reflection for light mode
      return Color.lerp(background, const Color(0xFFFFFFFF), 0.85) ?? Colors.white;
    }
  }
}

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final double bevel;
  final bool isPressed;
  final BoxBorder? border;
  final BoxShape shape;
  final Color? shadowColor;
  final Color? lightShadowColor;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.bevel = 12.0,
    this.isPressed = false,
    this.border,
    this.shape = BoxShape.rectangle,
    this.shadowColor,
    this.lightShadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    
    // Resolve the container's base surface color
    final baseColor = color ?? scaffoldBg;

    // Resolve shadow colors
    final darkShadow = shadowColor ?? NeumorphicTheme.getDarkShadow(scaffoldBg, isDark);
    final lightShadow = lightShadowColor ?? NeumorphicTheme.getLightShadow(scaffoldBg, isDark);

    // Shadow offset and blur calculations based on bevel
    final offset = bevel / 2;
    
    List<BoxShadow> shadows;
    if (isPressed) {
      // Simulate inset/sunken shadow by drawing soft, tightly bound inner boundaries
      shadows = [
        BoxShadow(
          color: darkShadow.withValues(alpha: isDark ? 0.35 : 0.25),
          offset: const Offset(1.5, 1.5),
          blurRadius: 3,
        ),
        BoxShadow(
          color: lightShadow.withValues(alpha: isDark ? 0.04 : 0.6),
          offset: const Offset(-1.5, -1.5),
          blurRadius: 3,
        ),
      ];
    } else {
      // Standard extruded neumorphic shadows
      shadows = [
        BoxShadow(
          color: darkShadow,
          offset: Offset(offset, offset),
          blurRadius: bevel,
        ),
        BoxShadow(
          color: lightShadow,
          offset: Offset(-offset, -offset),
          blurRadius: bevel,
        ),
      ];
    }

    final Decoration decoration = BoxDecoration(
      color: baseColor,
      borderRadius: shape == BoxShape.rectangle 
          ? (borderRadius ?? BorderRadius.circular(20)) 
          : null,
      shape: shape,
      border: border ?? Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015),
        width: 0.8,
      ),
      gradient: isPressed
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(baseColor, Colors.black, isDark ? 0.15 : 0.05)!,
                baseColor,
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(baseColor, Colors.white, isDark ? 0.04 : 0.4)!,
                Color.lerp(baseColor, Colors.black, isDark ? 0.08 : 0.03)!,
              ],
            ),
      boxShadow: shadows,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}
