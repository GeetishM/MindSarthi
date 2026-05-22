import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/app_lock/app_lock_screen.dart';
import 'package:mindsarthi/features/app_lock/app_lock_storage.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isPinEnabled = false;
  bool _isUnlocked = true;
  bool _isLoading = true;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPinStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPinStatus() async {
    try {
      final enabled = await AppLockStorage.isPinEnabled();
      final pin = await AppLockStorage.getPin();
      final pinConfigured = enabled && pin != null;

      if (mounted) {
        setState(() {
          _isPinEnabled = pinConfigured;
          // If app lock is enabled, we start locked on fresh app startup.
          _isUnlocked = !pinConfigured;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AppLockWrapper error loading status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Dynamically check storage to ensure we catch changes made in settings
    final enabled = await AppLockStorage.isPinEnabled();
    final pin = await AppLockStorage.getPin();
    final pinConfigured = enabled && pin != null;

    if (mounted) {
      setState(() {
        _isPinEnabled = pinConfigured;
      });
    }

    if (!pinConfigured) {
      // If PIN is disabled or not set, ensure we stay unlocked
      if (mounted && !_isUnlocked) {
        setState(() {
          _isUnlocked = true;
        });
      }
      return;
    }

    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final now = DateTime.now();
        final diff = now.difference(_backgroundTime!).inSeconds;
        final timeout = await AppLockStorage.getAutoLockDuration();

        if (diff >= timeout) {
          if (mounted) {
            setState(() {
              _isUnlocked = false;
            });
          }
        }
        _backgroundTime = null;
      } else {
        // Fallback: if we resumed but didn't catch the pause event, or
        // we want to be safe, we can enforce a lock if we were previously locked.
        // But normally _backgroundTime handles it.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_isPinEnabled && !_isUnlocked) {
      return AppLockScreen(
        onSuccess: () {
          setState(() {
            _isUnlocked = true;
          });
        },
      );
    }

    return widget.child;
  }
}
