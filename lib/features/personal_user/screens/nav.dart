import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/home.dart';
import 'package:mindsarthi/features/personal_user/screens/2consultpage/consult.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/community.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/screen/chat_screen.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = [
    const HomePage(),
    const ConsultPage(),
    const InsightPage(),
    const CommunityPage(),
    const ChatScreen(),
  ];

  final List<_NavItemData> _navItems = [
    _NavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItemData(
      label: 'Experts',
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services_rounded,
    ),
    _NavItemData(
      label: 'Discover',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    _NavItemData(
      label: 'Connect',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    _NavItemData(
      label: 'Sarthi AI',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        final backPressedRecently = _lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2);

        if (backPressedRecently) {
          exit(0);
        } else {
          _lastBackPressed = now;
          AppToast.info(context, 'Press back again to exit');
        }
      },
      child: Scaffold(
        extendBody: true, // Allows body to scroll behind the transparent/floating nav bar
        body: _pages[_currentIndex],
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    String translatedLabel;
    switch (item.label) {
      case 'Home':
        translatedLabel = context.tr('nav_home');
        break;
      case 'Experts':
        translatedLabel = context.tr('nav_experts');
        break;
      case 'Discover':
        translatedLabel = context.tr('nav_discover');
        break;
      case 'Connect':
        translatedLabel = context.tr('nav_connect');
        break;
      case 'Sarthi AI':
        translatedLabel = context.tr('nav_sarthi');
        break;
      default:
        translatedLabel = item.label;
    }

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    translatedLabel,
                    style: TextStyle(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
