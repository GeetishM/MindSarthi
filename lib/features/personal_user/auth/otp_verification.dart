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
  bool _isVerifying = false; // ✅ Prevent duplicate calls

  Future<void> _verifyOtp(String otp) async {
    if (_isVerifying) return; // ✅ Prevent duplicate execution
    setState(() => _isVerifying = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = authResult.user;

      if (user != null) {
        final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await doc.get();

        if (!snapshot.exists) {
          await doc.set({'uid': user.uid, 'phoneNumber': widget.phoneNumber});
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
    // Optionally add real resend OTP logic here.
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width / 375;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: size.width < 400 ? double.infinity : size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(20),
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
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.phoneNumber,
                          style: TextStyle(
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // OTP Input
                        Pinput(
                          length: 6,
                          onChanged: (value) => _enteredOtp = value,
                          onCompleted: (value) {
                            if (!_isVerifying) {
                              _verifyOtp(value);
                            }
                          },
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 56,
                            textStyle: TextStyle(
                              fontSize: 20 * fontScale,
                              color: Colors.black,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.deepPurpleAccent),
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

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!_isVerifying) {
                                _verifyOtp(_enteredOtp);
                              }
                            },
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Resend
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
