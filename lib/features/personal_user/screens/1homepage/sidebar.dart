import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/app_lock/app_lock_screen.dart';
import 'package:mindsarthi/features/personal_user/auth/personal_auth.dart';
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
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: fetchUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // SHIMMER PLACEHOLDER
                  return Material(
                    color: Colors.grey[200],
                    child: DrawerHeader(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 16,
                              width: 120,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data;
                final nickname = data?['nickname'] ?? 'User';
                final photoUrl = data?['photoUrl'];
                final _profileInitial = getProfileInitial(nickname);

                return Material(
                  color: Colors.grey[200],
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    child: DrawerHeader(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.pinkAccent,
                            backgroundImage:
                                (photoUrl != null &&
                                        photoUrl.toString().isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                        as ImageProvider<Object>
                                    : null,
                            child:
                                (photoUrl == null ||
                                        photoUrl.toString().isEmpty)
                                    ? Text(
                                      _profileInitial ?? '',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Namaste, $nickname!",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            _buildSidebarOption(
              icon: Icons.lock,
              title: "App Lock",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppLockSettingsScreen(),
                  ),
                );
              },
            ),

            Divider(color: Colors.grey[400]),

            _buildSidebarOption(
              icon: Icons.logout,
              title: "Log Out",
              textColor: Colors.red,
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  print("Logout failed: $e");
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.black),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.black, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
