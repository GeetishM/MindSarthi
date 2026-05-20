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
  bool _dialogOpen = false;

  void _dismissDialog() {
    if (_dialogOpen && mounted) {
      _dialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

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

    _dialogOpen = true;
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
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkOrg : AppColors.org,
                            width: 1.8,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    IntlPhoneField(
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownTextStyle: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      dropdownIconPosition: IconPosition.trailing,
                      dropdownIcon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 20,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Admin Phone Number',
                        counterText: '',
                        border: _buildBorder(isDark: isDark),
                        enabledBorder: _buildBorder(isDark: isDark),
                        focusedBorder: _buildBorder(focused: true, isDark: isDark),
                        errorBorder: _buildBorder(hasError: true, isDark: isDark),
                        focusedErrorBorder: _buildBorder(focused: true, hasError: true, isDark: isDark),
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
                    const SizedBox(height: 20),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? AppColors.darkOrg : AppColors.org,
                          foregroundColor: Colors.white,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
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

  OutlineInputBorder _buildBorder({bool focused = false, bool hasError = false, required bool isDark}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _isPhoneValid
            ? AppColors.success
            : hasError
                ? AppColors.error
                : focused
                    ? (isDark ? AppColors.darkOrg : AppColors.org)
                    : (isDark ? AppColors.darkBorder : AppColors.border),
        width: focused ? 1.8 : 1.0,
      ),
    );
  }
}