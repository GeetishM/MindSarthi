import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/profile.dart';

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white, // Light background color
        child: ListView(
          children: [
            Material(
              color: Colors.grey[200],
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // No extra color needed here
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[400],
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Nameste, User!",
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _buildSidebarOption(
              icon: Icons.person,
              title: "Personal Information",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.list_alt,
              title: "My Plans",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.lock,
              title: "Change Password",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.language,
              title: "Language",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.card_giftcard,
              title: "Referral Program",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.contact_support,
              title: "Contact Us",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.help_outline,
              title: "FAQs",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSidebarOption(
              icon: Icons.info,
              title: "About",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(color: Colors.grey[400]),
            _buildSidebarOption(
              icon: Icons.logout,
              title: "Log Out",
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut(); // Sign out the user
                  Navigator.pushReplacementNamed(
                    context,
                    '/welcome',
                  ); // Navigate to login screen
                } catch (e) {
                  print("Error signing out: $e"); // Handle errors
                }
              },
              textColor: Colors.red,
            ),
            _buildSidebarOption(
              icon: Icons.delete,
              title: "Delete My Account",
              onTap: () {
                Navigator.pop(context);
              },
              textColor: Colors.red,
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
