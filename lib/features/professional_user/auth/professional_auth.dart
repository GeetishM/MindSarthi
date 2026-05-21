import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/features/professional_user/auth/professional_otp_verification.dart';
import 'package:toastification/toastification.dart';

class ProfessionalAuth extends StatefulWidget {
  const ProfessionalAuth({super.key});

  @override
  State<ProfessionalAuth> createState() => _ProfessionalAuthState();
}

class _ProfessionalAuthState extends State<ProfessionalAuth> {
  final _auth = FirebaseAuth.instance;
  String? _phoneNumber;
  bool _isPhoneValid = false;
  bool _dialogOpen = false;
  int _enteredLength = 0;

  void _dismissDialog() {
    if (_dialogOpen && mounted) {
      _dialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _checkPhoneValidity(String? value) {
    if (value == null || value.isEmpty) {
      _isPhoneValid = false;
      _enteredLength = 0;
    } else {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      _isPhoneValid = digits.length == 10;
      _enteredLength = digits.length;
    }
    setState(() {});
  }

  Future<void> _sendOtp() async {
    if (_phoneNumber == null || !_isPhoneValid) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Phone number required'),
        description: const Text('Please enter a valid 10-digit phone number.'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    _dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/otp_pro.json',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Sending OTP...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: (cred) async {
          _dismissDialog();
          await _auth.signInWithCredential(cred);
        },
        verificationFailed: (e) {
          _dismissDialog();
          if (!mounted) return;
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('OTP Error'),
            description: Text(e.message ?? 'Unknown error'),
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
        codeSent: (verificationId, resendToken) {
          _dismissDialog();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: _phoneNumber!,
                verificationId: verificationId,
                isProfessional: true,
              ),
            ),
          );
          toastification.show(
            context: context,
            type: ToastificationType.info,
            title: const Text('OTP Sent'),
            description: const Text('Please check your SMS inbox.'),
            autoCloseDuration: const Duration(seconds: 4),
          );
        },
        // Do NOT pop here — dialog is already gone after codeSent
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      _dismissDialog();
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Verification Failed'),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 600;
    final horizontalPadding = size.width * 0.05;
    final cardWidth = size.width > 400 ? 380.0 : size.width * 0.9;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Professional Login / Signup",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome to MindSarthi Pro",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    IntlPhoneField(
                      invalidNumberMessage: _enteredLength > 0
                          ? 'Invalid Mobile Number                                   $_enteredLength/10'
                          : 'Invalid Mobile Number',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownTextStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      dropdownIconPosition: IconPosition.trailing,
                      dropdownIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        counterText: '',
                        border: _buildBorder(),
                        enabledBorder: _buildBorder(),
                        focusedBorder: _buildBorder(focused: true),
                        errorBorder: _buildBorder(hasError: true),
                        focusedErrorBorder: _buildBorder(focused: true, hasError: true),
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _phoneNumber = phone.completeNumber;
                        _checkPhoneValidity(phone.number);
                      },
                      validator: (_) => null,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isPhoneValid
                          ? Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle_rounded,
                                      color: AppColors.success, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Valid number',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.professional,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Send OTP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
                      icon: SvgPicture.asset(
                        'assets/icons/google.svg',
                        height: 20,
                      ),
                      text: "Continue with Google",
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                    _buildSocialButton(
                      icon: const Icon(
                        Icons.apple,
                        color: Colors.black,
                        size: 25,
                      ),
                      text: "Continue with Apple",
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

  OutlineInputBorder _buildBorder({bool focused = false, bool hasError = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _isPhoneValid
            ? AppColors.success
            : hasError
                ? AppColors.error
                : focused
                    ? AppColors.professional
                    : const Color(0xFFBDBDBD),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}
