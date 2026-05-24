import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/widgets/rive_teddy_widget.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'otp_verification.dart';

class PersonalAuth extends ConsumerStatefulWidget {
  const PersonalAuth({super.key});

  @override
  ConsumerState<PersonalAuth> createState() => _PersonalAuthState();
}

class _PersonalAuthState extends ConsumerState<PersonalAuth>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isEmailValid = false;
  bool _isSending = false;

  // Rive controller
  RiveTeddyController? _teddyCtrl;

  // Focus node to track email field focus
  final FocusNode _emailFocusNode = FocusNode();

  // Fade animation for card entrance
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
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    // Listen to email field focus changes
    _emailFocusNode.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _emailFocusNode.dispose();
    _emailController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onEmailFocusChanged() {
    if (_emailFocusNode.hasFocus) {
      _teddyCtrl?.isChecking = true;
    } else {
      _teddyCtrl?.isChecking = false;
    }
  }

  void _checkEmailValidity(String value) {
    // Simple email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    _isEmailValid = emailRegex.hasMatch(value.trim());
    setState(() {});
  }

  void _onEmailChanged(String text) {
    // Update bear's eye tracking based on email length
    _teddyCtrl?.look = text.length * 1.5;
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isEmailValid) {
      _teddyCtrl?.triggerFail();
      AppToast.warning(
        context,
        'Enter a valid email',
        description: 'Please enter a valid email address.',
      );
      return;
    }

    // Unfocus to reset bear
    _emailFocusNode.unfocus();
    _teddyCtrl?.isChecking = false;

    setState(() => _isSending = true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/otp_p.json',
                height: 100,
                width: 100,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(
                      const ['**', 'Stroke 1'],
                      value: isDark ? Colors.white : const Color(0xFF1E1E2C),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sending Code…',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
      final authRepo = ref.read(authRepositoryProvider);
      final userId = await authRepo.sendEmailOtp(email);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _teddyCtrl?.triggerSuccess();
        AppToast.info(context, 'Verification Sent',
            description: 'Check your email inbox for the code.');

        // Small delay so user sees the bear celebrate, then navigate
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => OtpVerificationScreen(
                  email: email,
                  userId: userId,
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _teddyCtrl?.triggerFail();
        AppToast.error(context, 'Failed to send code',
            description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.loginWithGoogle();
      // Successful Google Sign-In redirect is handled natively or via deep link
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Google Sign-In Failed', description: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF0F4F8),
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
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
            ),
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
                          color: isDark ? AppColors.darkSurface : AppColors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
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
                            // ── Header badge ────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkPrimary.withValues(alpha: 0.15)
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Step 2 of 2',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ── Title ────────────────────────────────
                            Text(
                              'Welcome to MindSarthi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your email address to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Email field ──────────────────────────
                            TextField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(
                                  CupertinoIcons.mail,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                                border: _buildBorder(
                                    isDark ? AppColors.darkBorder : AppColors.border),
                                enabledBorder: _buildBorder(
                                    isDark ? AppColors.darkBorder : AppColors.border),
                                focusedBorder:
                                    _buildBorder(AppColors.primary, width: 1.8),
                              ),
                              onChanged: (text) {
                                _checkEmailValidity(text);
                                _onEmailChanged(text);
                              },
                            ),

                            // ── Validity indicator ───────────────────
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _isEmailValid
                                  ? Padding(
                                      padding:
                                          const EdgeInsets.only(top: 6, left: 4),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              CupertinoIcons.checkmark_circle_fill,
                                              color: AppColors.success,
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Valid email address',
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
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
                                        'Send Verification Code',
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
                                Expanded(
                                  child: Divider(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextHint
                                          : AppColors.textHint,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border),
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
                              isDark: isDark,
                              onPressed: _handleGoogleSignIn,
                            ),

                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),

                    // ── Privacy note ─────────────────────────────
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Text(
                        'Your data is private & encrypted 🔒',
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

  OutlineInputBorder _buildBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.isDark,
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
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.textPrimary,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: icon),
            Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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
