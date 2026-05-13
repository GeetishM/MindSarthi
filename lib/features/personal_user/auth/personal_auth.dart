import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'otp_verification.dart';

class PersonalAuth extends StatefulWidget {
  const PersonalAuth({super.key});

  @override
  State<PersonalAuth> createState() => _PersonalAuthState();
}

class _PersonalAuthState extends State<PersonalAuth>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  String? _phoneNumber;
  bool _isPhoneValid = false;
  bool _isSending = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
      AppToast.warning(
        context,
        'Enter a valid phone number',
        description: 'Please enter a 10-digit number.',
      );
      return;
    }

    setState(() => _isSending = true);

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/otp.json',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sending OTP…',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
          if (mounted) Navigator.pop(context);
        },
        verificationFailed: (e) {
          if (mounted) {
            Navigator.pop(context);
            AppToast.error(context, 'OTP Error',
                description: e.message ?? 'Unknown error');
          }
        },
        codeSent: (verificationId, _) {
          if (mounted) {
            Navigator.pop(context);
            AppToast.info(context, 'OTP Sent',
                description: 'Check your SMS inbox.');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  phoneNumber: _phoneNumber!,
                  verificationId: verificationId,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {
          if (mounted) Navigator.pop(context);
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppToast.error(context, 'Verification Failed',
            description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: 24,
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Card ─────────────────────────────────────
                  Container(
                    width: size.width > 420 ? 400.0 : double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Log In or Sign Up',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Title ────────────────────────────────
                        const Text(
                          'Welcome to MindSarthi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your phone number to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Phone field ──────────────────────────
                        IntlPhoneField(
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
                            labelStyle: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            counterText: '',
                            border: _buildBorder(AppColors.border),
                            enabledBorder: _buildBorder(AppColors.border),
                            focusedBorder: _buildBorder(AppColors.primary,
                                width: 1.8),
                          ),
                          initialCountryCode: 'IN',
                          onChanged: (phone) {
                            _phoneNumber = phone.completeNumber;
                            _checkPhoneValidity(phone.number);
                          },
                          // Valid tick indicator
                          validator: (_) => null,
                        ),

                        // ── Validity indicator ───────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _isPhoneValid
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6, left: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.success, size: 16),
                                      const SizedBox(width: 6),
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

                        // ── Send OTP button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _sendOtp,
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Send OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ── Divider ──────────────────────────────
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.border),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.border),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // ── Social buttons ───────────────────────
                        _SocialButton(
                          icon: SvgPicture.asset(
                            'assets/icons/google.svg',
                            height: 22,
                          ),
                          label: 'Continue with Google',
                          onPressed: () {},
                        ),

                        const SizedBox(height: 10),

                        _SocialButton(
                          icon: const Icon(
                            Icons.apple,
                            color: AppColors.textPrimary,
                            size: 26,
                          ),
                          label: 'Continue with Apple',
                          onPressed: () {},
                        ),

                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Privacy note ─────────────────────────────
                  Text(
                    'Your data is private & encrypted 🔒',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

// ─── Social login button ────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: AppColors.textPrimary,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: icon),
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
