import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindsarthi/core/widgets/rive_teddy_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/features/organizational_user/auth/org_otp_verification.dart';
import 'package:toastification/toastification.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';

class OrganizationalAuth extends ConsumerStatefulWidget {
  const OrganizationalAuth({super.key});

  @override
  ConsumerState<OrganizationalAuth> createState() => _OrganizationalAuthState();
}

class _OrganizationalAuthState extends ConsumerState<OrganizationalAuth> {
  final _emailController = TextEditingController();
  bool _isEmailValid = false;
  bool _dialogOpen = false;

  RiveTeddyController? _teddyCtrl;
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailFocusChanged() {
    if (_emailFocusNode.hasFocus) {
      _teddyCtrl?.isChecking = true;
    } else {
      _teddyCtrl?.isChecking = false;
    }
  }

  void _onEmailChanged(String text) {
    _teddyCtrl?.look = text.length * 1.5;
  }

  void _dismissDialog() {
    if (_dialogOpen && mounted) {
      _dialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _checkEmailValidity(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    _isEmailValid = emailRegex.hasMatch(value.trim());
    setState(() {});
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isEmailValid) {
      _teddyCtrl?.triggerFail();
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Email address required'),
        description: const Text('Please enter a valid email address.'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    _emailFocusNode.unfocus();
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
                  'Sending Verification Code...',
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
      final authRepo = ref.read(authRepositoryProvider);
      final userId = await authRepo.sendEmailOtp(email);
      
      _dismissDialog();
      _teddyCtrl?.triggerSuccess();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: email,
              userId: userId,
              isOrg: true,
            ),
          ),
        );
        toastification.show(
          context: context,
          type: ToastificationType.info,
          title: const Text('Code Sent'),
          description: const Text('Please check your email inbox.'),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      _dismissDialog();
      _teddyCtrl?.triggerFail();
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Verification Failed'),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.loginWithGoogle();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Google Sign-In Failed', description: e.toString());
      }
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
                            "Organizational Login / Signup",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          Divider(thickness: 1, color: theme.dividerTheme.color),
                          const SizedBox(height: 10),
                          Text(
                            "Welcome to MindSarthi Workplaces",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.headlineSmall?.color,
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Work Email Address',
                              prefixIcon: Icon(
                                Icons.work_outline_rounded,
                                color: theme.textTheme.bodyMedium?.color,
                                size: 20,
                              ),
                              border: _buildBorder(),
                              enabledBorder: _buildBorder(),
                              focusedBorder: _buildBorder(focused: true),
                            ),
                            onChanged: (text) {
                              _checkEmailValidity(text);
                              _onEmailChanged(text);
                            },
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _isEmailValid
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.check_circle_rounded,
                                            color: AppColors.success, size: 16),
                                        SizedBox(width: 6),
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
                                "Send Verification Code",
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
                            onPressed: _handleGoogleSignIn,
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

  OutlineInputBorder _buildBorder({bool focused = false}) {
    final theme = Theme.of(context);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _isEmailValid
            ? AppColors.success
            : focused
                ? theme.colorScheme.primary
                : (theme.dividerTheme.color ?? const Color(0xFFBDBDBD)),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}