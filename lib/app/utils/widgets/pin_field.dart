import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class AppPinCodeField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final bool obscure;
  final String obscuringCharacter;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  // 🎨 Customization
  final Color? fillColor;
  final Color? inactiveColor;
  final Color? activeColor;
  final Color? selectedColor;

  final double? fieldHeight;
  final double? fieldWidth;

  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? fieldPadding;

  final PinCodeFieldShape shape;

  const AppPinCodeField({
    super.key,
    required this.controller,
    this.length = 4,
    this.obscure = false,
    this.obscuringCharacter = "●",
    this.onChanged,
    this.onCompleted,
    this.fillColor,
    this.inactiveColor,
    this.activeColor,
    this.selectedColor,
    this.borderRadius,
    this.fieldPadding,
    this.fieldHeight,
    this.fieldWidth,
    this.shape = PinCodeFieldShape.box,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    final h = fieldHeight ?? (isTablet ? 52.0 : 45.h);

    return PinCodeTextField(
      appContext: context,
      controller: controller,
      length: length.clamp(2, 6),
      animationType: AnimationType.fade,
      keyboardType: TextInputType.none,
      obscureText: obscure,
      obscuringCharacter: obscuringCharacter,
      autoFocus: false,
      enableActiveFill: true,
      readOnly: true,
      enablePinAutofill: false,

      // 🔥 THIS CONTROLS CENTERING
      textStyle: TextStyle(
        fontSize: h * 0.5,
        fontWeight: FontWeight.w600,
        height: 1,
      ),

      mainAxisAlignment: MainAxisAlignment.center,

      pinTheme: PinTheme(
        shape: shape,
        borderRadius: borderRadius ?? BorderRadius.circular(isTablet ? 10.0 : 10.r),
        fieldHeight: h,
        fieldWidth: fieldWidth ?? (isTablet ? 48.0 : 45.w),

        activeColor: activeColor ?? theme.colorScheme.primary,
        selectedColor: selectedColor ?? theme.colorScheme.primary,
        inactiveColor: inactiveColor ?? Colors.grey.shade400,

        activeFillColor: fillColor ?? Colors.grey.shade200,
        selectedFillColor: fillColor ?? Colors.grey.shade200,
        inactiveFillColor: fillColor ?? Colors.grey.shade200,

        fieldOuterPadding:
        fieldPadding ?? EdgeInsets.symmetric(horizontal: isTablet ? 3.0 : 2.w),
      ),
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}