import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
import 'otp_verification.dart';

class PersonalAuth extends StatefulWidget {
  const PersonalAuth({super.key});

  @override
  State<PersonalAuth> createState() => _PersonalAuthState();
}

class _PersonalAuthState extends State<PersonalAuth> {
  final _auth = FirebaseAuth.instance;
  String? _phoneNumber;
  String? _phoneError;

  bool get _isValid => _phoneNumber != null && _phoneError == null;

  void _validatePhone(String? value) {
    setState(() {
      _phoneError = (value == null || value.isEmpty) ? 'Phone number is required' : null;
    });
  }

  Future<void> _sendOtp() async {
    _validatePhone(_phoneNumber);
    if (_phoneError != null) return;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: (cred) async {
          await _auth.signInWithCredential(cred);
        },
        verificationFailed: (e) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('OTP Error'),
            description: Text(e.message ?? 'Unknown error'),
          );
        },
        codeSent: (verificationId, resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: _phoneNumber!,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );

      toastification.show(
        context: context,
        type: ToastificationType.info,
        title: const Text('OTP Sent'),
        description: const Text('Please check your SMS inbox.'),
      );
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Verification Failed'),
        description: Text(e.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: Center(
        child: Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                alignment: Alignment.center,
                child: const Text(
                  "Log In or Sign Up",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: const Text(
                        "Welcome to MindSarthi",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        border: _buildBorder(),
                        enabledBorder: _buildBorder(),
                        focusedBorder: _buildBorder(focused: true),
                        errorText: _phoneError,
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _phoneNumber = phone.completeNumber;
                        _validatePhone(_phoneNumber);
                      },
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isValid ? "Continue" : "Enter your phone",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("or"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSocialButton(
                      icon: SvgPicture.asset('assets/icons/google.svg', height: 20),
                      text: "Continue with Google",
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                    _buildSocialButton(
                      icon: const Icon(Icons.apple, color: Colors.black, size: 25),
                      text: "Continue with Apple",
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: icon),
            Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _buildBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _phoneError != null
            ? Colors.red
            : focused
                ? (_isValid ? Colors.green : const Color(0xFF222222))
                : (_isValid ? Colors.green : const Color(0xFFBDBDBD)),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}
