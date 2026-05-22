import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app-wide theme mode (light / dark) and active user role with persistence.
/// Wrap the app with ChangeNotifierProvider<ThemeProvider> in main.dart.
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'isDarkMode';
  static const _rolePrefKey = 'userRole';

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  String _currentRole = 'personal';
  String get currentRole => _currentRole;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    _currentRole = prefs.getString(_rolePrefKey) ?? 'personal';
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDark);
  }

  Future<void> setRole(String role) async {
    if (_currentRole != role) {
      _currentRole = role;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rolePrefKey, role);
    }
  }
}
