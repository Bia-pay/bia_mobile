import 'package:flutter/material.dart';

import 'theme_controller.dart';

abstract class ThemeContext {
  static const defaultButtonSize = Size(200, 43);

  static ThemeContext of(BuildContext? context) {
    final controller = ThemeController();
    if (context == null) {
      return controller.themeContext;
    }
    return Theme.of(context).brightness == Brightness.light
        ? controller.lightThemeContext
        : controller.darkThemeContext;
  }

  /// The brightness of the theme. Light or Dark
  abstract Brightness brightness;

  abstract BoxDecoration background;

  abstract BoxDecoration alternateBackground;

  abstract ColorScheme colorScheme;

  abstract Color titleTextColor;

  abstract Color kPrimary;

  abstract Color kSplash;

  abstract Color keyColor;

  abstract Color backgroundColor;

  abstract Color grayWhiteBg;

  abstract Color offWhiteBg;

  abstract Color kSecondary;

  abstract Color lightGray;
  
  abstract Color alternateTitleTextColor;

  abstract Color subtitleTextColor;

  abstract Color primaryTextColor;

  abstract Color secondaryTextColor;

  abstract Color promptHintTextColor;

  abstract Color promptUnfocusedColor;

  abstract Color promptFocusedColor;

  abstract Color promptBorderColor;

  abstract Color pinfieldTextColor;

  abstract Color tertiaryTextColor;

  abstract Color transparentColor;

  abstract Color camBg;

  abstract Color bodyTextColor;

  abstract Color errorTextColor;

  abstract Color disabledTextColor;

  abstract Color defaultBorderColor;

  abstract Color activeBorderColor;

  abstract Color disabledBorderColor;

  abstract Color errorBorderColor;

  abstract Color activeIconColor;

  abstract Color disabledIconColor;

  abstract Color disabledBackgroundColor;

  abstract Color secondaryBackgroundColor;

  abstract Color tertiaryBackgroundColor;

  // Solid Button
  abstract Color primarySolidButtonBackgroundColor;

  abstract Color primarySolidButtonHoverBackgroundColor;

  abstract Color primarySolidButtonHoverTextColor;

  abstract Color primarySolidButtonTextColor;

  abstract Color primarySolidButtonDisabledBackgroundColor;

  abstract Color primarySolidButtonDisabledTextColor;

  abstract Color secondarySolidButtonBackgroundColor;

  abstract Color secondarySolidButtonHoverBackgroundColor;

  abstract Color secondarySolidButtonHoverTextColor;

  abstract Color secondarySolidButtonTextColor;

  abstract Color secondarySolidButtonDisabledBackgroundColor;

  abstract Color secondarySolidButtonDisabledTextColor;

  abstract Color tertiarySolidButtonBackgroundColor;

  abstract Color tertiarySolidButtonHoverBackgroundColor;

  abstract Color tertiarySolidButtonHoverTextColor;

  abstract Color tertiarySolidButtonTextColor;

  abstract Color tertiarySolidButtonDisabledBackgroundColor;

  abstract Color tertiarySolidButtonDisabledTextColor;

  // Text Button
  abstract Color textButtonTextColor;

  abstract Color textButtonDisabledTextColor;

  // Outlined Button
  abstract Color primaryOutlinedButtonBackgroundColor;

  abstract double primaryOutlinedButtonBorderWidth;

  abstract Color primaryOutlinedButtonBorderColor;

  abstract Color primaryOutlinedButtonHoverBackgroundColor;

  abstract Color primaryOutlinedButtonTextColor;

  abstract Color primaryOutlinedButtonHoverTextColor;

  abstract Color primaryOutlinedButtonHoverBorderColor;

  abstract Color primaryOutlinedButtonDisabledBackgroundColor;

  abstract Color primaryOutlinedButtonDisabledTextColor;

  abstract Color primaryOutlinedButtonDisabledBorderColor;

  abstract Color secondaryOutlinedButtonBackgroundColor;

  abstract double secondaryOutlinedButtonBorderWidth;

  abstract Color secondaryOutlinedButtonBorderColor;

  abstract Color secondaryOutlinedButtonHoverBackgroundColor;

  abstract Color secondaryOutlinedButtonTextColor;

  abstract Color secondaryOutlinedButtonHoverTextColor;

  abstract Color secondaryOutlinedButtonHoverBorderColor;

