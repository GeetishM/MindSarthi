import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindsarthi/features/personal_user/auth/otp_verification.dart';
import 'package:toastification/toastification.dart';

class PersonalAuth extends StatefulWidget {
  const PersonalAuth({super.key});

  @override
  State<PersonalAuth> createState() => _PersonalAuthState();
}

class _PersonalAuthState extends State<PersonalAuth> {
  String? _phoneNumber;
  String? _phoneError;
  final _auth = FirebaseAuth.instance;

  bool get isValid => _phoneNumber != null && _phoneError == null;

  void _validatePhone(String? value) {
    setState(() {
      _phoneError =
          (value == null || value.isEmpty) ? 'Phone number is required' : null;
    });
  }

  void _sendOtp() {
    _validatePhone(_phoneNumber);
    if (_phoneError != null) return;

    _auth.verifyPhoneNumber(
      phoneNumber: _phoneNumber!,
      verificationCompleted: (cred) async {
        // Auto-retrieved or instant verification
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
            builder:
                (_) => OtpVerificationScreen(
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
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _phoneNumber != null && _phoneError == null;

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
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.close),
                    Text(
                      "Log In or Sign Up",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 24),
                  ],
                ),
              ),
              const Divider(thickness: 1),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome to MindSarthi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                          isValid ? "Continue" : "Enter your phone",
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

                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SvgPicture.asset(
                                'assets/icons/google.svg',
                                height: 20,
                              ),
                            ),
                            const Center(
                              child: Text(
                                "Continue with Google",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Apple Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(
                                Icons.apple,
                                color: Colors.black,
                                size: 25,
                              ),
                            ),
                            const Center(
                              child: Text(
                                "Continue with Apple",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  OutlineInputBorder _buildBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color:
            _phoneError != null
                ? Colors.red
                : focused
                ? (isValid ? Colors.green : const Color(0xFF222222))
                : (isValid ? Colors.green : const Color(0xFFBDBDBD)),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}
