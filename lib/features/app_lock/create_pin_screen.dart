import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/app_lock/app_lock_storage.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPin = '';
  int _step = 0; // 0 = Enter Pin, 1 = Confirm Pin
  bool _isAnimatingError = false;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
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
      Timer(const Duration(milliseconds: 250), () {
        _validatePin();
      });
    }
  }

  void _validatePin() async {
    if (_step == 0) {
      // Move to confirm step
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _step = 1;
      });
    } else {
      // Confirm step
      if (_enteredPin == _firstPin) {
        // PINs match! Save and exit.
        await AppLockStorage.setPin(_enteredPin);
        await AppLockStorage.setPinEnabled(true);
        if (mounted) {
          AppToast.success(context, 'Passcode set successfully');
          Navigator.pop(context, true);
        }
      } else {
        // PIN mismatch! Shake and reset.
        HapticFeedback.heavyImpact();
        setState(() {
          _isAnimatingError = true;
        });
        await _shakeController.forward();
        setState(() {
          _enteredPin = '';
          _firstPin = '';
          _step = 0;
          _isAnimatingError = false;
        });
        if (mounted) {
          AppToast.error(
            context,
            'PIN Mismatch',
            description: 'Passcodes do not match. Please start over.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final activeTeal = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: textPrimary,
            size: 26,
          ),
          onPressed: () {
            if (_step == 1) {
              setState(() {
                _step = 0;
                _enteredPin = '';
                _firstPin = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // ── Step Title and Subtitle ─────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey<int>(_step),
                children: [
                  Text(
                    _step == 0 ? 'Create a Passcode' : 'Confirm Passcode',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 0 
                        ? 'Choose a secure 4-digit PIN'
                        : 'Re-enter your passcode to verify',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── PIN Dot Indicators with Shake Animation ─────────
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                // Compute visual offset based on horizontal shake animation values
                double offset = 0.0;
                if (_shakeController.isAnimating) {
                  offset = (1.0 - _shakeController.value) *
                      24.0 *
                      (1.0 - _shakeController.value) *
                      (1.0 - _shakeController.value) *
                      (_shakeController.value * 20.0 * 3.14).hashCode.toDouble();
                  // A simple shake mathematics:
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
                                : (isFilled ? activeTeal : textSecondary.withValues(alpha:  0.4)),
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

            // ── Custom iOS-Style Numeric Keypad ─────────────────
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
                      // Bottom left: empty spacer or cancel button
                      const SizedBox(width: 72, height: 72),
                      _buildKeypadButton('0', textPrimary),
                      _buildKeypadButton('back', textPrimary, isIcon: true),
                    ],
                  ),
                ],
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
    final btnBg = isDark ? AppColors.darkSurface2 : Colors.teal.shade50.withValues(alpha:  0.4);

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
                  color: textColor.withValues(alpha:  0.8),
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
