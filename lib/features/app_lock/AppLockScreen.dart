import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';
import 'app_lock_storage.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  String? _correctPin;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _loadPin();
  }

  Future<void> _loadPin() async {
    _correctPin = await AppLockStorage.getPin();
  }

  Future<void> _checkBiometric() async {
    final isBioEnabled = await AppLockStorage.isBiometricEnabled();
    if (!isBioEnabled) return;

    final canCheck = await _localAuth.canCheckBiometrics;
    if (canCheck) {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock MindSarthi',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavBar()),
        );
      }
    }
  }

  void _verifyPin() async {
    final enteredPin = _pinController.text;
    if (enteredPin == _correctPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavBar()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Enter PIN to Unlock", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Pinput(
                length: 4,
                controller: _pinController,
                obscureText: true,
                onCompleted: (_) => _verifyPin(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyPin,
                child: const Text('Unlock'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
