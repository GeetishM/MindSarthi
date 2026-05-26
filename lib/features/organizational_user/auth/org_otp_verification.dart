import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/role_router.dart';
import 'package:mindsarthi/core/widgets/rive_teddy_widget.dart';
import 'package:pinput/pinput.dart';
import 'package:appwrite/appwrite.dart';
import 'package:toastification/toastification.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String userId;
  final bool isOrg;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
    this.isOrg = true,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  late String _currentUserId;
  String _enteredOtp = '';
  String? _error;
  bool _isVerifying = false;

  RiveTeddyController? _teddyCtrl;
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId;
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

  Future<_UserSessionResult> _verifyOtp(String otp) async {
    if (_isVerifying) return const _UserSessionResult(success: false);
    setState(() => _isVerifying = true);

    _otpFocusNode.unfocus();
    _teddyCtrl?.isHandsUp = false;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      // Verify OTP via Appwrite
      await authRepo.verifyEmailOtp(
        userId: _currentUserId,
        secretCode: otp,
      );

      final user = await authRepo.getCurrentUser();

      if (user != null) {
        // Set user in Riverpod AuthStateNotifier
        ref.read(authStateProvider.notifier).setUser(user);

        final databases = AppwriteService().databases;
        bool userDocExists = false;

        try {
          await databases.getDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.usersCollectionId,
            documentId: user.$id,
          );
          userDocExists = true;
        } on AppwriteException catch (e) {
          if (e.code != 404) {
            rethrow;
          }
        }

        // Cache the role locally in SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role_${user.$id}', 'org');
          // Also pre-cache name if we have it
          if (user.name.isNotEmpty) {
            await prefs.setString('profile_nickname_${user.$id}', user.name);
          } else {
            await prefs.remove('profile_nickname_${user.$id}');
          }
        } catch (_) {}

        if (!userDocExists) {
          try {
            await databases.createDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.usersCollectionId,
              documentId: user.$id,
              data: {
                'uid': user.$id,
                'email': widget.email,
                'userRole': 'org',
                'name': user.name.isEmpty ? 'Organizational User' : user.name,
                'joinedDate': DateTime.now().toIso8601String(),
              },
            );
          } catch (dbError) {
            debugPrint("Database profile creation failed but continuing: $dbError");
          }
        }

        _teddyCtrl?.triggerSuccess();

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: Text(userDocExists ? "Welcome back!" : "Account created successfully"),
            autoCloseDuration: const Duration(seconds: 2),
          );
        }

        await Future.delayed(const Duration(milliseconds: 1200));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleRouter()),
          );
        }
      }
      return const _UserSessionResult(success: true);
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
          title: const Text("Verification Failed"),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
      return const _UserSessionResult(success: false);
    }
  }

  void _resendOtp() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final newUserId = await authRepo.sendEmailOtp(widget.email);
      if (mounted) {
        setState(() {
          _currentUserId = newUserId;
        });
        toastification.show(
          context: context,
          type: ToastificationType.info,
          title: const Text("Code Resent"),
          description: const Text("Please check your email inbox for the new code."),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text("Resend Failed"),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = MediaQuery.of(context).size.width / 375;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = ThemePalette.forRole('org', isDark: isDark);

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
                                "Enter the verification code sent via Email",
                                style: TextStyle(
                                  fontSize: 14 * fontScale,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.email,
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

class _UserSessionResult {
  final bool success;
  const _UserSessionResult({required this.success});
}
