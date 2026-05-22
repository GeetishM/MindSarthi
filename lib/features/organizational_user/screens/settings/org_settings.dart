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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
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
                    color: theme.colorScheme.primary,
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
                // ── Organization ─────────────────────────────
                const _SectionHeader(title: 'Organization'),
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
                const _SectionHeader(title: 'Policies'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Anonymous Reporting',
                  subtitle: 'Allow team members to submit anonymous reports',
                  trailing: Switch.adaptive(
                    value: _anonymousReporting,
                    onChanged: (v) =>
                        setState(() => _anonymousReporting = v),
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Mandatory Weekly Check-in',
                  subtitle: 'Require weekly wellness check-ins from all members',
                  trailing: Switch.adaptive(
                    value: _mandatoryCheckin,
                    onChanged: (v) =>
                        setState(() => _mandatoryCheckin = v),
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Appearance ────────────────────────────────
                const _SectionHeader(title: 'Appearance'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: isDark
                      ? Icons.nights_stay_rounded
                      : Icons.wb_sunny_rounded,
                  title: isDark ? 'Dark Mode' : 'Light Mode',
                  subtitle: 'Toggle app theme',
                  trailing: const ThemeToggleSwitch(),
                  onTap: () =>
                      context.read<ThemeProvider>().toggle(),
                ),
                const SizedBox(height: 28),

                // ── Account ───────────────────────────────────
                const _SectionHeader(title: 'Account'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: CupertinoIcons.lock_shield,
                  title: 'App Lock',
                  subtitle: 'Secure your app with a passcode',
                  trailing: Icon(
                    CupertinoIcons.chevron_forward,
                    color: theme.hintColor,
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

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: theme.hintColor,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor ?? theme.textTheme.bodyMedium?.color,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: titleColor ?? theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
