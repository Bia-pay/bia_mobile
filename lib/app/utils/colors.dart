
import 'package:flutter/material.dart';

/// 🌈 PRIMARY BRAND COLORS
const primaryColor = Color(0xFF26B4DF);
const secondaryColor = Color(0xFFE5FBFF);
const accentColor = Color(0xFF0C284E);
const whiteBackground = Color(0xFFFFFFFF);
const lightgray = Color(0xFFF5F5F5);

/// 🌤️ LIGHT THEME COLORS
const lightBackground = Color(0xFFFFFFFF);
const offWhiteBackground = Color(0xFFF6F6F6);
const lightSurface = Color(0xFFF9FAFB);
const lightText = Color(0xFF0C284E);
const lightSecondaryText = Color(0xFF475467);
const lightBorderColor = Color(0xFFEAECF0);
const borderColor = Color(0xFFA9AAAC);
const disabledBorderColor = Color(0xFFB6B7C3);
const disabledTextColor = Color(0xFFB6B7C3);
const checkboxBorderColor = Color(0xFF8F91A1);
const keyAColor = Color(0x26A4A9AE);
/// ⚪ Off-White Color
const offWhite = Color(0xFFFFFFFF);
/// ⚠️ ALERT / ERROR RED
///
const errorColor = Color(0xFFEF4444); // bright red
/// ✅ SUCCESS GREEN
const successColor = Color(0xFF22C55E); // main green for success messages, icons
const successLight = Color(0xFFD1FAE5); // light green background for containers, badges,
const errorLight = Color(0xFFFEE2E2); // light red background for icons, containers, etc.
/// 🌑 DARK THEME COLORS
const darkBackground = Color(0xFF0B0B0B);
const darkSurface = Color(0xFF1A1A1A);
const darkText = Color(0xFFF9FAFB);
const darkSecondaryText = Color(0xFFD0D5DD);
const darkBorderColor = Color(0xFF2E2E2E);

/// ⚙️ SHARED NEUTRALS
const Color kGray = Color(0xFF757575);

/// ---------------- LIGHT THEME ----------------
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: lightBackground,
    foregroundColor: lightText,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: lightText, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: lightText),
    displaySmall: TextStyle(color: lightText),
    headlineLarge: TextStyle(color: lightText),
    headlineMedium: TextStyle(color: lightText),
    headlineSmall: TextStyle(color: lightText),
    titleLarge: TextStyle(color: lightText, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: lightText, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: lightText),
    bodyLarge: TextStyle(color: lightText, fontSize: 16),
    bodyMedium: TextStyle(color: lightSecondaryText, fontSize: 14),
    bodySmall: TextStyle(color: lightSecondaryText, fontSize: 12),
    labelLarge: TextStyle(color: lightText, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: lightSecondaryText),
  ),
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: accentColor,
    surface: lightSurface,
    background: lightBackground,
    onBackground: lightText,
    onSurface: lightText,
  ),
  dividerColor: lightBorderColor,
  iconTheme: const IconThemeData(color: lightText),
);

/// ---------------- DARK THEME ----------------
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkBackground,
    foregroundColor: darkText,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: darkText),
    displaySmall: TextStyle(color: darkText),
    headlineLarge: TextStyle(color: darkText),
    headlineMedium: TextStyle(color: darkText),
    headlineSmall: TextStyle(color: darkText),
    titleLarge: TextStyle(color: darkText, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: darkText, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: darkText),
    bodyLarge: TextStyle(color: darkText, fontSize: 16),
    bodyMedium: TextStyle(color: darkSecondaryText, fontSize: 14),
    bodySmall: TextStyle(color: darkSecondaryText, fontSize: 12),
    labelLarge: TextStyle(color: darkText, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: darkSecondaryText),
  ),
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: accentColor,
    surface: darkSurface,
    background: darkBackground,
    onBackground: darkText,
    onSurface: darkText,
  ),
  dividerColor: darkBorderColor,
  iconTheme: const IconThemeData(color: darkText),
);
