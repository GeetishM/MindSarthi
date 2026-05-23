import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';
import 'package:mindsarthi/core/widgets/premium_showcase.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:provider/provider.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';

class UserSelection extends StatefulWidget {
  const UserSelection({super.key});

  @override
  State<UserSelection> createState() => _UserSelectionState();
}

class _UserSelectionState extends State<UserSelection>
    with SingleTickerProviderStateMixin {
  String? selectedRole;

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final GlobalKey _personalKey = GlobalKey();
  final GlobalKey _professionalKey = GlobalKey();
  final GlobalKey _organizationalKey = GlobalKey();
  final GlobalKey _continueKey = GlobalKey();
  bool _showcaseStarted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _selectRole(String role) => setState(() => selectedRole = role);

  void _continue() {
    if (selectedRole == null) {
      AppToast.warning(context, 'Please select a role to continue');
      return;
    }
    // Set the theme provider role so the login/auth screens match the selected role's theme.
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    final resolvedRole = selectedRole == 'organization' ? 'org' : (selectedRole ?? 'personal');
    provider.setRole(resolvedRole);

    switch (selectedRole) {
      case 'personal':
        Navigator.pushNamed(context, '/personalauth');
      case 'professional':
        Navigator.pushNamed(context, '/professionalauth');
      case 'organization':
        Navigator.pushNamed(context, '/organizationalauth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: () {
        Hive.box('mybox').put('showcase_user_selection', true);
      },
      builder: (context) {
          if (!_showcaseStarted) {
            _showcaseStarted = true;
            final myBox = Hive.box('mybox');
            final hasShown = myBox.get('showcase_user_selection', defaultValue: false);
            if (!hasShown) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (context.mounted) {
                    ShowCaseWidget.of(context).startShowCase([
                      _personalKey,
                      _professionalKey,
                      _organizationalKey,
                      _continueKey,
                    ]);
                  }
                });
              });
            }
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final resolvedRole = selectedRole == 'organization' ? 'org' : (selectedRole ?? 'personal');
          final palette = ThemePalette.forRole(resolvedRole, isDark: isDark);
          final bgCol = palette.background;
          final textPrimaryCol = palette.textPrimary;
          final textSecondaryCol = palette.textSecondary;
          final primaryLightCol = palette.primaryLight;
          final primaryCol = palette.primary;
          final borderCol = palette.border;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            color: bgCol,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: textPrimaryCol,
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/welcome'),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
  
                      // ── Page header ───────────────────────────────
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: primaryLightCol,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Step 1 of 2',
                                  style: TextStyle(
                                    color: primaryCol,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Choose your role',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimaryCol,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Personalises your space and shows\nyou the right tools.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondaryCol,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
  
                      const SizedBox(height: 24),
  
                      // ── Role cards ─────────────────────────────────
                      Expanded(
                        child: ListView(
                          children: [
                            PremiumShowcase(
                              showcaseKey: _personalKey,
                              title: 'Personal User',
                              description: 'Select this if you want to use the app for yourself to build healthier habits & access everyday wellness tools.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tooltipBackgroundColor: ThemePalette.forRole('personal', isDark: isDark).primary,
                              child: _RoleCard(
                                title: 'Personal User',
                                subtitle: "I'm here for myself",
                                description:
                                    'Build healthier habits & access everyday support tools',
                                roleKey: 'personal',
                                icon: Icons.person_rounded,
                                accentColor: ThemePalette.forRole('personal', isDark: isDark).primary,
                                imagePath: 'assets/illustrations/curiosity-pana 1.svg',
                                isSelected: selectedRole == 'personal',
                                onTap: () => _selectRole('personal'),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PremiumShowcase(
                              showcaseKey: _professionalKey,
                              title: 'Professional User',
                              description: 'Select this if you are a mental health practitioner looking to manage clients and share guidance.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tooltipBackgroundColor: ThemePalette.forRole('professional', isDark: isDark).primary,
                              child: _RoleCard(
                                title: 'Professional User',
                                subtitle: "I'm a Mental Health Professional",
                                description:
                                    'Offer support, manage clients & grow your practice',
                                roleKey: 'professional',
                                icon: Icons.health_and_safety_rounded,
                                accentColor: ThemePalette.forRole('professional', isDark: isDark).primary,
                                imagePath: 'assets/illustrations/curiosity-pana 1.svg',
                                isSelected: selectedRole == 'professional',
                                onTap: () => _selectRole('professional'),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PremiumShowcase(
                              showcaseKey: _organizationalKey,
                              title: 'Organizational User',
                              description: 'Select this if you are part of a company or organization seeking wellness programs for your team.',
                              targetShapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tooltipBackgroundColor: ThemePalette.forRole('org', isDark: isDark).primary,
                              child: _RoleCard(
                                title: 'Organizational User',
                                subtitle: "I'm part of an Organization",
                                description:
                                    'Access workplace wellness tools & team programmes',
                                roleKey: 'organization',
                                icon: Icons.business_rounded,
                                accentColor: ThemePalette.forRole('org', isDark: isDark).primary,
                                imagePath: 'assets/illustrations/curiosity-pana 1.svg',
                                isSelected: selectedRole == 'organization',
                                onTap: () => _selectRole('organization'),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
  
                      // ── Continue button — color tracks selected role ──
                      PremiumShowcase(
                        showcaseKey: _continueKey,
                        title: 'Proceed & Continue',
                        description: 'Tap this button after choosing a role to complete your signup or sign in process.',
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tooltipBackgroundColor: primaryCol,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: selectedRole != null
                                ? primaryCol
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                            border: Border.all(
                              color: selectedRole != null
                                  ? Colors.transparent
                                  : borderCol.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            boxShadow: selectedRole != null
                                ? [
                                    BoxShadow(
                                      color: primaryCol.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _continue,
                              borderRadius: BorderRadius.circular(14),
                              splashColor: Colors.white.withValues(alpha: 0.15),
                              highlightColor: Colors.white.withValues(alpha: 0.05),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: selectedRole != null
                                            ? Colors.white
                                            : textSecondaryCol.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      child: selectedRole != null
                                          ? const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
      },
    );
  }
}

// ─── Role card widget ───────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String roleKey;
  final String imagePath;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemePalette palette;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.roleKey,
    required this.imagePath,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    // When selected: solid accent background + all text/icons go white
    final textColor = isSelected 
        ? Colors.white 
        : palette.textPrimary;
    final subTextColor = isSelected
        ? Colors.white.withValues(alpha: 0.85)
        : palette.textSecondary;

    final cardBg = isSelected 
        ? accentColor 
        : palette.surface2;
    final cardBorder = isSelected 
        ? accentColor 
        : palette.border.withValues(alpha: 0.4);
    
    final iconBg = isSelected
        ? Colors.white.withValues(alpha: 0.20)
        : palette.primaryLight;
    final iconCol = isSelected 
        ? Colors.white 
        : palette.primary;

    final indicatorBorder = isSelected 
        ? Colors.white 
        : palette.border;

    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        borderRadius: BorderRadius.circular(16),
        color: cardBg,
        bevel: isSelected ? 16.0 : 10.0,
        // For selected: colorful accent shadow; for idle: standard soft neumorphic shadow
        shadowColor: isSelected ? accentColor.withValues(alpha: 0.3) : null,
        lightShadowColor: isSelected ? Colors.white.withValues(alpha: 0.15) : null,
        border: Border.all(
          color: cardBorder,
          width: isSelected ? 1.5 : 0.8,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Icon badge ──────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconCol,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ── Text ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Selection indicator ──────────────────────
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: indicatorBorder,
                  width: 2,
                ),
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

