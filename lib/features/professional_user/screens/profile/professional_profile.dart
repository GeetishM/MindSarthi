import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/app_lock/app_lock_settings_screen.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/theme_toggle.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';

class ProfessionalProfile extends StatefulWidget {
  const ProfessionalProfile({super.key});

  @override
  State<ProfessionalProfile> createState() => _ProfessionalProfileState();
}

class _ProfessionalProfileState extends State<ProfessionalProfile> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _specializations = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(_uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameCtrl.text = data['displayName'] ?? '';
        _bioCtrl.text = data['bio'] ?? '';
        _experienceCtrl.text = data['experience'] ?? '';
        _specializations =
            List<String>.from(data['specializations'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('professionals')
          .doc(_uid)
          .set({
        'uid': _uid,
        'displayName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'experience': _experienceCtrl.text.trim(),
        'specializations': _specializations,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) AppToast.success(context, 'Profile saved');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Save failed', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSpecialization() {
    final text = _specCtrl.text.trim();
    if (text.isNotEmpty && !_specializations.contains(text)) {
      setState(() {
        _specializations.add(text);
        _specCtrl.clear();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Logout failed', description: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: Text(
                  _isSaving ? 'Saving...' : 'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: isDark
                          ? AppColors.darkPrimaryLight
                          : AppColors.primaryLight,
                      child: Text(
                        (_nameCtrl.text.isNotEmpty)
                            ? _nameCtrl.text[0].toUpperCase()
                            : 'D',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Display name
                  _buildLabel('Display Name', isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Dr. Jane Smith',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Experience
                  _buildLabel('Experience', isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _experienceCtrl,
                    decoration: const InputDecoration(
                      hintText: '10 years',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  _buildLabel('Bio', isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'A brief introduction about yourself...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Specializations
                  _buildLabel('Specializations', isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _specCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. CBT, Anxiety',
                          ),
                          onFieldSubmitted: (_) => _addSpecialization(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addSpecialization,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _specializations.map((spec) {
                      return Chip(
                        label: Text(spec),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () =>
                            setState(() => _specializations.remove(spec)),
                        backgroundColor: isDark
                            ? AppColors.darkPrimaryLight
                            : AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        deleteIconColor:
                            isDark ? AppColors.darkPrimary : AppColors.primary,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // ── Account section ───────────────────────────────────
                  Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Theme toggle tile
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        CupertinoIcons.lock_shield,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 22,
                      ),
                      title: const Text(
                        'App Lock',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Secure your app with a passcode',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_forward,
                        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                        size: 16,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Theme toggle tile
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 22,
                      ),
                      title: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle app theme',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      trailing: const ThemeToggleSwitch(),
                      onTap: () => context.read<ThemeProvider>().toggle(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Logout tile
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      onTap: _logout,
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: Text(
                        'Sign out of your account',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }
}
