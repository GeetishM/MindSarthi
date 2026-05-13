import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/theme_toggle.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/app_lock/app_lock_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/profile.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  String _initial(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) return 'U';
    return nickname.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.white;
    final headerBg = isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight;
    final nameColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Drawer(
      backgroundColor: bgColor,
      child: Column(
        children: [
          // ── Profile header ─────────────────────────────
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _shimmerHeader(isDark);
              }

              final data   = snapshot.data;
              final name   = data?['nickname'] ?? 'User';
              final photo  = data?['photoUrl'];
              final letter = _initial(name);

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  decoration: BoxDecoration(color: headerBg),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            isDark ? AppColors.darkSurface2 : AppColors.white,
                        backgroundImage: (photo != null &&
                                photo.toString().isNotEmpty)
                            ? NetworkImage(photo) as ImageProvider<Object>
                            : null,
                        child: (photo == null || photo.toString().isEmpty)
                            ? Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 22,
                                  color: nameColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Name & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Namaste, $name 👋',
                              style: TextStyle(
                                color: nameColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Tap to edit profile',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: subtitleColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Menu items ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'App Lock',
                  isDark: isDark,
                  onTap: (ctx) => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => const AppLockSettingsScreen(),
                    ),
                  ),
                ),

                // ── Theme toggle row ────────────────────────
                _buildThemeToggleRow(context, isDark),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),

                _buildItem(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  isDark: isDark,
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: (ctx) async {
                    try {
                      await FirebaseAuth.instance.signOut();
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
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Text(
              'MindSarthi • Your calm companion',
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Theme toggle list tile ────────────────────────────
  Widget _buildThemeToggleRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            key: ValueKey(isDark),
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          isDark ? 'Dark Mode' : 'Light Mode',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const ThemeToggleSwitch(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => context.read<ThemeProvider>().toggle(),
      ),
    );
  }

  // ── Standard list tile ────────────────────────────────
  Widget _buildItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required void Function(BuildContext) onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Builder(
      builder: (context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(
          icon,
          color: iconColor ??
              (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ??
                (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => onTap(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Shimmer placeholder ───────────────────────────────
  Widget _shimmerHeader(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Container(
        width: double.infinity,
        height: 130,
        color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
      ),
    );
  }
}
