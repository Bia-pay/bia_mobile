import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';

import '../../../core/themes/theme_context.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.appButtonStyle = AppButtonStyle.primarySolid,
    this.child,
    this.text,
    this.prefixIconData,
    this.suffixIconData,
    this.prefix,
    this.suffix,
    this.minimumSize = const Size(double.infinity, 52),
    this.maximumSize,
    this.size,
    this.enabled = true,
    this.padding,
    this.onPressed,
    this.onLongPress,
    this.centralized = true,
    this.borderRadius,
    this.textStyle,
  }) : assert(
  (child == null) ^ (text == null),
  'You must provide only one of child or text',
  ),
        assert(
        child == null || prefixIconData == null,
        'You cannot provide prefixIconData with child',
        ),
        assert(
        child == null || suffixIconData == null,
        'You cannot provide suffixIconData with child',
        ),
        assert(
        size == null || minimumSize == null,
        'You cannot provide size with minimumSize',
        ),
        assert(
        size == null || maximumSize == null,
        'You cannot provide size with maximumSize',
        ),
        assert(
        (prefix == null) || (prefixIconData == null),
        'You can only provide one of prefix and prefixIconData',
        ),
        assert(
        (suffix == null) || (suffixIconData == null),
        'You can only provide one of suffix and suffixIconData',
        );

  final AppButtonStyle appButtonStyle;
  final Widget? child;
  final String? text;
  final IconData? prefixIconData;
  final IconData? suffixIconData;
  final Widget? prefix;
  final Widget? suffix;
  final Size? minimumSize;
  final Size? maximumSize;
  final Size? size;
  final bool enabled;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final bool centralized;
  final double? borderRadius;

  void _unfocusAndPress(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = appButtonStyle.isOutlined
        ? Theme.of(context).outlinedButtonTheme.style!
        : Theme.of(context).elevatedButtonTheme.style!;

    final style = defaultStyle.copyWith(
      padding: WidgetStatePropertyAll(padding ?? const EdgeInsets.all(13)),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) => states.isEmpty
            ? appButtonStyle.backgroundColor
            : appButtonStyle.disabledColor,
      ),
      overlayColor: WidgetStateProperty.all<Color>(appButtonStyle.hoverColor),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) => states.isEmpty
            ? appButtonStyle.textColor
            : appButtonStyle.disabledTextColor,
      ),
      minimumSize: WidgetStatePropertyAll(minimumSize ?? size),
      maximumSize: WidgetStatePropertyAll(maximumSize ?? size),
      shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
            (Set<WidgetState> states) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 32),
          side: !appButtonStyle.isOutlined
              ? BorderSide.none
              : BorderSide(
            color: states.isEmpty
                ? appButtonStyle.borderColor
                : states.contains(WidgetState.disabled)
                ? appButtonStyle.disabledBorderColor
                : appButtonStyle.hoverBorderColor,
            width: appButtonStyle.borderWidth,
          ),
        ),
      ),
      side: !appButtonStyle.isOutlined
          ? const WidgetStatePropertyAll(BorderSide.none)
          : WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => BorderSide(
          width: appButtonStyle.borderWidth,
          color: states.isEmpty
              ? appButtonStyle.borderColor
              : appButtonStyle.disabledBorderColor,
        ),
      ),
    );

    var prefixWidget = prefix;
    var suffixWidget = suffix;

    if (centralized &&
        (prefixIconData != null || prefix != null) &&
        suffixIconData == null &&
        suffix == null) {
      suffixWidget = Opacity(
        opacity: 0,
        child: prefixIconData != null ? Icon(prefixIconData, size: 24) : prefix!,
      );
    }
    if (centralized &&
        (suffixIconData != null || suffix != null) &&
        prefixIconData == null &&
        prefix == null) {
      prefixWidget = Opacity(
        opacity: 0,
        child: suffixIconData != null ? Icon(suffixIconData, size: 24) : suffix!,
      );
    }

    final theChild = child ??
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefixIconData != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(prefixIconData, size: 24),
              )
            else if (prefixWidget != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: prefixWidget,
              ),
            Flexible(
              child: Text(
                text!,
                textAlign: TextAlign.center,
                style: textStyle ??
                    TextStyle(
                        fontSize: 16, color: context.themeContext.offWhiteBg),
              ),
            ),
            if (suffixIconData != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(suffixIconData, size: 24),
              )
            else if (suffixWidget != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: suffixWidget,
              ),
          ],
        );

    return switch (appButtonStyle) {
      AppButtonStyle.primarySolid ||
      AppButtonStyle.secondarySolid ||
      AppButtonStyle.tertiarySolid =>
          ElevatedButton(
            onPressed:
            enabled && onPressed != null ? () => _unfocusAndPress(context) : null,
            onLongPress: enabled && onLongPress != null ? onLongPress : null,
            style: style,
            child: theChild,
          ),
      AppButtonStyle.primaryOutlined ||
      AppButtonStyle.secondaryOutlined ||
      AppButtonStyle.tertiaryOutlined =>
          OutlinedButton(
            onPressed:
            enabled && onPressed != null ? () => _unfocusAndPress(context) : null,
            onLongPress: enabled && onLongPress != null ? onLongPress : null,
            style: style,
            child: theChild,
          ),
    };
  }
}

