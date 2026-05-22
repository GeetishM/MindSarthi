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
  int _enteredLength = 0;

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
      builder: (context) {
        final dialogTheme = Theme.of(context);
        return Dialog(
          backgroundColor: dialogTheme.cardTheme.color ?? dialogTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/otp_org.json',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Sending OTP...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dialogTheme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 400 ? 380.0 : size.width * 0.9;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textTheme.bodyLarge?.color,
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
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
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
                        color: theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Organization Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Access workplace wellness tools\n& team programmes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
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
                          color: theme.hintColor,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.8,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),

                    IntlPhoneField(
                      invalidNumberMessage: _enteredLength > 0
                          ? 'Invalid Mobile Number                                   $_enteredLength/10'
                          : 'Invalid Mobile Number',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownTextStyle: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                      ),
                      dropdownIconPosition: IconPosition.trailing,
                      dropdownIcon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 20,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Admin Phone Number',
                        counterText: '',
                        border: _buildBorder(theme: theme),
                        enabledBorder: _buildBorder(theme: theme),
                        focusedBorder: _buildBorder(focused: true, theme: theme),
                        errorBorder: _buildBorder(hasError: true, theme: theme),
                        focusedErrorBorder: _buildBorder(focused: true, hasError: true, theme: theme),
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
                          backgroundColor: theme.colorScheme.primary,
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

  OutlineInputBorder _buildBorder({bool focused = false, bool hasError = false, required ThemeData theme}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _isPhoneValid
            ? AppColors.success
            : hasError
                ? AppColors.error
                : focused
                    ? theme.colorScheme.primary
                    : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant),
        width: focused ? 1.8 : 1.0,
      ),
    );
  }
}