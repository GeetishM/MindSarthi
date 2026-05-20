import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/features/organizational_user/auth/org_otp_verification.dart';
import 'package:toastification/toastification.dart';

class OrganizationalAuth extends StatefulWidget {
  const OrganizationalAuth({super.key});

  @override
  State<OrganizationalAuth> createState() => _OrganizationalAuthState();
}

class _OrganizationalAuthState extends State<OrganizationalAuth> {
  final _auth = FirebaseAuth.instance;
  String? _phoneNumber;
  bool _isPhoneValid = false;
  final _orgNameController = TextEditingController();

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  void _checkPhoneValidity(String? value) {
    if (value == null || value.isEmpty) {
      _isPhoneValid = false;
    } else {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      _isPhoneValid = digits.length == 10;
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

    if (_orgNameController.text.trim().isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Organization name required'),
        description: const Text('Please enter your organization name.'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/otp.json',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                'Sending OTP...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
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
          await _auth.signInWithCredential(cred);
          if (context.mounted) Navigator.pop(context);
        },
        verificationFailed: (e) {
          Navigator.pop(context);
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('OTP Error'),
            description: Text(e.message ?? 'Unknown error'),
            autoCloseDuration: const Duration(seconds: 3),
          );
        },
        codeSent: (verificationId, resendToken) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrgOtpVerification(
                phoneNumber: _phoneNumber!,
                verificationId: verificationId,
                orgName: _orgNameController.text.trim(),
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
        codeAutoRetrievalTimeout: (_) {
          Navigator.pop(context);
        },
      );
    } catch (e) {
      Navigator.pop(context);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 400 ? 380.0 : size.width * 0.9;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.accentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Organization Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Access workplace wellness tools\n& team programmes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Org name field
                    TextField(
                      controller: _orgNameController,
                      decoration: InputDecoration(
                        labelText: 'Organization Name',
                        prefixIcon: Icon(
                          Icons.domain_rounded,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: 'Admin Phone Number',
                        prefixIcon: null,
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _phoneNumber = phone.completeNumber;
                        _checkPhoneValidity(phone.number);
                      },
                    ),
                    const SizedBox(height: 20),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? AppColors.darkPrimary : AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Send OTP',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}