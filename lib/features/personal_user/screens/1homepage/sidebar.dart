import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/theme_toggle.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/app_lock/app_lock_settings_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/profile.dart';
import 'package:mindsarthi/core/localization/locale_provider.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    try {
      final databases = AppwriteService().databases;
      final doc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: user.$id,
      );
      return doc.data;
    } catch (_) {
      return null;
    }
  }

  String _initial(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) return 'U';
    return nickname.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Drawer(
      backgroundColor: bgColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Profile Header ─────────────────────────────
                FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUserProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _shimmerHeader(isDark);
                    }

                    final data = snapshot.data;
                    final name = data?['nickname'] ?? 'User';
                    final letter = _initial(name);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfilePage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${context.tr('sb_namaste')}\n$name 👋',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'Tap to view profile',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: subtitleColor,
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
                    );
                  },
                ),

                // ── Sidebar Items ──────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildAnimatedItem(
                        index: 1,
                        icon: CupertinoIcons.lock_shield_fill,
                        title: context.tr('sb_app_lock'),
                        isDark: isDark,
                        onTap: (ctx) => Navigator.push(
                          ctx,
                          MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
                        ),
                      ),
                      _buildAnimatedThemeToggleRow(context, isDark, index: 2),
                      _buildAnimatedLanguageSelector(context, isDark, index: 3),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Divider(thickness: 1, height: 1),
                      ),
                      _buildAnimatedItem(
                        index: 4,
                        icon: Icons.logout_rounded,
                        title: context.tr('sb_logout'),
                        isDark: isDark,
                        textColor: AppColors.error,
                        iconColor: AppColors.error,
                        onTap: (ctx) async {
                          try {
                            await ref.read(authRepositoryProvider).signOut();
                            if (ctx.mounted) {
                              Navigator.pushAndRemoveUntil(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              AppToast.error(
                                ctx,
                                'Logout failed',
                                description: e.toString(),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // ── Footer ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 16),
                  child: Text(
                    'MindSarthi • Your pocket companion',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            // ── Close Button ─────────────────────────────
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface2 : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha:  0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Animated Theme toggle list tile ────────────────────────────
  Widget _buildAnimatedThemeToggleRow(BuildContext context, bool isDark, {required int index}) {
    final slideAnimation = Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                key: ValueKey(isDark),
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                size: 24,
              ),
            ),
            title: Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const ThemeToggleSwitch(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () => context.read<ThemeProvider>().toggle(),
          ),
        ),
      ),
    );
  }

  // ── Animated Language selector list tile ────────────────────────
  Widget _buildAnimatedLanguageSelector(BuildContext context, bool isDark, {required int index}) {
    final slideAnimation = Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final localeProvider = context.watch<LocaleProvider>();
    final currentLanguage = localeProvider.locale.languageCode;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              Icons.translate_rounded,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 24,
            ),
            title: Text(
              context.tr('sb_language'),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: DropdownButton<String>(
              value: currentLanguage,
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 14))),
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(fontSize: 14))),
                DropdownMenuItem(value: 'bn', child: Text('বাংলা', style: TextStyle(fontSize: 14))),
              ],
              onChanged: (val) {
                if (val != null) {
                  localeProvider.setLocale(Locale(val));
                }
              },
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  // ── Animated Standard list tile ────────────────────────────────
  Widget _buildAnimatedItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isDark,
    required void Function(BuildContext) onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final slideAnimation = Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                icon,
                color: iconColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                size: 24,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: textColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => onTap(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              hoverColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }

  // ── Shimmer placeholder ───────────────────────────────
  Widget _shimmerHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor: isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
        child: Container(
          width: double.infinity,
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
