import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/app_lock/app_lock_storage.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:shimmer/shimmer.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AppLockScreen({super.key, required this.onSuccess});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with TickerProviderStateMixin {
  String _enteredPin = '';
  String? _correctPin;
  bool _isAnimatingError = false;
  bool _isBioSupported = false;
  String _greeting = 'Welcome back';
  String _nickname = '';
  bool _loadingProfile = true;

  final LocalAuthentication _localAuth = LocalAuthentication();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initAnimations();
    _checkBiometricSupport();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        }
      });

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  Future<void> _loadData() async {
    _correctPin = await AppLockStorage.getPin();
    _determineGreeting();
    await _fetchUserProfile();
    
    // Automatically trigger biometric unlock if enabled
    final isBioEnabled = await AppLockStorage.isBiometricEnabled();
    if (isBioEnabled) {
      // Delay slightly for smooth transitions
      Timer(const Duration(milliseconds: 500), () {
        _authenticateBiometrics();
      });
    }
  }

  void _determineGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loadingProfile = false);
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nickname = doc.data()?['nickname'] ?? 'User';
          _loadingProfile = false;
        });
      } else {
        if (mounted) setState(() => _loadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _checkBiometricSupport() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    setState(() {
      _isBioSupported = canCheck && isSupported;
    });
  }

  Future<void> _authenticateBiometrics() async {
    if (!_isBioSupported) return;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock MindSarthi',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        HapticFeedback.mediumImpact();
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint('Biometric unlock error: $e');
    }
  }

  void _onKeyPress(String value) {
    if (_isAnimatingError) return;
    HapticFeedback.lightImpact();

    setState(() {
      if (value == 'back') {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else {
        if (_enteredPin.length < 4) {
          _enteredPin += value;
        }
      }
    });

    if (_enteredPin.length == 4) {
      Timer(const Duration(milliseconds: 200), () {
        _verifyPin();
      });
    }
  }

  void _verifyPin() async {
    if (_enteredPin == _correctPin) {
      HapticFeedback.mediumImpact();
      widget.onSuccess();
    } else {
      // PIN mismatch: Trigger shake
      HapticFeedback.heavyImpact();
      setState(() {
        _isAnimatingError = true;
      });
      await _shakeController.forward();
      setState(() {
        _enteredPin = '';
        _isAnimatingError = false;
      });
    }
  }

  void _handleForgotPasscode() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Passcode?'),
        content: const Text(
            'To reset your passcode, you must sign out of your current session and log in again with your password.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context); // Pop dialog
              try {
                await FirebaseAuth.instance.signOut();
                await AppLockStorage.clearAll();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppToast.error(context, 'Sign out failed', description: e.toString());
                }
              }
            },
            child: const Text('Sign Out & Reset'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final activeTeal = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // ── Breathing Profile Logo / Avatar ───────────────────
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                  CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: activeTeal.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: activeTeal.withOpacity(0.3), width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.heart_circle_fill,
                      color: activeTeal,
                      size: 54,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Personalized Greeting ──────────────────────────
            Column(
              children: [
                _loadingProfile
                    ? Shimmer.fromColors(
                        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
                        highlightColor: isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
                        child: Container(
                          width: 140,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    : Text(
                        _nickname.isNotEmpty ? 'Namaste, $_nickname' : _greeting,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                const SizedBox(height: 6),
                Text(
                  'Enter Passcode to Unlock',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ── Passcode Dots with Shake Animation ───────────────
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                double offset = 0.0;
                if (_shakeController.isAnimating) {
                  offset = (2.0 * (_shakeController.value * 5 * 3.14).hashCode.hashCode % 2 - 1) *
                      (1.0 - _shakeController.value) *
                      12.0;
                }
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: isFilled ? 18 : 14,
                        height: isFilled ? 18 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAnimatingError 
                              ? AppColors.error 
                              : (isFilled ? activeTeal : Colors.transparent),
                          border: Border.all(
                            color: _isAnimatingError
                                ? AppColors.error
                                : (isFilled ? activeTeal : textSecondary.withOpacity(0.4)),
                            width: 2.2,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const Spacer(flex: 2),

            // ── Numeric Keypad with Biometric Shortcut ──────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKeypadButton('1', textPrimary),
                      _buildKeypadButton('2', textPrimary),
                      _buildKeypadButton('3', textPrimary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKeypadButton('4', textPrimary),
                      _buildKeypadButton('5', textPrimary),
                      _buildKeypadButton('6', textPrimary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildKeypadButton('7', textPrimary),
                      _buildKeypadButton('8', textPrimary),
                      _buildKeypadButton('9', textPrimary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bottom Left: Fingerprint/Face ID icon (if supported)
                      _isBioSupported
                          ? InkWell(
                              onTap: _authenticateBiometrics,
                              borderRadius: BorderRadius.circular(36),
                              child: Ink(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: activeTeal.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fingerprint,
                                  color: activeTeal,
                                  size: 32,
                                ),
                              ),
                            )
                          : const SizedBox(width: 72, height: 72),
                      _buildKeypadButton('0', textPrimary),
                      _buildKeypadButton('back', textPrimary, isIcon: true),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── Forgot Passcode Option ──────────────────────────
            TextButton(
              onPressed: _handleForgotPasscode,
              child: Text(
                'Forgot Passcode?',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label, Color textColor, {bool isIcon = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? AppColors.darkSurface2 : Colors.teal.shade50.withOpacity(0.4);

    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(36),
      child: Ink(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: btnBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isIcon 
              ? Icon(
                  CupertinoIcons.delete_left_fill,
                  color: textColor.withOpacity(0.8),
                  size: 24,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