  abstract Color secondaryOutlinedButtonDisabledBackgroundColor;

  abstract Color secondaryOutlinedButtonDisabledTextColor;

  abstract Color secondaryOutlinedButtonDisabledBorderColor;

  abstract Color tertiaryOutlinedButtonBackgroundColor;

  abstract double tertiaryOutlinedButtonBorderWidth;

  abstract Color tertiaryOutlinedButtonBorderColor;

  abstract Color tertiaryOutlinedButtonHoverBackgroundColor;

  abstract Color tertiaryOutlinedButtonTextColor;

  abstract Color tertiaryOutlinedButtonHoverTextColor;

  abstract Color tertiaryOutlinedButtonHoverBorderColor;

  abstract Color tertiaryOutlinedButtonDisabledBackgroundColor;

  abstract Color tertiaryOutlinedButtonDisabledTextColor;

  abstract Color tertiaryOutlinedButtonDisabledBorderColor;

  abstract Color switchActiveTrackColor;

  abstract Color switchActiveThumbColor;

  abstract Color switchActiveBorderColor;

  abstract double? switchActiveBorderWidth;

  abstract Color switchInactiveTrackColor;

  abstract Color switchInactiveThumbColor;

  abstract Color switchInactiveBorderColor;

  abstract double? switchInactiveBorderWidth;

  abstract Color switchDisabledTrackColor;

  abstract Color switchDisabledThumbColor;

  abstract Color switchDisabledBorderColor;

  abstract double? switchDisabledBorderWidth;

  // Checkbox
  abstract Color checkboxBorderColor;
  abstract Color unCheckboxBorderColor;

  abstract Color checkboxSelectedBackgroundColor;

  abstract Color checkboxUnselectedBackgroundColor;

  abstract Color checkboxDisabledBackgroundColor;

  abstract Color checkboxDisabledBorderColor;

  // Radio Button
  abstract Color radioSelectedColor;

  abstract Color radioDisabledColor;

  // Bottom App Bar
  abstract Color bottomAppBarTextColor;

  // App Bar
  abstract Color appBarActionColor;
  abstract Color appBarDisabledActionColor;

  // Floating Action Button
  abstract Color activeFloatingActionButtonBackgroundColor;

  abstract Color activeFloatingActionButtonForegroundColor;

  abstract Color inactiveFloatingActionButtonBackgroundColor;

  abstract Color inactiveFloatingActionButtonForegroundColor;

  bool get isLight => brightness == Brightness.light;

  // Padding
  abstract EdgeInsets defaultScaffoldPadding;

  // Banner
  abstract Color successBannerBorderColor;
  abstract Color successBannerBackgroundColor;
  abstract Color successBannerTextColor;

  abstract Color errorBannerBorderColor;
  abstract Color errorBannerBackgroundColor;
  abstract Color errorBannerTextColor;

  abstract Color infoBannerBorderColor;
  abstract Color infoBannerBackgroundColor;
  abstract Color infoBannerTextColor;

  abstract Color warningBannerBorderColor;
  abstract Color warningBannerBackgroundColor;
  abstract Color warningBannerTextColor;

  abstract Color dividerColor;

  abstract Color settingsDividerColor;

  // Bottom Nav
  abstract Color bottomNavBackgroundColor;
  abstract Color inactiveBottomNavItemColor;
  abstract Color activeBottomNavItemColor;

  // TabBar
  abstract Color tabBarInactiveItemColor;
  abstract Color tabBarActiveItemColor;
  abstract Color tabBarIndicatorColor;
  abstract Color tabBarBorderColor;

  // Input
  abstract Color inputBackgroundColor;

  // Drop down
  abstract Color dropdownBackgroundColor;
  abstract Color dropdownSelectedItemBackgroundColor;
  abstract Color dropdownTextColor;

  //Container
  abstract Color containerBoxColor;
  abstract List<BoxShadow> containerBoxShadow;
  abstract List<BoxShadow> addBoxShadow;
  abstract BoxDecoration tabBoxDecoration;
  abstract BoxDecoration containerDecoration;
  abstract BoxDecoration selectedTabBoxDecoration;
  abstract BoxDecoration blueBoxDecoration;

  
  
  abstract BoxDecoration userChatBubbleDecoration;
  abstract Color userChatBubbleTextColor;
  abstract Color agentChatBubbleTextColor;


  
}