class OutlinedAppButton extends AppButton {
  const OutlinedAppButton.primary({super.key, super.child, super.text, super.prefixIconData, super.suffixIconData, super.prefix, super.suffix, super.minimumSize, super.maximumSize, super.size, super.enabled = true, super.padding, super.onPressed, super.onLongPress, super.centralized, super.borderRadius})
      : super(appButtonStyle: AppButtonStyle.primaryOutlined);

  const OutlinedAppButton.secondary({super.key, super.child, super.text, super.prefixIconData, super.suffixIconData, super.prefix, super.suffix, super.minimumSize, super.maximumSize, super.size, super.enabled = true, super.padding, super.onPressed, super.onLongPress, super.centralized, super.borderRadius})
      : super(appButtonStyle: AppButtonStyle.secondaryOutlined);

  const OutlinedAppButton.tertiary({super.key, super.child, super.text, super.prefixIconData, super.suffixIconData, super.prefix, super.suffix, super.minimumSize, super.maximumSize, super.size, super.enabled = true, super.padding, super.onPressed, super.onLongPress, super.centralized, super.borderRadius})
      : super(appButtonStyle: AppButtonStyle.tertiaryOutlined);
}

class SolidAppButton extends AppButton {
  const SolidAppButton.primary({super.key, super.child, super.text, super.prefixIconData, super.suffixIconData, super.prefix, super.suffix, super.minimumSize, super.maximumSize, super.size, super.enabled = true, super.padding, super.onPressed, super.onLongPress, super.centralized, super.borderRadius})
      : super(appButtonStyle: AppButtonStyle.primarySolid);

  const SolidAppButton.secondary({super.key, super.child, super.text, super.prefixIconData, super.suffixIconData, super.prefix, super.suffix, super.minimumSize, super.maximumSize, super.size, super.enabled = true, super.padding, super.onPressed, super.onLongPress, super.centralized, super.borderRadius})
      : super(appButtonStyle: AppButtonStyle.secondarySolid);

  const SolidAppButton.tertiary({super.key, super.child, super.text, super.prefixIconData, super.suffixIconData, super.prefix, super.suffix, super.minimumSize, super.maximumSize, super.size, super.enabled = true, super.padding, super.onPressed, super.onLongPress, super.centralized, super.borderRadius})
      : super(appButtonStyle: AppButtonStyle.tertiarySolid);
}

enum AppButtonStyle {
  primarySolid,
  secondarySolid,
  tertiarySolid,
  primaryOutlined,
  secondaryOutlined,
  tertiaryOutlined;

