import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindsarthi/core/widgets/rive_teddy_widget.dart';

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

  RiveTeddyController? _teddyCtrl;
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onPhoneFocusChanged);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onPhoneFocusChanged);
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onPhoneFocusChanged() {
    if (_phoneFocusNode.hasFocus) {
      _teddyCtrl?.isChecking = true;
    } else {
      _teddyCtrl?.isChecking = false;
    }
  }

  void _onPhoneChanged(String number) {
    final length = number.replaceAll(RegExp(r'\D'), '').length;
    _teddyCtrl?.look = length * 5.0;
  }

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
      _teddyCtrl?.triggerFail();
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Phone number required'),
        description: const Text('Please enter a valid 10-digit phone number.'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    _phoneFocusNode.unfocus();
    _teddyCtrl?.isChecking = false;

    _dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.color(
                        const ['**', 'Stroke 1'],
                        value: isDark ? Colors.white : const Color(0xFF1E1E2C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sending OTP...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
    final horizontalPadding = size.width * 0.05;
    final cardWidth = size.width > 400 ? 380.0 : size.width * 0.9;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RiveTeddyWidget(
                  height: size.height * 0.28,
                  onControllerReady: (ctrl) {
                    _teddyCtrl = ctrl;
                  },
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? []
                          : const [
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
                    Text(
                      "Professional Login / Signup",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    Divider(thickness: 1, color: theme.dividerTheme.color),
                    const SizedBox(height: 10),
                    Text(
                      "Welcome to MindSarthi Pro",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.headlineSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 15),
                    IntlPhoneField(
                      focusNode: _phoneFocusNode,
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
                        labelText: 'Phone Number',
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
                        _onPhoneChanged(phone.number);
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
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Send OTP",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.dividerTheme.color)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "or",
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.dividerTheme.color)),
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
                      icon: Icon(
                        Icons.apple,
                        color: isDark ? Colors.white : Colors.black,
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
        ],
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
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: BorderSide(color: theme.colorScheme.outline),
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
                style: TextStyle(
                  color: theme.textTheme.labelLarge?.color,
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
    final theme = Theme.of(context);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _isPhoneValid
            ? AppColors.success
            : hasError
                ? AppColors.error
                : focused
                    ? theme.colorScheme.primary
                    : (theme.dividerTheme.color ?? const Color(0xFFBDBDBD)),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}
