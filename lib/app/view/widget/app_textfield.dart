import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/themes/theme_context.dart';
import '../../validation/validator.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.fieldKey,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.decoration,
    this.obscureText = false,
    this.autoCorrect = true,
    this.autoFocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.initialValue,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.inputValidator,
    this.autovalidateMode,
    this.scrollPadding = const EdgeInsets.all(20),
    this.hintText,
    this.hintTextAlign,
    this.labelText,
    this.alignLabelWithHint,
    this.style,
    this.textAlignVertical,
    this.suffixIcon,
    this.prefixIcon,
    this.borderRadius = 8.0,
  }) : assert(
  validator == null || inputValidator == null,
  'You can only provide one of validator and inputValidator',
  );

  final Key? fieldKey;
  final TextEditingController? controller;
  final bool enabled;
  final bool readOnly;
  final InputDecoration? decoration;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? initialValue;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLength;
  final bool autoCorrect;
  final bool autoFocus;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final InputValidator<String>? inputValidator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsets scrollPadding;
  final String? hintText;
  final String? labelText;
  final bool? alignLabelWithHint;
  final TextStyle? style;
  final TextAlignVertical? textAlignVertical;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextAlign? hintTextAlign;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final themeContext = ThemeContext.of(context);
    final textTheme = Theme.of(context).textTheme;

    final defaultBorderSide =
    BorderSide(color: const Color(0xFFB6B7C3), width: 1.0);

    final v = inputValidator != null
        ? (String? value) => inputValidator!
        .call(value)
        .validate()
        .firstOrNull
        ?.toInputValidator(context: context)
        : validator;

    final defaultInputStyle = style ??
        textTheme.displaySmall?.copyWith(
          color: enabled
              ? const Color(0xFF383842)
              : themeContext.disabledTextColor,
        );

    final defaultLabelStyle = textTheme.displaySmall?.copyWith(
      color: enabled
          ? const Color(0xFF383842)
          : themeContext.disabledTextColor,
      fontSize: 10,
    );

    final errorLabelStyle = textTheme.bodySmall?.copyWith(
      color: enabled
          ? const Color(0xFFE83B3B)
          : themeContext.disabledTextColor,
      fontSize: 13,
    );

    final defaultHintStyle = textTheme.bodySmall?.copyWith(
      color: enabled
          ? const Color(0xFFB6B7C3)
          : themeContext.disabledTextColor,
      fontSize: 12,
    );

    final hasNoBorder = decoration?.border == InputBorder.none;

    final effectiveDecoration =
    (decoration ?? const InputDecoration()).copyWith(
      errorStyle: errorLabelStyle?.merge(decoration?.errorStyle),
      labelText: labelText,
      hintText: hintText,
      labelStyle: defaultLabelStyle?.merge(decoration?.labelStyle),
      hintStyle: defaultHintStyle?.merge(decoration?.hintStyle),
      hintTextDirection:
      hintTextAlign == TextAlign.center ? TextDirection.ltr : null,
      filled: decoration?.filled ?? true,
      fillColor: decoration?.fillColor ??
          (enabled
              ? Colors.white
              : themeContext.disabledBackgroundColor),
      border: decoration?.border ?? InputBorder.none,
      enabledBorder: hasNoBorder
          ? InputBorder.none
          : (decoration?.enabledBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: defaultBorderSide,
          )),
      focusedBorder: hasNoBorder
          ? InputBorder.none
          : (decoration?.focusedBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: defaultBorderSide.copyWith(
              color: const Color(0xFF717286),
              width: 1.5,
            ),
          )),
      errorBorder: hasNoBorder
          ? InputBorder.none
          : (decoration?.errorBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: defaultBorderSide.copyWith(
              color: themeContext.errorBorderColor,
            ),
          )),
      focusedErrorBorder: hasNoBorder
          ? InputBorder.none
          : (decoration?.focusedErrorBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: defaultBorderSide.copyWith(
              color: themeContext.errorBorderColor,
              width: 1.5,
            ),
          )),
      disabledBorder: hasNoBorder
          ? InputBorder.none
          : (decoration?.disabledBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: defaultBorderSide.copyWith(
              color: themeContext.disabledBorderColor,
            ),
          )),
      suffixIcon: suffixIcon,
      suffixIconColor: enabled
          ? const Color(0xFF5B5D6E)
          : themeContext.disabledIconColor,
      prefixIcon: prefixIcon,
      prefixIconColor: enabled
          ? const Color(0xFF5B5D6E)
          : themeContext.disabledIconColor,

      /// 👇 This controls input alignment and height
      contentPadding: decoration?.contentPadding ??
          const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
      alignLabelWithHint: alignLabelWithHint,
    );

    return TextFormField(
      key: fieldKey,
      controller: controller,
      scrollPadding: scrollPadding,
      enabled: enabled,
      readOnly: readOnly,
      decoration: effectiveDecoration,
      obscureText: obscureText,
      autocorrect: autoCorrect,
      autofocus: autoFocus,
      textCapitalization: textCapitalization,
      focusNode: focusNode,
      initialValue: initialValue,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: defaultInputStyle,
      validator: v,
      autovalidateMode: autovalidateMode,
      textAlignVertical:
      textAlignVertical ?? TextAlignVertical.center, // ✅ Vertical center
      textAlign: hintTextAlign ?? TextAlign.start,
    );
  }
}