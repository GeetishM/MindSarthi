import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/professional_user/screens/dashboard/professional_home.dart';
import 'package:mindsarthi/features/professional_user/screens/sessions/session_list.dart';
import 'package:mindsarthi/features/professional_user/screens/clients/client_list.dart';
import 'package:mindsarthi/features/professional_user/screens/profile/professional_profile.dart';

class ProfessionalNav extends StatefulWidget {
  const ProfessionalNav({super.key});

  @override
  State<ProfessionalNav> createState() => _ProfessionalNavState();
}

class _ProfessionalNavState extends State<ProfessionalNav> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = [
    const ProfessionalHome(),
    const SessionList(),
    const ClientList(),
    const ProfessionalProfile(),
  ];

  final List<_NavItemData> _navItems = [
    _NavItemData(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _NavItemData(
      label: 'Sessions',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
    ),
    _NavItemData(
      label: 'Clients',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    _NavItemData(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        final backPressedRecently = _lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2);

        if (backPressedRecently) {
          SystemNavigator.pop();
        } else {
          _lastBackPressed = now;
          AppToast.info(context, 'Press back again to exit');
        }
      },
      child: Scaffold(
        extendBody: true,
        body: _pages[_currentIndex],
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 68,
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index, theme, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme, bool isDark) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

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
              ? theme.colorScheme.tertiary
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
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
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
                    item.label,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
