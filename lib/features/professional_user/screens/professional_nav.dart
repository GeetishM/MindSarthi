import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/professional_user/screens/dashboard/professional_home.dart';
import 'package:mindsarthi/features/professional_user/screens/sessions/session_list.dart';
import 'package:mindsarthi/features/professional_user/screens/clients/client_list.dart';
import 'package:mindsarthi/features/professional_user/screens/profile/professional_profile.dart';
import 'package:mindsarthi/features/professional_user/screens/profile/profile_completion_gate.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_cms.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

class ProfessionalNav extends ConsumerStatefulWidget {
  const ProfessionalNav({super.key});

  @override
  ConsumerState<ProfessionalNav> createState() => _ProfessionalNavState();
}

class _ProfessionalNavState extends ConsumerState<ProfessionalNav> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  late final List<Widget> _pages;

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
      label: 'Insights',
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
    ),
    _NavItemData(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      ProfessionalHome(
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const SessionList(),
      const ClientList(),
      ProfileCompletionGate(
        onNavigateToProfile: () {
          setState(() {
            _currentIndex = 4; // index of Profile
          });
        },
        child: const InsightCmsPage(showBackButton: false),
      ),
      const ProfessionalProfile(),
    ];
    _checkProfileOnNavInit();
  }

  Future<void> _checkProfileOnNavInit() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final databases = AppwriteService().databases;
      bool isComplete = false;
      try {
        final doc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.professionalProfilesCollectionId,
          documentId: user.$id,
        );
        isComplete = doc.data['profileComplete'] as bool? ?? false;
      } catch (_) {}

      if (!isComplete && mounted) {
        _showProfileReminderDialog();
      }
    } catch (e) {
      debugPrint('Error checking professional profile status: $e');
    }
  }

  void _showProfileReminderDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.lock_person_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Complete Your Profile",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            "Please take a moment to set up your display name, bio, experience, specializations, and upload your certificates in your Profile. This is required to show your profile in counselling sessions and to publish insights.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Later',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 4; // Navigate to Profile tab
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Profile'),
            ),
          ],
        );
      },
    );
  }

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
        body: SafeArea(
          top: true,
          bottom: false,
          child: _pages[_currentIndex],
        ),
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
          horizontal: isSelected ? 14.0 : 10.0,
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
                      fontSize: 12,
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
