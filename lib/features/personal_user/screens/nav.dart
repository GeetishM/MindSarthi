import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/theme_toggle.dart';
import 'package:mindsarthi/core/localization/locale_provider.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/home.dart';
import 'package:mindsarthi/features/personal_user/screens/2consultpage/consult.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/community.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/screen/chat_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/boxes.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/app_lock/app_lock_settings_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/profile.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:mindsarthi/core/widgets/premium_showcase.dart';
import 'package:mindsarthi/core/widgets/app_dialog.dart';
import 'package:mindsarthi/core/widgets/app_action_sheet.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  String _chatSearchQuery = '';

  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _expertsKey = GlobalKey();
  final GlobalKey _discoverKey = GlobalKey();
  final GlobalKey _connectKey = GlobalKey();
  final GlobalKey _sarthiKey = GlobalKey();
  bool _showcaseStarted = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(menuKey: _menuKey),
      const ConsultPage(),
      const InsightPage(),
      const CommunityPage(),
      const ChatScreen(),
    ];
  }

  GlobalKey _getTabKey(int index) {
    switch (index) {
      case 0: return _homeKey;
      case 1: return _expertsKey;
      case 2: return _discoverKey;
      case 3: return _connectKey;
      case 4: return _sarthiKey;
      default: return GlobalKey();
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0: return 'Home Dashboard';
      case 1: return 'Consult Experts';
      case 2: return 'Discover Insights';
      case 3: return 'Connect Community';
      case 4: return 'Sarthi AI Companion';
      default: return '';
    }
  }

  String _getTabDesc(int index) {
    switch (index) {
      case 0: return 'Your personal feed tracking goals, mood patterns, and active panic SOS help.';
      case 1: return 'Connect with certified mental health professional counselors and therapists.';
      case 2: return 'Explore guided journals, articles, self-care paths, and wellness media.';
      case 3: return 'Join support communities, discussion rooms, and share your experiences.';
      case 4: return 'Chat with our AI companion Sarthi for instant active listening and support.';
      default: return '';
    }
  }

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

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  String _initial(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) return 'U';
    return nickname.trim()[0].toUpperCase();
  }

  void _showLanguageSelector(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    MindSarthiActionSheet.show(
      context: context,
      title: 'Choose Language',
      subtitle: 'भाषा चुनें',
      actions: [
        ActionSheetItem(
          label: 'English',
          icon: CupertinoIcons.textformat,
          onTap: () => localeProvider.setLocale(const Locale('en')),
        ),
        ActionSheetItem(
          label: 'हिन्दी (Hindi)',
          icon: CupertinoIcons.textformat,
          onTap: () => localeProvider.setLocale(const Locale('hi')),
        ),
        ActionSheetItem(
          label: 'বাংলা (Bengali)',
          icon: CupertinoIcons.textformat,
          onTap: () => localeProvider.setLocale(const Locale('bn')),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await MindSarthiDialog.show(
      context: context,
      title: 'Sign Out?',
      content: 'Are you sure you want to sign out of MindSarthi?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Sign out failed', description: e.toString());
        }
      }
    }
  }

  Future<void> _deleteChat(BuildContext context, ChatHistory chat) async {
    final confirmed = await MindSarthiDialog.show(
      context: context,
      title: 'Delete Chat?',
      content: 'Are you sure you want to permanently delete this chat history?',
      confirmText: 'Yes, Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      final provider = context.read<ChatProvider>();
      await provider.deletChatMessages(chatId: chat.chatId);
      await chat.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShowCaseWidget(
      onFinish: () {
        Hive.box('mybox').put('showcase_nav', true);
      },
      builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;

          if (!_showcaseStarted) {
            _showcaseStarted = true;
            final myBox = Hive.box('mybox');
            final hasShown = myBox.get('showcase_nav', defaultValue: false);
            if (!hasShown) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (context.mounted) {
                    final isMobile = screenWidth < 640;
                    final list = isMobile
                        ? [_menuKey, _homeKey, _expertsKey, _discoverKey, _connectKey, _sarthiKey]
                        : [_profileKey, _homeKey, _expertsKey, _discoverKey, _connectKey, _sarthiKey];
                    ShowCaseWidget.of(context).startShowCase(list);
                  }
                });
              });
            }
          }

          if (screenWidth < 640) {
            // ── Mobile layout (< 640px) ───────────────────────────
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
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        _navItems.length,
                        (index) => _buildMobileNavItem(index, isDark),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (screenWidth >= 640 && screenWidth < 1024) {
            // ── Tablet Layout (640px - 1024px) (Icons-only rail) ──
            return Scaffold(
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              body: Row(
                children: [
                  _buildTabletSidebar(isDark),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  Expanded(
                    child: _pages[_currentIndex],
                  ),
                ],
              ),
            );
          } else {
            // ── Desktop Layout (>= 1024px) (Expanded primary sidebar) ──
            return Scaffold(
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              body: Row(
                children: [
                  _buildDesktopSidebar(isDark),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  // Double Sidebar for Chat Page
                  if (_currentIndex == 4) ...[
                    _buildInnerChatHistorySidebar(context, isDark),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ],
                  Expanded(
                    child: _currentIndex == 4
                        ? Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: _pages[_currentIndex],
                            ),
                          )
                        : _pages[_currentIndex],
                  ),
                ],
              ),
            );
          }
        },
    );
  }

  // ── Mobile Nav Item Builder ──────────────────────────────────────────
  Widget _buildMobileNavItem(int index, bool isDark) {
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

    return PremiumShowcase(
      showcaseKey: _getTabKey(index),
      title: _getTabTitle(index),
      description: _getTabDesc(index),
      targetShapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: GestureDetector(
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
      ),
    );
  }

  // ── Tablet Sidebar (Icons-only Rail) ──────────────────────────────
  Widget _buildTabletSidebar(bool isDark) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final railBg = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      width: 76,
      color: railBg,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.heart_circle_fill,
              color: activeColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 36),
          // Tabs
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: PremiumShowcase(
                      showcaseKey: _getTabKey(index),
                      title: _getTabTitle(index),
                      description: _getTabDesc(index),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Tooltip(
                        message: item.label,
                        child: InkWell(
                          onTap: () => setState(() => _currentIndex = index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected ? activeColor : inactiveColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          // Bottom Settings Buttons (Icons Only)
          _buildTabletSettingButton(
            icon: CupertinoIcons.lock_shield,
            tooltip: 'App Lock',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
            ),
            isDark: isDark,
          ),
          _buildTabletSettingButton(
            icon: isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
            tooltip: 'Theme',
            onTap: () => context.read<ThemeProvider>().toggle(),
            isDark: isDark,
          ),
          _buildTabletSettingButton(
            icon: Icons.translate_rounded,
            tooltip: 'Language',
            onTap: () => _showLanguageSelector(context),
            isDark: isDark,
          ),
          PremiumShowcase(
            showcaseKey: _profileKey,
            title: 'Your Profile & Settings',
            description: 'Configure App Lock settings, toggle theme mode, select language preference, and sign out of your account.',
            targetShapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildTabletSettingButton(
              icon: CupertinoIcons.profile_circled,
              tooltip: 'Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              isDark: isDark,
            ),
          ),
          _buildTabletSettingButton(
            icon: Icons.logout_rounded,
            tooltip: 'Sign Out',
            onTap: () => _handleLogout(context),
            isDark: isDark,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabletSettingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop Sidebar (Expanded Logo + Profile + Info) ───────────────
  Widget _buildDesktopSidebar(bool isDark) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      width: 260,
      color: bg,
      child: Column(
        children: [
          // Logo & Name
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.heart_circle_fill,
                    color: activeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'MindSarthi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),

          // User Profile Header
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Shimmer.fromColors(
                    baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
                    highlightColor: isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              }

              final data = snapshot.data;
              final name = data?['nickname'] ?? 'User';
              final letter = _initial(name);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: PremiumShowcase(
                  showcaseKey: _profileKey,
                  title: 'Your Profile & Settings',
                  description: 'Access your profile to check settings, configure passcodes for App Lock, switch light/dark theme, and change language preference.',
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface2 : AppColors.primaryLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: activeColor,
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'View profile',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: inactiveColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Tabs List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
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

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: PremiumShowcase(
                    showcaseKey: _getTabKey(index),
                    title: _getTabTitle(index),
                    description: _getTabDesc(index),
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _currentIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected ? activeColor : inactiveColor,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              translatedLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? activeColor : textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Settings Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildDesktopSettingsTile(
                  icon: CupertinoIcons.lock_shield,
                  title: 'App Lock',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
                  ),
                  isDark: isDark,
                ),
                _buildDesktopSettingsTile(
                  icon: isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  title: isDark ? 'Dark Mode' : 'Light Mode',
                  trailing: const ThemeToggleSwitch(),
                  onTap: () => context.read<ThemeProvider>().toggle(),
                  isDark: isDark,
                ),
                _buildDesktopSettingsTile(
                  icon: Icons.translate_rounded,
                  title: context.tr('sb_language'),
                  onTap: () => _showLanguageSelector(context),
                  isDark: isDark,
                ),
                _buildDesktopSettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  onTap: () => _handleLogout(context),
                  isDark: isDark,
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ── Chat Inner Sidebar (Double Sidebar Mode) ───────────────────────
  Widget _buildInnerChatHistorySidebar(BuildContext context, bool isDark) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final sideBg = isDark ? AppColors.darkBackground : AppColors.background;

    return Container(
      width: 320,
      color: sideBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & New Chat button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final provider = context.read<ChatProvider>();
                    await provider.prepareChatRoom(isNewChat: true, chatID: '');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.plus,
                      color: activeColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CupertinoSearchTextField(
              placeholder: 'Search chats...',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
              ),
              backgroundColor: isDark ? AppColors.darkSurface2 : Colors.teal.shade50.withOpacity(0.4),
              onChanged: (val) {
                setState(() {
                  _chatSearchQuery = val;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // ValueListenableBuilder for reactive chat list
          Expanded(
            child: ValueListenableBuilder<Box<ChatHistory>>(
              valueListenable: Boxes.getChatHistory().listenable(),
              builder: (context, box, _) {
                var chatHistory = box.values.toList().cast<ChatHistory>().reversed.toList();

                if (_chatSearchQuery.isNotEmpty) {
                  chatHistory = chatHistory
                      .where((c) =>
                          c.prompt.toLowerCase().contains(_chatSearchQuery.toLowerCase()) ||
                          c.response.toLowerCase().contains(_chatSearchQuery.toLowerCase()))
                      .toList();
                }

                if (chatHistory.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _chatSearchQuery.isEmpty ? 'No chat history' : 'No matches found',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: chatHistory.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 64,
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chatHistory[index];
                    final chatProvider = context.watch<ChatProvider>();
                    final isActive = chatProvider.currentChatId == chat.chatId;

                    return Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark ? AppColors.darkPrimaryLight.withOpacity(0.3) : AppColors.primaryLight.withOpacity(0.5))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.chat_bubble_2,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          chat.prompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            chat.response,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            CupertinoIcons.delete,
                            color: AppColors.error.withOpacity(0.7),
                            size: 14,
                          ),
                          onPressed: () => _deleteChat(context, chat),
                        ),
                        onTap: () async {
                          await chatProvider.prepareChatRoom(
                            isNewChat: false,
                            chatID: chat.chatId,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
