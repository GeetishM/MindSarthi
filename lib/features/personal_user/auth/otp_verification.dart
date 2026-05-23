import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/widgets/role_router.dart';
import 'package:mindsarthi/core/widgets/rive_teddy_widget.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  String _enteredOtp = '';
  String? _error;
  bool _isVerifying = false;

  // Rive controller
  RiveTeddyController? _teddyCtrl;

  // Focus node to track OTP field focus
  final FocusNode _otpFocusNode = FocusNode();

  // Entrance animation
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    // Listen to OTP field focus changes → bear covers eyes
    _otpFocusNode.addListener(_onOtpFocusChanged);
  }

  @override
  void dispose() {
    _otpFocusNode.removeListener(_onOtpFocusChanged);
    _otpFocusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onOtpFocusChanged() {
    if (_otpFocusNode.hasFocus) {
      // Bear covers its eyes when OTP field is focused 🙈
      _teddyCtrl?.isHandsUp = true;
    } else {
      _teddyCtrl?.isHandsUp = false;
    }
  }

  Future<void> _verifyOtp(String otp) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    // Unfocus to drop the bear's hands
    _otpFocusNode.unfocus();
    _teddyCtrl?.isHandsUp = false;

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = authResult.user;

      if (user != null) {
        final doc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await doc.get();

        if (!snapshot.exists) {
          await doc.set({
            'uid': user.uid,
            'phoneNumber': widget.phoneNumber,
            'userRole': 'personal',
          });
        }

        // Bear celebrates! 🎉
        _teddyCtrl?.triggerSuccess();

        if (mounted) {
          AppToast.success(context, 'Verified!',
              description: snapshot.exists
                  ? 'Welcome back!'
                  : 'Account created successfully.');

          // Delay so user sees the bear celebrate, then navigate
          await Future.delayed(const Duration(milliseconds: 1200));

          if (mounted) {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (_) => const RoleRouter()),
            );
          }
        }
      }
    } catch (e) {
      // Bear looks sad 😢
      _teddyCtrl?.triggerFail();

      setState(() {
        _error = 'Invalid OTP';
        _isVerifying = false;
      });

      if (mounted) {
        AppToast.error(context, 'OTP Verification Failed',
            description: 'Please check the code and try again.');
      }
    }
  }

  void _resendOtp() {
    AppToast.info(context, 'Resending OTP…',
        description: 'Please wait for the new code.');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pinput theme
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: isDark
            ? AppColors.darkPrimary.withValues(alpha: 0.1)
            : AppColors.primaryLight,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.error, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 22),
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Rive Teddy Bear ──────────────────────────
                    RiveTeddyWidget(
                      height: size.height * 0.28,
                      onControllerReady: (ctrl) {
                        _teddyCtrl = ctrl;
                      },
                    ),

                    // Overlap the card slightly with the bear
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: Container(
                        width: size.width > 420 ? 400.0 : double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Icon badge ────────────────────────
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkPrimary
                                        .withValues(alpha: 0.15)
                                    : AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.lock_shield_fill,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary,
                                size: 22,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Title ─────────────────────────────
                            Text(
                              'Verification Code',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the 6-digit code sent to',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.phoneNumber,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── OTP Input (Pinput) ────────────────
                            Pinput(
                              length: 6,
                              focusNode: _otpFocusNode,
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: focusedPinTheme,
                              submittedPinTheme: submittedPinTheme,
                              errorPinTheme: errorPinTheme,
                              onChanged: (value) {
                                _enteredOtp = value;
                                // Subtle eye tracking before hands come up
                                if (!_otpFocusNode.hasFocus) {
                                  _teddyCtrl?.look =
                                      value.length * 8.0;
                                }
                              },
                              onCompleted: (value) {
                                if (!_isVerifying) {
                                  _verifyOtp(value);
                                }
                              },
                            ),

                            // ── Error message ─────────────────────
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons
                                          .exclamationmark_circle_fill,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // ── Verify button ─────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isVerifying
                                    ? null
                                    : () => _verifyOtp(_enteredOtp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: AppColors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Verify & Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Resend ────────────────────────────
                            TextButton(
                              onPressed: _resendOtp,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: "Didn't receive code? "),
                                    TextSpan(
                                      text: 'Resend', 
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Security note ────────────────────────────
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Text(
                        'Code expires in 2 minutes ⏱️',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                      ),
                    ),
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
