import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mindsarthi/features/app_lock/Pinput.dart';
import 'package:mindsarthi/features/app_lock/app_lock_storage.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool isPasscodeEnabled = false;
  bool isBiometricEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pinEnabled = await AppLockStorage.isPinEnabled();
    final bioEnabled = await AppLockStorage.isBiometricEnabled();
    setState(() {
      isPasscodeEnabled = pinEnabled;
      isBiometricEnabled = bioEnabled;
    });
  }

  Future<void> _saveSettings() async {
    await AppLockStorage.setPinEnabled(isPasscodeEnabled);
    await AppLockStorage.setBiometricEnabled(isBiometricEnabled);
  }

  Future<void> _setPasscode() async {
    String? passcode;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Passcode'),
          content: Pinput(
            length: 4,
            obscureText: true,
            onCompleted: (value) {
              passcode = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (passcode != null && passcode!.length == 4) {
                  await AppLockStorage.setPin(passcode!);
                  await AppLockStorage.setPinEnabled(true);
                  Navigator.pop(context);
                  _loadSettings();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleBiometric(bool enabled) async {
    bool canCheck = await auth.canCheckBiometrics;
    bool isAuthenticated = false;

    if (enabled && canCheck) {
      try {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Enable biometric unlock',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } catch (e) {
        isAuthenticated = false;
      }
    }

    if (enabled && !isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
      return;
    }

    setState(() => isBiometricEnabled = enabled);
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App lock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasscodeCard(),
            const SizedBox(height: 20),
            _buildBiometricCard(),
            const SizedBox(height: 12),
            const Text(
              'Keep your app secure by unlocking it with a passcode and biometrics.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasscodeCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  await _setPasscode();
                },
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passcode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Change passcode',
                      style: TextStyle(color: Colors.pink),
                    ),
                  ],
                ),
              ),
            ),
            Switch(
              value: isPasscodeEnabled,
              activeColor: Colors.pink,
              onChanged: (value) async {
                if (value) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePinScreen()),
                  );
                  final enabled = await AppLockStorage.isPinEnabled();
                  setState(() => isPasscodeEnabled = enabled);
                } else {
                  await AppLockStorage.setPinEnabled(false);
                  setState(() => isPasscodeEnabled = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Biometric authentication',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Switch(
              value: isBiometricEnabled,
              activeColor: Colors.pink,
              onChanged: (value) async {
                await _toggleBiometric(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
