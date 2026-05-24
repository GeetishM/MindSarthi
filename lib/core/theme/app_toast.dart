import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'app_theme.dart';

/// AppToast — unified toast notification helper for MindSarthi.
/// Use this everywhere instead of calling toastification.show() directly.
///
/// Usage:
///   AppToast.success(context, 'Profile saved!');
///   AppToast.error(context, 'Something went wrong', description: e.toString());
///   AppToast.warning(context, 'Please fill all fields');
///   AppToast.info(context, 'OTP sent to your phone');

class AppToast {
  AppToast._();

  static void success(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      title: title,
      description: description,
      type: ToastificationType.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      title: title,
      description: description,
      type: ToastificationType.error,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      title: title,
      description: description,
      type: ToastificationType.warning,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String title, {
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      title: title,
      description: description,
      type: ToastificationType.info,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String title,
    String? description,
    required ToastificationType type,
    required Duration duration,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      description: description != null
          ? Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      autoCloseDuration: duration,
      showProgressBar: false,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
      primaryColor: _colorForType(type),
      backgroundColor: AppColors.white,
    );
  }

  static Color _colorForType(ToastificationType type) {
    switch (type) {
      case ToastificationType.success:
        return AppColors.success;
      case ToastificationType.error:
        return AppColors.error;
      case ToastificationType.warning:
        return AppColors.warning;
      case ToastificationType.info:
      default:
        return AppColors.primary;
    }
  }

  static void showUndo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha:  0.3),
            width: 1,
          ),
        ),
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        action: SnackBarAction(
          label: 'Undo',
          textColor: theme.colorScheme.primary,
          onPressed: onUndo,
        ),
      ),
    );
  }
}

