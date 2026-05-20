import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/role_router.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';

class OrgOtpVerification extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String orgName;

  const OrgOtpVerification({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.orgName,
  });

  @override
  State<OrgOtpVerification> createState() => _OrgOtpVerificationState();
}

class _OrgOtpVerificationState extends State<OrgOtpVerification> {
  String _enteredOtp = '';
  String? _error;
  bool _isVerifying = false;

  Future<void> _verifyOtp(String otp) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = authResult.user;

      if (user != null) {
        // Write to organizations collection
        final orgDoc = FirebaseFirestore.instance
            .collection('organizations')
            .doc(user.uid);
        final orgSnapshot = await orgDoc.get();

        if (!orgSnapshot.exists) {
          await orgDoc.set({
            'orgId': user.uid,
            'orgName': widget.orgName,
            'adminUid': user.uid,
            'phoneNumber': widget.phoneNumber,
            'plan': 'free',
            'createdAt': FieldValue.serverTimestamp(),
            'anonymousReporting': true,
            'mandatoryCheckin': false,
          });

          // Add admin as first member
          await FirebaseFirestore.instance
              .collection('org_members')
              .doc(user.uid)
              .collection('members')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'role': 'admin',
            'department': 'Management',
            'joinedAt': FieldValue.serverTimestamp(),
          });
        }

        // Write to unified users collection for RoleRouter
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'phoneNumber': widget.phoneNumber,
          'userRole': 'org',
          'orgName': widget.orgName,
        }, SetOptions(merge: true));

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: Text(orgSnapshot.exists ? 'Welcome back!' : 'Organization created'),
            autoCloseDuration: const Duration(seconds: 2),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleRouter()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Invalid OTP';
        _isVerifying = false;
      });
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('OTP Verification Failed'),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  void _resendOtp() {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      title: const Text('Resend OTP tapped'),
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verification Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the code sent to',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 28),
                Pinput(
                  length: 6,
                  onChanged: (val) => _enteredOtp = val,
                  onCompleted: (val) => _verifyOtp(val),
                  defaultPinTheme: PinTheme(
                    width: 50,
                    height: 56,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface2
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 50,
                    height: 56,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface2
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : () => _verifyOtp(_enteredOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkPrimary : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    "Didn't receive the code? Resend",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      fontWeight: FontWeight.w600,
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
}
