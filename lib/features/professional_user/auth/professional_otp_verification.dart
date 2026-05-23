import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/role_router.dart';
import 'package:mindsarthi/core/widgets/rive_teddy_widget.dart';
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

  RiveTeddyController? _teddyCtrl;
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onOtpFocusChanged);
  }

  @override
  void dispose() {
    _otpFocusNode.removeListener(_onOtpFocusChanged);
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onOtpFocusChanged() {
    if (_otpFocusNode.hasFocus) {
      _teddyCtrl?.isHandsUp = true;
    } else {
      _teddyCtrl?.isHandsUp = false;
    }
  }

  Future<void> _verifyOtp(String otp) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    _otpFocusNode.unfocus();
    _teddyCtrl?.isHandsUp = false;

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

          // Also write to unified users collection for RoleRouter
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'phoneNumber': widget.phoneNumber,
            'userRole': 'professional',
          }, SetOptions(merge: true));

          if (mounted) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: const Text("New user created"),
              autoCloseDuration: const Duration(seconds: 2),
            );
          }
        } else {
          if (mounted) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: const Text("Welcome back!"),
              autoCloseDuration: const Duration(seconds: 2),
            );
          }
        }

        _teddyCtrl?.triggerSuccess();
        await Future.delayed(const Duration(milliseconds: 1200));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleRouter()),
          );
        }
      }
    } catch (e) {
      _teddyCtrl?.triggerFail();
      setState(() {
        _error = 'Invalid OTP';
        _isVerifying = false;
      });
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text("OTP Verification Failed"),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = ThemePalette.forRole('professional', isDark: isDark);

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
      body: LayoutBuilder(
        builder: (_, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RiveTeddyWidget(
                        height: MediaQuery.of(context).size.height * 0.28,
                        onControllerReady: (ctrl) {
                          _teddyCtrl = ctrl;
                        },
                      ),
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          width: 400,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Verification Required",
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Enter the verification code sent via SMS",
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.phoneNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16 * fontScale,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Pinput(
                          length: 6,
                          focusNode: _otpFocusNode,
                          onChanged: (val) {
                            _enteredOtp = val;
                            if (!_otpFocusNode.hasFocus) {
                              _teddyCtrl?.look = val.length * 8.0;
                            }
                          },
                          onCompleted: (val) => _verifyOtp(val),
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 56,
                            textStyle: TextStyle(
                              fontSize: 20 * fontScale,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.primary,
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _verifyOtp(_enteredOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 16 * fontScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _resendOtp,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13 * fontScale,
                                color: palette.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: "Didn't receive code? "),
                                TextSpan(
                                  text: 'Resend',
                                  style: TextStyle(
                                    color: palette.primary,
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
            ],
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
