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
//  ThemePalette
// ─────────────────────────────────────────────────────────────────────────────

class ThemePalette {
  final Color primary;
  final Color primaryLight; // tertiary
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color surface2; // elevated dark/light surface
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color error;
  final Color success;
  final Color warning;
  final Color accent;
  final Color onPrimary;

  const ThemePalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.error,
    required this.success,
    required this.warning,
    required this.accent,
    required this.onPrimary,
  });

  factory ThemePalette.forRole(String role, {required bool isDark}) {
    if (isDark) {
      switch (role) {
        case 'professional':
          return const ThemePalette(
            primary: AppColors.darkProfessional,
            primaryLight: AppColors.darkProfessionalLight,
            primaryDark: AppColors.professionalDark,
            background: Color(0xFF0F111E), // cool dark slate background
            surface: Color(0xFF17192A),
            surface2: Color(0xFF20233B),
            border: Color(0xFF2D3150),
            divider: Color(0xFF20233B),
            textPrimary: Color(0xFFE2E4F3),
            textSecondary: Color(0xFF8E93B3),
            textHint: Color(0xFF5A5E78),
            error: AppColors.error,
            success: AppColors.success,
            warning: AppColors.warning,
            accent: AppColors.accent,
            onPrimary: Color(0xFF0F111E),
          );
        case 'org':
          return const ThemePalette(
            primary: AppColors.darkOrg,
            primaryLight: AppColors.darkOrgLight,
            primaryDark: AppColors.orgDark,
            background: Color(0xFF1F110D), // warm dark coral background
            surface: Color(0xFF261915),
            surface2: Color(0xFF32231E),
            border: Color(0xFF422B24),
            divider: Color(0xFF32231E),
            textPrimary: Color(0xFFFBECE8),
            textSecondary: Color(0xFFC39F95),
            textHint: Color(0xFF89675D),
            error: AppColors.error,
            success: AppColors.success,
            warning: AppColors.warning,
            accent: AppColors.accent,
            onPrimary: Color(0xFF1F110D),
          );
        case 'personal':
        default:
          return const ThemePalette(
            primary: AppColors.darkPrimary,
            primaryLight: AppColors.darkPrimaryLight,
            primaryDark: AppColors.primaryDark,
            background: AppColors.darkBackground,
            surface: AppColors.darkSurface,
            surface2: AppColors.darkSurface2,
            border: AppColors.darkBorder,
            divider: AppColors.darkDivider,
            textPrimary: AppColors.darkTextPrimary,
            textSecondary: AppColors.darkTextSecondary,
            textHint: AppColors.darkTextHint,
            error: AppColors.error,
            success: AppColors.success,
            warning: AppColors.warning,
            accent: AppColors.accent,
            onPrimary: AppColors.darkBackground,
          );
      }
    } else {
      switch (role) {
        case 'professional':
          return const ThemePalette(
            primary: AppColors.professional,
            primaryLight: AppColors.professionalLight,
            primaryDark: AppColors.professionalDark,
            background: Color(0xFFF5F6FA), // cool grey/indigo scaffold background
            surface: AppColors.white,
            surface2: AppColors.white,
            border: Color(0xFFD5D8E7),
            divider: Color(0xFFE8EAF3),
            textPrimary: Color(0xFF1A1C29),
            textSecondary: Color(0xFF5A5E78),
            textHint: Color(0xFF9EA3C0),
            error: AppColors.error,
            success: AppColors.success,
            warning: AppColors.warning,
            accent: AppColors.accent,
            onPrimary: AppColors.white,
          );
        case 'org':
          return const ThemePalette(
            primary: AppColors.org,
            primaryLight: AppColors.orgLight,
            primaryDark: AppColors.orgDark,
            background: Color(0xFFFCFAF9), // warm coral/peach scaffold background
            surface: AppColors.white,
            surface2: AppColors.white,
            border: Color(0xFFF7DFD6),
            divider: Color(0xFFFCEFEA),
            textPrimary: Color(0xFF2C1E1A),
            textSecondary: Color(0xFF755C54),
            textHint: Color(0xFFBCAAA4),
            error: AppColors.error,
            success: AppColors.success,
            warning: AppColors.warning,
            accent: AppColors.accent,
            onPrimary: AppColors.white,
          );
        case 'personal':
        default:
          return const ThemePalette(
            primary: AppColors.primary,
            primaryLight: AppColors.primaryLight,
            primaryDark: AppColors.primaryDark,
            background: AppColors.background,
            surface: AppColors.surface,
            surface2: AppColors.surface,
            border: AppColors.border,
            divider: AppColors.divider,
            textPrimary: AppColors.textPrimary,
            textSecondary: AppColors.textSecondary,
            textHint: AppColors.textHint,
            error: AppColors.error,
            success: AppColors.success,
            warning: AppColors.warning,
            accent: AppColors.accent,
            onPrimary: AppColors.textOnPrimary,
          );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppTheme
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light => getThemeForRole('personal', isDark: false);
  static ThemeData get dark => getThemeForRole('personal', isDark: true);

  static ThemeData getThemeForRole(String role, {required bool isDark}) {
    final palette = ThemePalette.forRole(role, isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: palette.surface,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        secondary: palette.accent,
        onSecondary: AppColors.white,
        tertiary: palette.primaryLight,
        error: palette.error,
        onError: AppColors.white,
      ),

      scaffoldBackgroundColor: palette.background,

      // ── AppBar ───────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: palette.border,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),

      // ── Card ─────────────────────────────────────────
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: palette.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input / TextField ─────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? palette.surface2 : palette.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 1.8),
        ),
        hintStyle: TextStyle(
          color: palette.textHint, fontSize: 14, fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: palette.textSecondary, fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: palette.primary, fontSize: 13, fontWeight: FontWeight.w600,
        ),
      ),

      // ── ElevatedButton ───────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: isDark ? palette.background : AppColors.white,
          disabledBackgroundColor: palette.primaryLight,
          disabledForegroundColor: palette.primary,
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
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary, width: 1.5),
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
          foregroundColor: palette.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FAB — coral accent for key CTAs ─────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── NavigationBar ────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        shadowColor: palette.border,
        indicatorColor: palette.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: palette.primary, size: 24);
          }
          return IconThemeData(color: palette.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: palette.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return TextStyle(
            color: palette.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // ── Drawer ───────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),

      // ── Chip ─────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? palette.surface2 : palette.background,
        selectedColor: palette.primary,
        disabledColor: isDark ? palette.surface2 : palette.background,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: palette.textPrimary,
        ),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ──────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 0,
      ),

      // ── SnackBar (use AppToast instead) ──────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? palette.surface2 : palette.textPrimary,
        contentTextStyle: TextStyle(color: isDark ? palette.textPrimary : AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ─────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 13,
        ),
      ),

      // ── Progress indicator ────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
      ),

      // ── Typography ────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: palette.textPrimary, letterSpacing: -0.8, height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: palette.textPrimary, letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: palette.textPrimary, letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: palette.textPrimary, letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: palette.textPrimary, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: palette.textSecondary, height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: palette.textSecondary, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: palette.textSecondary, letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: palette.textHint, letterSpacing: 0.5,
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) => const Icon(Icons.arrow_back_ios_new_rounded),
      ),
    );
  }
}

