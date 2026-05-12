import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/app_lock/app_lock_screen.dart';
import 'package:mindsarthi/features/personal_user/screens/profile.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  String? getProfileInitial(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) return null;
    return nickname.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────
          FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _shimmerHeader();
              }

              final data = snapshot.data;
              final nickname = data?['nickname'] ?? 'User';
              final photoUrl = data?['photoUrl'];
              final initial = getProfileInitial(nickname);

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.white,
                        backgroundImage: (photoUrl != null &&
                                photoUrl.toString().isNotEmpty)
                            ? NetworkImage(photoUrl) as ImageProvider<Object>
                            : null,
                        child: (photoUrl == null || photoUrl.toString().isEmpty)
                            ? Text(
                                initial ?? 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Namaste, $nickname 👋',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to edit profile',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Menu items ────────────────────────────────────
          const SizedBox(height: 8),

          _buildItem(
            icon: Icons.lock_outline_rounded,
            title: 'App Lock',
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.divider),
          ),

          _buildItem(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: (ctx) async {
              try {
                await FirebaseAuth.instance.signOut();
                if (ctx.mounted) {
                  Navigator.pushAndRemoveUntil(
                    ctx,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppToast.error(ctx, 'Logout failed', description: e.toString());
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _shimmerHeader() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: double.infinity,
        height: 160,
        color: AppColors.primaryLight,
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required void Function(BuildContext) onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Builder(
      builder: (context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => onTap(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
