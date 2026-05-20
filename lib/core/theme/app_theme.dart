import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MindSarthi Design System — "Healing Teal" palette
//
//  Psychology rationale:
//  • Teal/green-blue → calm, healing, growth, trust (used by Wysa, Calm)
//  • Warm coral accent → empathy, warmth, human connection (the "companion" feel)
//  • Teal-tinted text → avoids the "cold & clinical" grey feeling completely
//  • Warm off-white bg → softer than pure white; never harsh on tired eyes
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Primary — Healing Teal ─────────────────────────────
  /// Main brand color. Teal evokes calm, healing, clarity & trust.
  static const Color primary      = Color(0xFF2D9B8F);
  /// Light tint for chips, selected states, header backgrounds.
  static const Color primaryLight = Color(0xFFE5F5F3);
  /// Deeper shade for pressed states or bold headings.
  static const Color primaryDark  = Color(0xFF1B6B62);

  // ── Accent — Warm Coral ───────────────────────────────
  /// Used on FABs, key CTAs, SOS button — warmth & human connection.
  static const Color accent       = Color(0xFFF4845F);
  /// Light tint for accent backgrounds / highlight chips.
  static const Color accentLight  = Color(0xFFFFF0EB);

  // ── Neutral surfaces ──────────────────────────────────
  static const Color white        = Color(0xFFFFFFFF);
  /// Page scaffold background — barely warm, never harsh.
  static const Color background   = Color(0xFFF6FAF9);
  /// Card / sheet surface — pure white for contrast against bg.
  static const Color surface      = Color(0xFFFFFFFF);
  /// Soft teal-tinted border — not grey, not blue.
  static const Color border       = Color(0xFFD0E9E6);
  static const Color divider      = Color(0xFFE2F0EE);

  // ── Text — teal-tinted, never cold grey ───────────────
  /// Primary text. Dark teal-black — warm, readable, never cold.
  static const Color textPrimary   = Color(0xFF192C2A);
  /// Secondary text. Warm teal-grey — alive, not flat grey.
  static const Color textSecondary = Color(0xFF4D7B78);
  /// Hint / placeholder text. Light teal-grey.
  static const Color textHint      = Color(0xFF9DC4C0);
  /// Text on dark/primary-colored surfaces.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF3AAF7F);   // Soft green — not harsh
  static const Color warning = Color(0xFFF5A623);   // Warm amber
  static const Color error   = Color(0xFFE05252);   // Soft red — calmer than pure red
  static const Color info    = Color(0xFF2D9B8F);   // Same as primary

  // ── Shimmer ───────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE5EFEE);
  static const Color shimmerHighlight = Color(0xFFF2F8F7);

  // ── Dark mode surfaces ────────────────────────────────
  /// Dark scaffold background — very dark teal, not pure black
  static const Color darkBackground   = Color(0xFF0D1F1E);
  /// Dark card / sheet surface
  static const Color darkSurface      = Color(0xFF162421);
  /// Elevated surface (modals, drawers) in dark mode
  static const Color darkSurface2     = Color(0xFF1E302D);
  /// Dark border — subtle teal outline
  static const Color darkBorder       = Color(0xFF2A4040);
  static const Color darkDivider      = Color(0xFF1E302D);
  /// Primary teal in dark mode — slightly lighter so it pops
  static const Color darkPrimary      = Color(0xFF3DB8AA);
  static const Color darkPrimaryLight = Color(0xFF1E3F3C);
  /// Text on dark backgrounds
  static const Color darkTextPrimary   = Color(0xFFE2F5F3);
  static const Color darkTextSecondary = Color(0xFF89B5B1);
  static const Color darkTextHint      = Color(0xFF4D7B78);
  static const Color darkShimmerBase      = Color(0xFF1A3030);
  static const Color darkShimmerHighlight = Color(0xFF234040);

  // ── Professional — Slate Indigo ───────────────────────
  /// Trustworthy, clinical, credible — used across professional dashboards.
  static const Color professional         = Color(0xFF5C6BC0); // Indigo base
  static const Color professionalLight    = Color(0xFFEEF0FB); // Soft tint for chips/bg
  static const Color professionalDark     = Color(0xFF3949AB); // Pressed / bold
  /// Dark-mode variants
  static const Color darkProfessional     = Color(0xFF7986CB); // Lighter indigo for dark bg
  static const Color darkProfessionalLight= Color(0xFF1A1F3A); // Dark surface tint

  // ── Organizational — Warm Coral (extended) ────────────
  /// Same as accent but aliased for the org role. Energetic, corporate.
  static const Color org         = Color(0xFFF4845F); // Same as accent
  static const Color orgLight    = Color(0xFFFFF0EB); // Same as accentLight
  static const Color orgDark     = Color(0xFFD4623C); // Deeper coral for pressed/bold
  /// Dark-mode variants
  static const Color darkOrg      = Color(0xFFFF8A65); // Brighter coral on dark bg
  static const Color darkOrgLight = Color(0xFF3A1E14); // Dark surface tint
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppTheme
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        tertiary: AppColors.primaryLight,
        error: AppColors.error,
        onError: AppColors.white,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ───────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Card ─────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField ─────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint, fontSize: 14, fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600,
        ),
      ),

      // ── ElevatedButton ───────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ───────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FAB — coral accent for key CTAs ─────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── NavigationBar ────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        shadowColor: AppColors.border,
        indicatorColor: AppColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // ── Drawer ───────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),

      // ── Chip ─────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.background,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ──────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ── SnackBar (use AppToast instead) ──────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ─────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),

      // ── Progress indicator ────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // ── Typography ────────────────────────────────────
      // All text uses textPrimary (#192C2A) by default —
      // warm teal-black, never cold blue-grey.
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, letterSpacing: -0.8, height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400,
          // Uses textSecondary — but it's warm teal-grey, NOT flat grey
          color: AppColors.textSecondary, height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.textHint, letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Dark theme
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        tertiary: AppColors.darkPrimaryLight,
        error: AppColors.error,
        onError: AppColors.white,
      ),

      scaffoldBackgroundColor: AppColors.darkBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.darkBorder,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextHint, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: AppColors.darkPrimary, fontSize: 13, fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkBackground,
          disabledBackgroundColor: AppColors.darkPrimaryLight,
          disabledForegroundColor: AppColors.darkPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        indicatorColor: AppColors.darkPrimaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkPrimary, size: 24);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.darkPrimary, fontSize: 11, fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: AppColors.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w500,
          );
        }),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface2,
        selectedColor: AppColors.darkPrimary,
        labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary,
        ),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider, thickness: 1, space: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface2,
        contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkTextSecondary,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkPrimary,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary, letterSpacing: -0.8, height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary, letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary, height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12, color: AppColors.darkTextSecondary, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.darkTextSecondary, letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: AppColors.darkTextHint, letterSpacing: 0.5,
        ),
      ),
    );
  }
}
