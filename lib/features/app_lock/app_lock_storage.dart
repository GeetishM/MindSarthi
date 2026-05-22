import 'package:shared_preferences/shared_preferences.dart';

class AppLockStorage {
  static const _pinKey = 'user_pin';
  static const _isPinEnabledKey = 'is_pin_enabled';
  static const _isBiometricEnabledKey = 'is_biometric_enabled';
  static const _autoLockDurationKey = 'auto_lock_duration'; // Auto lock delay in seconds

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  static Future<void> setPinEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPinEnabledKey, value);
  }

  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPinEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isBiometricEnabledKey, value);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isBiometricEnabledKey) ?? false;
  }

  static Future<void> setAutoLockDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockDurationKey, seconds);
  }

  static Future<int> getAutoLockDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoLockDurationKey) ?? 0; // Default is 0 (Immediately)
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_isPinEnabledKey);
    await prefs.remove(_isBiometricEnabledKey);
    await prefs.remove(_autoLockDurationKey);
  }
}
