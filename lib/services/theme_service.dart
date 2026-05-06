import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'theme_mode';


  static Future<ThemeMode> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_key) ?? 0;

    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    int value = 0;
    if (mode == ThemeMode.light) value = 1;
    if (mode == ThemeMode.dark) value = 2;

    await prefs.setInt(_key, value);
  }
}