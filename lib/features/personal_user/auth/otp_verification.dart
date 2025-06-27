import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _enteredOtp = '';
  String? _error;

  Future<void> _verifyOtp(String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final authResult = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = authResult.user;

      if (user != null) {
        final doc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final snapshot = await doc.get();
        if (!snapshot.exists) {
          await doc.set({'uid': user.uid, 'phoneNumber': widget.phoneNumber});

          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text("New user created"),
          );
        } else {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text("Welcome back!"),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavBar()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Invalid OTP');
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text("Error: $e"),
      );
    }
  }

  void _resendOtp() {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: const Text("Resend OTP tapped"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Verification Required",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Enter the verification code sent via SMS"),
              const SizedBox(height: 10),
              Text(
                widget.phoneNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Pinput(
                length: 6,
                onChanged: (value) => _enteredOtp = value,
                onCompleted: _verifyOtp,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 56,
                  textStyle: const TextStyle(fontSize: 20, color: Colors.black),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _verifyOtp(_enteredOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _resendOtp,
                child: const Text("Didn't receive the code? Resend"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
