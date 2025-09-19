import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool isProfessional;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.isProfessional = true,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _enteredOtp = '';
  String? _error;
  bool _isVerifying = false;

  Future<void> _verifyOtp(String otp) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

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
        final collectionName = widget.isProfessional ? 'p_user' : 'users';
        final doc = FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid);
        final snapshot = await doc.get();

        if (!snapshot.exists) {
          await doc.set({
            'uid': user.uid,
            'phoneNumber': widget.phoneNumber,
            'isProfessional': widget.isProfessional,
          });

          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text("New user created"),
            autoCloseDuration: const Duration(seconds: 2),
          );
        } else {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text("Welcome back!"),
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NavBar()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Invalid OTP';
        _isVerifying = false;
      });
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text("OTP Verification Failed"),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  void _resendOtp() {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: const Text("Resend OTP tapped"),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = MediaQuery.of(context).size.width / 375;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (_, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Verification Required",
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Enter the verification code sent via SMS",
                          style: TextStyle(fontSize: 14 * fontScale),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.phoneNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Pinput(
                          length: 6,
                          onChanged: (val) => _enteredOtp = val,
                          onCompleted: (val) => _verifyOtp(val),
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 56,
                            textStyle: TextStyle(fontSize: 20 * fontScale),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _verifyOtp(_enteredOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * fontScale,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _resendOtp,
                          child: Text(
                            "Didn't receive the code? Resend",
                            style: TextStyle(
                              fontSize: 14 * fontScale,
                              color: Colors.deepPurpleAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
