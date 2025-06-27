import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'app_lock_storage.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();

  void _savePin() async {
    final pin = _pinController.text;
    if (pin.length == 4) {
      await AppLockStorage.setPin(pin);
      await AppLockStorage.setPinEnabled(true);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 4-digit PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Passcode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter a 4-digit PIN"),
            const SizedBox(height: 20),
            Pinput(
              length: 4,
              controller: _pinController,
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _savePin,
              child: const Text("Save PIN"),
            ),
          ],
        ),
      ),
    );
  }
}
