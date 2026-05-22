import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/app_lock/app_lock_storage.dart';
import 'package:mindsarthi/features/app_lock/create_pin_screen.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool isPasscodeEnabled = false;
  bool isBiometricEnabled = false;
  int autoLockSeconds = 0;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pinEnabled = await AppLockStorage.isPinEnabled();
    final bioEnabled = await AppLockStorage.isBiometricEnabled();
    final duration = await AppLockStorage.getAutoLockDuration();
    setState(() {
      isPasscodeEnabled = pinEnabled;
      isBiometricEnabled = bioEnabled;
      autoLockSeconds = duration;
    });
  }

  Future<void> _togglePasscode(bool enabled) async {
    if (enabled) {
      // Go to setup passcode screen
      final result = await Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const CreatePinScreen()),
      );
      // reload settings
      _loadSettings();
    } else {
      // Disable passcode
      await AppLockStorage.setPinEnabled(false);
      await AppLockStorage.setBiometricEnabled(false);
      AppToast.info(context, 'Passcode lock disabled');
      _loadSettings();
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!isPasscodeEnabled && enabled) {
      AppToast.error(context, 'Enable Passcode', description: 'You must set a passcode before enabling biometrics.');
      return;
    }

    bool canCheck = await auth.canCheckBiometrics;
    bool isSupported = await auth.isDeviceSupported();
    if (!canCheck || !isSupported) {
      AppToast.error(context, 'Not Supported', description: 'Biometric authentication is not available on this device.');
      return;
    }

    bool isAuthenticated = false;
    if (enabled) {
      try {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Enable biometric unlock for MindSarthi',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } catch (e) {
        isAuthenticated = false;
        debugPrint('Biometric auth error: $e');
      }
    }

    if (enabled && !isAuthenticated) {
      AppToast.error(context, 'Authentication Failed', description: 'Could not verify your biometrics.');
      return;
    }

    await AppLockStorage.setBiometricEnabled(enabled);
    setState(() => isBiometricEnabled = enabled);
    AppToast.success(context, enabled ? 'Biometrics enabled' : 'Biometrics disabled');
  }

  Future<void> _changeAutoLockDuration(int seconds) async {
    await AppLockStorage.setAutoLockDuration(seconds);
    setState(() => autoLockSeconds = seconds);
    AppToast.success(context, 'Auto-lock setting updated');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final activeTeal = isDark ? AppColors.darkPrimary : AppColors.primary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'App Lock Settings',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: textPrimary,
            size: 26,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Icon Description ─────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: activeTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.lock_shield_fill,
                        color: activeTeal,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secure Your MindSarthi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Keep your journals, mood trackers, and chat logs secure from unwanted access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Settings Card Section ─────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Switch 1: Enable Passcode Lock
                    _buildSettingsTile(
                      icon: CupertinoIcons.padlock_solid,
                      iconColor: activeTeal,
                      title: 'Passcode Lock',
                      subtitle: 'Require 4-digit PIN to open app',
                      trailing: CupertinoSwitch(
                        value: isPasscodeEnabled,
                        activeColor: activeTeal,
                        onChanged: _togglePasscode,
                      ),
                    ),

                    if (isPasscodeEnabled) ...[
                      Divider(color: borderCol, height: 1, indent: 56),
                      // Action: Change Passcode
                      _buildSettingsTile(
                        icon: CupertinoIcons.refresh_bold,
                        iconColor: activeTeal,
                        title: 'Change Passcode',
                        subtitle: 'Update your 4-digit security PIN',
                        onTap: () => _togglePasscode(true),
                        trailing: Icon(
                          CupertinoIcons.chevron_forward,
                          color: textSecondary.withOpacity(0.5),
                          size: 20,
                        ),
                      ),
                      
                      Divider(color: borderCol, height: 1, indent: 56),
                      // Switch 2: Biometric Authentication
                      _buildSettingsTile(
                        icon: CupertinoIcons.device_phone_portrait,
                        iconColor: activeTeal,
                        title: 'Biometric Unlock',
                        subtitle: 'Use Fingerprint or Face ID',
                        trailing: CupertinoSwitch(
                          value: isBiometricEnabled,
                          activeColor: activeTeal,
                          onChanged: _toggleBiometric,
                        ),
                      ),

                      Divider(color: borderCol, height: 1, indent: 56),
                      // Dropdown: Auto lock timing
                      _buildSettingsTile(
                        icon: CupertinoIcons.clock_solid,
                        iconColor: activeTeal,
                        title: 'Auto-Lock Timeout',
                        subtitle: 'Lock app after background inactive',
                        trailing: _buildDurationDropdown(isDark, textPrimary, textSecondary),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Footer Notes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Note: If biometrics or passcodes fail, you can sign out and sign back in with your credentials to restore app access.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDropdown(bool isDark, Color textPrimary, Color textSecondary) {
    final Map<int, String> options = {
      0: 'Immediately',
      30: '30 seconds',
      60: '1 minute',
      300: '5 minutes',
    };

    return DropdownButton<int>(
      value: autoLockSeconds,
      dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
      underline: const SizedBox(),
      alignment: Alignment.centerRight,
      icon: Icon(
        CupertinoIcons.chevron_down,
        color: textSecondary.withOpacity(0.7),
        size: 16,
      ),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkPrimary : AppColors.primary,
      ),
      items: options.entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Text(entry.value),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          _changeAutoLockDuration(val);
        }
      },
    );
  }
}
