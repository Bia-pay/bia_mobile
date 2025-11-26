
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';

import '../theme_context.dart';
import 'light_theme_colors.dart';

class LightTheme extends ThemeContext {
  @override
  Brightness brightness = Brightness.light;

  @override
  ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: LightThemeColors.primaryColor,
  );

  @override
  Color kPrimary = LightThemeColors.primaryColor;


  @override
  Color keyColor = LightThemeColors.key;

  @override
  Color kSplash = LightThemeColors.splashColor;

  @override
  Color kSecondary = LightThemeColors.secondaryColor;

  @override
  Color backgroundColor = LightThemeColors.offWhite;

  @override
  BoxDecoration background = const BoxDecoration(
    color: LightThemeColors.whiteColor,
  );

  @override
  BoxDecoration alternateBackground = const BoxDecoration(
    color: LightThemeColors.whiteColor,
  );

  @override
  Color titleTextColor = LightThemeColors.black900;

  @override
  Color alternateTitleTextColor = LightThemeColors.whiteColor;

  @override
  Color subtitleTextColor = LightThemeColors.grey700;

  @override
  Color primaryTextColor = LightThemeColors.black900;

  @override
  Color offWhiteBg = LightThemeColors.offWhite;

  @override
  Color grayWhiteBg = LightThemeColors.grayWhite;

  @override
  Color promptHintTextColor = LightThemeColors.grey500;

  @override
  Color promptUnfocusedColor = LightThemeColors.grey50;

  @override
  Color promptFocusedColor = LightThemeColors.whiteColor;

  @override
  Color promptBorderColor = LightThemeColors.grey100;

  @override
  Color secondaryTextColor = LightThemeColors.black600;

  @override
  Color tertiaryTextColor = LightThemeColors.whiteColor;

  @override
  Color bodyTextColor = LightThemeColors.grey200;

  @override
  Color pinfieldTextColor = LightThemeColors.lightGrey;

  @override
  Color transparentColor = LightThemeColors.transparent;

  @override
  Color errorTextColor = LightThemeColors.redColor;

  @override
  Color camBg = LightThemeColors.camBgColor;

  @override
  Color activeBorderColor = LightThemeColors.grey900;

  @override
  Color defaultBorderColor = LightThemeColors.grey300;

  @override
  Color disabledBorderColor = LightThemeColors.grey100;

  @override
  Color errorBorderColor = LightThemeColors.redColor;

  @override
  Color disabledTextColor = LightThemeColors.grey300;

  @override
  Color activeIconColor = LightThemeColors.primaryColor;

  @override
  Color disabledIconColor = LightThemeColors.grey300;

  @override
  Color disabledBackgroundColor = LightThemeColors.whiteColor;

  @override
  Color secondaryBackgroundColor = LightThemeColors.primaryColor;

  @override
  Color tertiaryBackgroundColor = LightThemeColors.whiteColor;

  // Solid Button
  @override
  Color primarySolidButtonBackgroundColor = LightThemeColors.primaryColor;

  @override
  Color primarySolidButtonHoverBackgroundColor = LightThemeColors.primaryColor;

  @override
  Color primarySolidButtonHoverTextColor = LightThemeColors.primaryColor;

  @override
  Color primarySolidButtonTextColor = LightThemeColors.black;

  @override
  Color primarySolidButtonDisabledBackgroundColor =
      LightThemeColors.primaryColor;

  @override
  Color primarySolidButtonDisabledTextColor = LightThemeColors.black600;

  @override
  Color secondarySolidButtonBackgroundColor = LightThemeColors.grey950;

  @override
  Color secondarySolidButtonHoverBackgroundColor = LightThemeColors.grey400;

  @override
  Color secondarySolidButtonHoverTextColor = LightThemeColors.redColor;

  @override
  Color secondarySolidButtonTextColor = LightThemeColors.whiteColor;

  @override
  Color secondarySolidButtonDisabledBackgroundColor = LightThemeColors.grey300;

  @override
  Color secondarySolidButtonDisabledTextColor = LightThemeColors.grey200;

  @override
  Color tertiarySolidButtonBackgroundColor = LightThemeColors.redColor;

  @override
  Color tertiarySolidButtonHoverBackgroundColor = LightThemeColors.redColor;

  @override
  Color tertiarySolidButtonHoverTextColor = LightThemeColors.primaryColor;

  @override
  Color tertiarySolidButtonTextColor = LightThemeColors.whiteColor;

  @override
  Color tertiarySolidButtonDisabledBackgroundColor = LightThemeColors.redColor;

  @override
  Color tertiarySolidButtonDisabledTextColor = LightThemeColors.redColor;

  // Text Button
  @override
  Color textButtonTextColor = LightThemeColors.primaryColor;

  @override
  Color textButtonDisabledTextColor = LightThemeColors.grey300;

  // Outlined Button
  @override
  Color primaryOutlinedButtonBackgroundColor = Colors.transparent;

  @override
  double primaryOutlinedButtonBorderWidth = 1;

  @override
  Color primaryOutlinedButtonBorderColor = LightThemeColors.primaryColor;

  @override
  Color primaryOutlinedButtonHoverBackgroundColor = Colors.transparent;

  @override
  Color primaryOutlinedButtonTextColor = LightThemeColors.primaryColor;

  @override
  Color primaryOutlinedButtonHoverTextColor = LightThemeColors.primaryColor;

  @override
  Color primaryOutlinedButtonHoverBorderColor = LightThemeColors.primaryColor;

  @override
  Color primaryOutlinedButtonDisabledBackgroundColor = Colors.transparent;

  @override
  Color primaryOutlinedButtonDisabledTextColor = LightThemeColors.primaryColor;

  @override
  Color primaryOutlinedButtonDisabledBorderColor =
      LightThemeColors.primaryColor;

  @override
  Color secondaryOutlinedButtonBackgroundColor = Colors.transparent;

  @override
  double secondaryOutlinedButtonBorderWidth = 1;

  @override
  Color secondaryOutlinedButtonBorderColor = LightThemeColors.black900;

  @override
  Color secondaryOutlinedButtonHoverBackgroundColor = Colors.transparent;

  @override
  Color secondaryOutlinedButtonTextColor = LightThemeColors.black900;

  @override
  Color secondaryOutlinedButtonHoverTextColor = LightThemeColors.redColor;

  @override
  Color secondaryOutlinedButtonHoverBorderColor = LightThemeColors.redColor;

  @override
  Color secondaryOutlinedButtonDisabledBackgroundColor = Colors.transparent;

  @override
  Color secondaryOutlinedButtonDisabledTextColor = LightThemeColors.grey200;

  @override
  Color secondaryOutlinedButtonDisabledBorderColor = LightThemeColors.grey200;

  @override
  Color tertiaryOutlinedButtonBackgroundColor = Colors.transparent;

  @override
  double tertiaryOutlinedButtonBorderWidth = 1;

  @override
  Color tertiaryOutlinedButtonBorderColor = LightThemeColors.redColor;

  @override
  Color tertiaryOutlinedButtonHoverBackgroundColor = Colors.transparent;

  @override
  Color tertiaryOutlinedButtonTextColor = LightThemeColors.redColor;

  @override
  Color tertiaryOutlinedButtonHoverTextColor = LightThemeColors.redColor;

  @override
  Color tertiaryOutlinedButtonHoverBorderColor = LightThemeColors.redColor;

  @override
  Color tertiaryOutlinedButtonDisabledBackgroundColor = Colors.transparent;

  @override
  Color tertiaryOutlinedButtonDisabledTextColor = LightThemeColors.redColor;

  @override
  Color tertiaryOutlinedButtonDisabledBorderColor = LightThemeColors.redColor;

  // Switch
  @override
  Color switchActiveTrackColor = LightThemeColors.grey100;

  @override
  Color switchActiveThumbColor = LightThemeColors.primaryColor;

  @override
  Color switchActiveBorderColor = LightThemeColors.grey100;

  @override
  double? switchActiveBorderWidth;

  @override
  Color switchInactiveTrackColor = Colors.transparent;

  @override
  Color switchInactiveThumbColor = LightThemeColors.whiteColor;

  @override
  Color switchInactiveBorderColor = LightThemeColors.grey300;

  @override
  double? switchInactiveBorderWidth = 3;

  @override
  Color switchDisabledTrackColor = LightThemeColors.greyColor;

  @override
  Color switchDisabledBorderColor = LightThemeColors.greyColor;

  @override
  double? switchDisabledBorderWidth = 2;

  @override
  Color switchDisabledThumbColor = Colors.black26;

  @override
  Color checkboxBorderColor = LightThemeColors.grey400;

  @override
  Color lightGray = LightThemeColors.gray;

  @override
  Color unCheckboxBorderColor = LightThemeColors.grey300;

  @override
  Color checkboxSelectedBackgroundColor = LightThemeColors.whiteColor;

  @override
  Color checkboxUnselectedBackgroundColor = Colors.transparent;

  @override
  Color checkboxDisabledBackgroundColor = LightThemeColors.grey200;

  @override
  Color checkboxDisabledBorderColor = LightThemeColors.grey200;

  @override
  Color radioSelectedColor = LightThemeColors.grey100;

  @override
  Color radioDisabledColor = LightThemeColors.greyColor;

  // Bottom App Bar
  @override
  Color bottomAppBarTextColor = LightThemeColors.whiteColor;

  // App Bar
  @override
  Color appBarActionColor = LightThemeColors.black900;

  @override
  Color appBarDisabledActionColor = LightThemeColors.primaryColor;

  // Center Floating Action Button
  @override
  Color activeFloatingActionButtonBackgroundColor = LightThemeColors.redColor;

  @override
  Color activeFloatingActionButtonForegroundColor = LightThemeColors.whiteColor;

  @override
  Color inactiveFloatingActionButtonBackgroundColor =
      LightThemeColors.primaryColor;

  @override
  Color inactiveFloatingActionButtonForegroundColor = LightThemeColors.redColor;

  @override
  EdgeInsets defaultScaffoldPadding = const EdgeInsets.only(
    top: 20,
    left: 8,
    right: 8,
  );

  @override
  Color successBannerBorderColor = LightThemeColors.green700;
  @override
  Color successBannerBackgroundColor = LightThemeColors.green50;
  @override
  Color successBannerTextColor = LightThemeColors.green900;

  @override
  Color errorBannerBorderColor = LightThemeColors.redColor;
  @override
  Color errorBannerBackgroundColor = LightThemeColors.redColor;
  @override
  Color errorBannerTextColor = LightThemeColors.redColor;

  @override
  Color infoBannerBorderColor = LightThemeColors.primaryColor;
  @override
  Color infoBannerBackgroundColor = LightThemeColors.primaryColor;
  @override
  Color infoBannerTextColor = LightThemeColors.black900;

  @override
  Color warningBannerBorderColor = LightThemeColors.yellow600;
  @override
  Color warningBannerBackgroundColor = LightThemeColors.yellow50;
  @override
  Color warningBannerTextColor = LightThemeColors.yellow500;

  @override
  Color dividerColor = LightThemeColors.grey200;

  @override
  Color settingsDividerColor = LightThemeColors.grey200;

  // Bottom Nav
  @override
  Color bottomNavBackgroundColor = LightThemeColors.primaryColor;
  @override
  Color inactiveBottomNavItemColor = LightThemeColors.grey400;
  @override
  Color activeBottomNavItemColor = LightThemeColors.grey100;

  // TabBar
  @override
  Color tabBarBorderColor = LightThemeColors.grey100;

  @override
  Color tabBarInactiveItemColor = LightThemeColors.grey100;

  @override
  Color tabBarActiveItemColor = LightThemeColors.whiteColor;

  @override
  Color tabBarIndicatorColor = LightThemeColors.redColor;

  @override
  Color inputBackgroundColor = LightThemeColors.whiteColor;

  // Drop down
  @override
  Color dropdownBackgroundColor = LightThemeColors.primaryColor;

  @override
  Color dropdownSelectedItemBackgroundColor = LightThemeColors.primaryColor;

  @override
  Color dropdownTextColor = LightThemeColors.black900;

  @override
  Color containerBoxColor = LightThemeColors.grey50;

  @override
  List<BoxShadow> containerBoxShadow = [
    const BoxShadow(
      color: LightThemeColors.c98BEE4,
      blurRadius: 25.7,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];
  @override
  List<BoxShadow> addBoxShadow = [
    BoxShadow(
      color: LightThemeColors.primaryColor,
      blurRadius: 13.5,
      spreadRadius: 0,
      offset: const Offset(2.25, 4.5),
    ),
  ];

  @override
  BoxDecoration selectedTabBoxDecoration = BoxDecoration(
    color: LightThemeColors.whiteColor,
    borderRadius: 24.circular,

    border: Border.all(color: LightThemeColors.whiteColor, width: .2),
  );

  @override
  BoxDecoration tabBoxDecoration = BoxDecoration(
    color: LightThemeColors.grey50,
    borderRadius: 24.circular,
    border: Border.all(color: LightThemeColors.grey100, width: .2),
  );
  @override
  BoxDecoration containerDecoration = BoxDecoration(
    color: LightThemeColors.grey50,
    borderRadius: 24.circular,
    border: Border.all(color: LightThemeColors.grey100, width: .2),
    boxShadow: [
      BoxShadow(
        color: LightThemeColors.grey200,
        offset: const Offset(0, .45),
        spreadRadius: 0,
        blurRadius: 1.35,
      ),
    ],
  );

  @override
  BoxDecoration blueBoxDecoration = BoxDecoration(
    border: Border.all(color: LightThemeColors.grey50),
    borderRadius: 12.circular,
    //image: DecorationImage(image: Assets.png.blueGradientImage.provider(), fit: BoxFit.cover, opacity: .5),
  );

  @override
  Color agentChatBubbleTextColor = LightThemeColors.grey950;

  @override
  BoxDecoration userChatBubbleDecoration = BoxDecoration(
    color: LightThemeColors.primaryColor,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
    ),
  );

  @override
  Color userChatBubbleTextColor = LightThemeColors.grey50;
}
