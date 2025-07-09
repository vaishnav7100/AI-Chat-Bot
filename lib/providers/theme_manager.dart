import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadTheme();
  }
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
        saveTheme();
        notifyListeners();
  }

  void _loadTheme() async {
    final pref = await SharedPreferences.getInstance();
    final themeString = pref.getString(_themeKey);
    if (themeString != null) {
      _themeMode = themeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  void saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
