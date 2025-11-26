import 'package:bia/core/font.dart';
import 'package:flutter/material.dart';


import 'light/light_theme.dart';
import 'theme_context.dart';

class ThemeController with ChangeNotifier {
  factory ThemeController() => _instance;

  ThemeController._internal() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      _changeTheme(
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light ? _lightTheme : _darkTheme,
      );
    };
  }

  static final ThemeController _instance = ThemeController._internal();

  static final _lightTheme = LightTheme();
  static final _darkTheme = LightTheme();

  ThemeContext _themeContext = _darkTheme;
  ThemeMode _themeMode = ThemeMode.dark;

  void changeThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    switch (themeMode) {
      case ThemeMode.system:
        _changeTheme(
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light ? _lightTheme : _darkTheme,
        );
      case ThemeMode.light:
        _changeTheme(_lightTheme);
      case ThemeMode.dark:
        _changeTheme(_darkTheme);
    }
  }

  void _changeTheme(ThemeContext themeContext, {bool notify = true}) {
    if (_themeContext.brightness == themeContext.brightness) {
      return;
    }
    _themeContext = themeContext;
    if (notify) {
      notifyListeners();
    }
  }

  ThemeData get theme => makeTheme(_themeContext);

  ThemeData get darkTheme => makeTheme(_darkTheme);

  ThemeData get lightTheme => makeTheme(_lightTheme);

  ThemeContext get darkThemeContext => _darkTheme;

  ThemeContext get lightThemeContext => _lightTheme;

  ThemeContext get themeContext => _themeContext;

  ThemeMode get themeMode => _themeMode;

  ThemeData makeTheme(ThemeContext themeContext) {
    final textTheme = _createTextTheme(
      themeContext,
    ).apply(bodyColor: themeContext.primaryTextColor, displayColor: themeContext.primaryTextColor);

    return ThemeData(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      colorScheme: themeContext.colorScheme.copyWith(surface: themeContext.bodyTextColor),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        foregroundColor: themeContext.primaryTextColor,
        elevation: 1,
        titleTextStyle: textTheme.headlineMedium?.copyWith(color: themeContext.primaryTextColor),
        centerTitle: true,
        color: themeContext.background.color,
        shadowColor: themeContext.background.color,
        surfaceTintColor: themeContext.background.color,
        iconTheme: IconThemeData(color: themeContext.appBarActionColor),
      ),
      scaffoldBackgroundColor: themeContext.background.color,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: themeContext.inputBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: themeContext.defaultBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: themeContext.activeBorderColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: themeContext.errorBorderColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: themeContext.errorBorderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: themeContext.disabledBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide(color: themeContext.defaultBorderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        errorMaxLines: 3,
        isDense: true,
        hintStyle: TextStyle(color: themeContext.secondaryTextColor, fontSize: 16),
        errorStyle: textTheme.titleSmall!.copyWith(fontSize: 11, color: themeContext.errorTextColor),
        prefixIconColor: themeContext.activeIconColor,
        suffixIconColor: themeContext.activeIconColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.titleLarge!.copyWith(fontSize: 16, color: themeContext.primarySolidButtonTextColor),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ).copyWith(
          overlayColor: WidgetStateProperty.all<Color>(themeContext.primarySolidButtonHoverBackgroundColor),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.disabled)
                    ? themeContext.primarySolidButtonDisabledTextColor
                    : themeContext.primarySolidButtonTextColor,
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.isEmpty
                    ? themeContext.primarySolidButtonBackgroundColor
                    : states.contains(WidgetState.disabled)
                    ? themeContext.primarySolidButtonDisabledBackgroundColor
                    : themeContext.primarySolidButtonHoverBackgroundColor,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.titleLarge!.copyWith(fontSize: 16, color: themeContext.primarySolidButtonTextColor),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ).copyWith(
          overlayColor: WidgetStateProperty.all<Color>(themeContext.primarySolidButtonHoverBackgroundColor),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.disabled)
                    ? themeContext.primarySolidButtonDisabledTextColor
                    : themeContext.primarySolidButtonTextColor,
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.isEmpty
                    ? themeContext.primarySolidButtonBackgroundColor
                    : states.contains(WidgetState.disabled)
                    ? themeContext.primarySolidButtonDisabledBackgroundColor
                    : themeContext.primarySolidButtonHoverBackgroundColor,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.titleLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          disabledBackgroundColor: themeContext.primaryOutlinedButtonDisabledBackgroundColor,
          disabledForegroundColor: themeContext.primaryOutlinedButtonDisabledTextColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.isEmpty
                    ? themeContext.primaryOutlinedButtonBackgroundColor
                    : states.contains(WidgetState.disabled)
                    ? themeContext.primaryOutlinedButtonDisabledBackgroundColor
                    : themeContext.primaryOutlinedButtonHoverBackgroundColor,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.isEmpty
                    ? themeContext.primaryOutlinedButtonTextColor
                    : states.contains(WidgetState.disabled)
                    ? themeContext.primaryOutlinedButtonDisabledTextColor
                    : themeContext.primaryOutlinedButtonHoverTextColor,
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.isEmpty
                    ? themeContext.primaryOutlinedButtonBackgroundColor
                    : states.contains(WidgetState.disabled)
                    ? themeContext.primaryOutlinedButtonDisabledBackgroundColor
                    : themeContext.primaryOutlinedButtonHoverBackgroundColor,
          ),
          side: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => BorderSide(
              width: themeContext.primaryOutlinedButtonBorderWidth,
              color:
                  states.contains(WidgetState.disabled)
                      ? themeContext.primaryOutlinedButtonDisabledBorderColor
                      : themeContext.primaryOutlinedButtonBorderColor,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          textStyle: textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w400, fontSize: 16),
          backgroundColor: Colors.transparent,
        ).copyWith(
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.disabled)
                    ? themeContext.textButtonDisabledTextColor
                    : themeContext.textButtonTextColor,
          ),
          shape: WidgetStateProperty.resolveWith<OutlinedBorder?>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.pressed)
                    ? LinearBorder.bottom(side: BorderSide(color: themeContext.textButtonTextColor))
                    : null,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.switchDisabledTrackColor;
          }

          return !states.contains(WidgetState.selected)
              ? themeContext.switchInactiveTrackColor
              : themeContext.switchActiveTrackColor;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.switchDisabledBorderColor;
          }

          return !states.contains(WidgetState.selected)
              ? themeContext.switchInactiveBorderColor
              : themeContext.switchActiveBorderColor;
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.switchDisabledBorderWidth;
          }

          return !states.contains(WidgetState.selected)
              ? themeContext.switchInactiveBorderWidth
              : themeContext.switchActiveBorderWidth;
        }),
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.switchDisabledThumbColor;
          }

          return !states.contains(WidgetState.selected)
              ? themeContext.switchInactiveThumbColor
              : states.contains(WidgetState.selected)
              ? themeContext.switchActiveThumbColor
              : null;
        }),
        thumbIcon: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled) ? null : const Icon(null),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: false,
        elevation: 16,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        modalElevation: 16,
        shadowColor: Colors.transparent,
        modalBarrierColor: Colors.black.withAlpha((255.0 * 0.6).round()),
        modalBackgroundColor: themeContext.background.color,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.checkboxDisabledBackgroundColor;
          } else if (!states.contains(WidgetState.selected)) {
            return themeContext.checkboxUnselectedBackgroundColor;
          } else {
            return themeContext.checkboxSelectedBackgroundColor;
          }
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.checkboxDisabledBorderColor;
          } else if (!states.contains(WidgetState.selected)) {
            return themeContext.checkboxBorderColor;
          } else {
            return themeContext.checkboxBorderColor;
          }
        }),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            width: 1,
            color:
                states.contains(WidgetState.disabled)
                    ? themeContext.checkboxDisabledBorderColor
                    : !states.contains(WidgetState.selected)
                    ? themeContext.unCheckboxBorderColor
                    : themeContext.checkboxBorderColor,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return themeContext.radioDisabledColor;
          } else {
            return themeContext.radioSelectedColor;
          }
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeContext.activeFloatingActionButtonBackgroundColor,
        foregroundColor: themeContext.activeFloatingActionButtonForegroundColor,
        shape: const CircleBorder(),
        elevation: 0,
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderRadius: BorderRadius.circular(8),
        borderColor: themeContext.activeBorderColor,
        textStyle: textTheme.titleLarge,
        color: themeContext.activeBorderColor,
        selectedColor: Colors.white,
        fillColor: themeContext.activeBorderColor,
        selectedBorderColor: themeContext.activeBorderColor,
        disabledColor: themeContext.disabledBackgroundColor,
        disabledBorderColor: themeContext.disabledBorderColor,
      ),

      dividerColor: themeContext.settingsDividerColor,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white, elevation: 4),

      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        tilePadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        collapsedBackgroundColor: Colors.white,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyMedium,
        tileColor: themeContext.background.color,
        iconColor: themeContext.primaryTextColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      ),
    );
  }

  TextTheme _createTextTheme(ThemeContext themeContext) => TextTheme(
    // Title 1
    displayLarge: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w700, fontSize: 32),
    // Title 2
    displayMedium: TextStyle(
      fontFamily: FontFamily.outfit,
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: themeContext.titleTextColor,
    ),
    // Title 3
    displaySmall: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w700, fontSize: 22),
    // Title 4
    headlineLarge: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w700, fontSize: 24),
    // Headline 1
    headlineMedium: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w400, fontSize: 18),
    // Title 5
    headlineSmall: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w700, fontSize: 16),
    // FormField Fonts
    bodyLarge: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w600, fontSize: 24),
    // Body 2 | Body 1 => copyWith(fontSize: 20)
    bodyMedium: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w400, fontSize: 16),
    // Body 3 / Call out
    bodySmall: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w300, fontSize: 12),
    // Headline 2 | Hyperlink => copyWith(color: #004C96)
    titleLarge: TextStyle(
      fontFamily: FontFamily.outfit,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: themeContext.titleTextColor,
      height: 1,
    ),
    // Subhead
    titleMedium: TextStyle(
      fontFamily: FontFamily.outfit,
      fontWeight: FontWeight.w400,
      fontSize: 15,
      color: themeContext.primaryTextColor,
    ),
    // Subtitle/Caption | Subtitle2/Caption2 => copyWith(fontSize: 11)
    titleSmall: TextStyle(
      fontFamily: FontFamily.outfit,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: themeContext.primaryTextColor,
    ),
    // Button
    labelLarge: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w700, fontSize: 17),
    // LABEL
    labelMedium: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w700, fontSize: 13),
    // Footnote
    labelSmall: const TextStyle(fontFamily: FontFamily.outfit, fontWeight: FontWeight.w400, fontSize: 13),
  );
}
