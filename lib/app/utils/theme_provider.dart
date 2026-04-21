import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    // Load theme asynchronously to avoid blocking startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTheme();
    });
  }

  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox('settingsBox');
      final savedTheme = box.get('themeMode', defaultValue: 'light');
      if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.light;
      }
    } catch (e) {
      print('Error loading theme: $e');
      // Keep default light theme
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