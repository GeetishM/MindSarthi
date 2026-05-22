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

class OrgSettings extends StatefulWidget {
  const OrgSettings({super.key});

  @override
  State<OrgSettings> createState() => _OrgSettingsState();
}

class _OrgSettingsState extends State<OrgSettings> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  final _orgNameCtrl = TextEditingController();
  bool _anonymousReporting = true;
  bool _mandatoryCheckin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(_uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _orgNameCtrl.text = data['orgName'] ?? '';
        _anonymousReporting = data['anonymousReporting'] ?? true;
        _mandatoryCheckin = data['mandatoryCheckin'] ?? false;
      }
    } catch (e) {
      debugPrint('OrgSettings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(_uid)
          .update({
        'orgName': _orgNameCtrl.text.trim(),
        'anonymousReporting': _anonymousReporting,
        'mandatoryCheckin': _mandatoryCheckin,
      });

      if (mounted) AppToast.success(context, 'Settings saved');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Save failed', description: e.toString());
      }
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
          'Settings',
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
                onPressed: _saveSettings,
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              children: [
                // ── Org Name ──────────────────────────────────
                _SectionHeader(title: 'Organization', isDark: isDark),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orgNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Policies ──────────────────────────────────
                _SectionHeader(title: 'Policies', isDark: isDark),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Anonymous Reporting',
                  subtitle: 'Allow team members to submit anonymous reports',
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: _anonymousReporting,
                    onChanged: (v) =>
                        setState(() => _anonymousReporting = v),
                    activeColor:
                        isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Mandatory Weekly Check-in',
                  subtitle: 'Require weekly wellness check-ins from all members',
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: _mandatoryCheckin,
                    onChanged: (v) =>
                        setState(() => _mandatoryCheckin = v),
                    activeColor:
                        isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Appearance ────────────────────────────────
                _SectionHeader(title: 'Appearance', isDark: isDark),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: isDark
                      ? Icons.nights_stay_rounded
                      : Icons.wb_sunny_rounded,
                  title: isDark ? 'Dark Mode' : 'Light Mode',
                  subtitle: 'Toggle app theme',
                  isDark: isDark,
                  trailing: const ThemeToggleSwitch(),
                  onTap: () =>
                      context.read<ThemeProvider>().toggle(),
                ),
                const SizedBox(height: 28),

                // ── Danger Zone ───────────────────────────────
                _SectionHeader(title: 'Account', isDark: isDark),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: CupertinoIcons.lock_shield,
                  title: 'App Lock',
                  subtitle: 'Secure your app with a passcode',
                  isDark: isDark,
                  trailing: Icon(
                    CupertinoIcons.chevron_forward,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    size: 16,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  isDark: isDark,
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  onTap: _logout,
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextHint : AppColors.textHint,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor ??
              (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: titleColor ??
                (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