  ThemeContext get _themeContext => ThemeContext.of(null);

  bool get isOutlined =>
      this == primaryOutlined ||
          this == secondaryOutlined ||
          this == tertiaryOutlined;

  Color get backgroundColor => switch (this) {
    AppButtonStyle.primarySolid =>
    _themeContext.primarySolidButtonBackgroundColor,
    AppButtonStyle.secondarySolid =>
    _themeContext.backgroundColor, // ✅ CHANGED
    AppButtonStyle.tertiarySolid =>
    _themeContext.tertiarySolidButtonBackgroundColor,
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonBackgroundColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonBackgroundColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonBackgroundColor,
  };

  double get borderWidth => switch (this) {
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonBorderWidth,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonBorderWidth,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonBorderWidth,
    _ => 0,
  };

  Color get hoverColor => switch (this) {
    AppButtonStyle.primarySolid =>
    _themeContext.primarySolidButtonHoverBackgroundColor,
    AppButtonStyle.secondarySolid =>
        _themeContext.offWhiteBg.withOpacity(0.9), // ✅ CHANGED
    AppButtonStyle.tertiarySolid =>
    _themeContext.tertiarySolidButtonHoverBackgroundColor,
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonHoverBackgroundColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonHoverBackgroundColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonHoverBackgroundColor,
  };

  Color get borderColor => switch (this) {
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonBorderColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonBorderColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonBorderColor,
    _ => Colors.transparent,
  };

  Color get hoverBorderColor => switch (this) {
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonHoverBorderColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonHoverBorderColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonHoverBorderColor,
    _ => Colors.transparent,
  };

  Color get disabledBorderColor => switch (this) {
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonDisabledBorderColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonDisabledBorderColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonDisabledBorderColor,
    _ => Colors.transparent,
  };

  Color get textColor => switch (this) {
    AppButtonStyle.primarySolid =>
    _themeContext.offWhiteBg,
    AppButtonStyle.secondarySolid =>
    Colors.black, // ✅ CHANGED
    AppButtonStyle.tertiarySolid =>
    _themeContext.tertiarySolidButtonTextColor,
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonTextColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonTextColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonTextColor,
  };

  Color get hoverTextColor => switch (this) {
    AppButtonStyle.primarySolid =>
    _themeContext.primarySolidButtonHoverTextColor,
    AppButtonStyle.secondarySolid =>
    Colors.black, // stays black
    AppButtonStyle.tertiarySolid =>
    _themeContext.tertiarySolidButtonHoverTextColor,
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonHoverTextColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonHoverTextColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonHoverTextColor,
  };

  Color get disabledColor => switch (this) {
    AppButtonStyle.primarySolid =>
    _themeContext.primarySolidButtonDisabledBackgroundColor,
    AppButtonStyle.secondarySolid =>
        _themeContext.offWhiteBg, // ✅ CHANGED
    AppButtonStyle.tertiarySolid =>
    _themeContext.tertiarySolidButtonDisabledBackgroundColor,
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonDisabledBackgroundColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonDisabledBackgroundColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonDisabledBackgroundColor,
  };

  Color get disabledTextColor => switch (this) {
    AppButtonStyle.primarySolid =>
    _themeContext.primarySolidButtonDisabledTextColor,
    AppButtonStyle.secondarySolid =>
        Colors.black.withOpacity(0.5), // ✅ CHANGED
    AppButtonStyle.tertiarySolid =>
    _themeContext.tertiarySolidButtonDisabledTextColor,
    AppButtonStyle.primaryOutlined =>
    _themeContext.primaryOutlinedButtonDisabledTextColor,
    AppButtonStyle.secondaryOutlined =>
    _themeContext.secondaryOutlinedButtonDisabledTextColor,
    AppButtonStyle.tertiaryOutlined =>
    _themeContext.tertiaryOutlinedButtonDisabledTextColor,
  };
}
