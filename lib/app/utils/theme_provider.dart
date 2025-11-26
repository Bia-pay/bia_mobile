import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox('settingsBox');
    final savedTheme = box.get('themeMode', defaultValue: 'light');
    if (savedTheme == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    final box = await Hive.openBox('settingsBox');
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await box.put('themeMode', 'dark');
    } else {
      state = ThemeMode.light;
      await box.put('themeMode', 'light');
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final box = await Hive.openBox('settingsBox');
    state = mode;
    await box.put('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
  }
}