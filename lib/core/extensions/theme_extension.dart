import 'package:flutter/material.dart';

import '../themes/theme_context.dart';



// Your new AppThemeExtension
extension AppThemeExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ThemeContext get themeContext => ThemeContext.of(this);
  Color get primaryColor => const Color(0xFFCCFF02);
  Color get primaryTextColor => themeContext.primaryTextColor;
  Color get subtitleTextColor => themeContext.subtitleTextColor;
  Color get inverseText => themeContext.tertiaryTextColor;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;

}