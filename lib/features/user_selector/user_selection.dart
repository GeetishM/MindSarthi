import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';

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

  /// Returns the accent color that matches the currently selected role.
  Color get _roleColor {
    switch (selectedRole) {
      case 'personal':     return AppColors.primary;
      case 'professional': return AppColors.professional;
      case 'organization': return AppColors.org;
      default:             return AppColors.border;
    }
  }

  void _continue() {
    if (selectedRole == null) {
      AppToast.warning(context, 'Please select a role to continue');
      return;
    }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
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
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Step 1 of 2',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Choose your role',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Personalises your space and shows\nyou the right tools.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                    _RoleCard(
                      title: 'Personal User',
                      subtitle: "I'm here for myself",
                      description:
                          'Build healthier habits & access everyday support tools',
                      roleKey: 'personal',
                      icon: Icons.person_rounded,
                      accentColor: AppColors.primary,
                      imagePath: 'assets/illustrations/curiosity-pana 1.svg',
                      isSelected: selectedRole == 'personal',
                      onTap: () => _selectRole('personal'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      title: 'Professional User',
                      subtitle: "I'm a Mental Health Professional",
                      description:
                          'Offer support, manage clients & grow your practice',
                      roleKey: 'professional',
                      icon: Icons.health_and_safety_rounded,
                      accentColor: const Color(0xFF5C6BC0),
                      imagePath: 'assets/illustrations/curiosity-pana 1.svg',
                      isSelected: selectedRole == 'professional',
                      onTap: () => _selectRole('professional'),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      title: 'Organizational User',
                      subtitle: "I'm part of an Organization",
                      description:
                          'Access workplace wellness tools & team programmes',
                      roleKey: 'organization',
                      icon: Icons.business_rounded,
                      accentColor: AppColors.accent,
                      imagePath: 'assets/illustrations/curiosity-pana 1.svg',
                      isSelected: selectedRole == 'organization',
                      onTap: () => _selectRole('organization'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Continue button — color tracks selected role ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roleColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ).copyWith(
                    // Keeps ripple white regardless of role color
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (selectedRole != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
  });

  @override
  Widget build(BuildContext context) {
    // When selected: solid accent background + all text/icons go white
    final textColor = isSelected ? Colors.white : AppColors.textPrimary;
    final subTextColor = isSelected
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // ── Icon badge ──────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.20)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
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
                  color: isSelected ? Colors.white : AppColors.border,
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
