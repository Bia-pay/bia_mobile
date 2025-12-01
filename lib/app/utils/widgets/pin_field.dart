import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class AppPinCodeField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  // Customization options
  final Color? fillColor;
  final Color? inactiveColor;
  final Color? activeColor;
  final Color? selectedColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? fieldPadding; // new

  const AppPinCodeField({
    super.key,
    required this.controller,
    this.length = 4,
    this.obscure = false,
    this.onChanged,
    this.onCompleted,
    this.fillColor,
    this.inactiveColor,
    this.activeColor,
    this.selectedColor,
    this.borderRadius,
    this.fieldPadding, // new
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PinCodeTextField(
      appContext: context,
      controller: controller,
      length: length.clamp(2, 6),
      animationType: AnimationType.fade,
      keyboardType: TextInputType.number,
      obscureText: obscure,
      autoFocus: false,
      enableActiveFill: true,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: borderRadius ?? BorderRadius.circular(10.r),
        fieldHeight: 45.h,
        fieldWidth: 45.w,
        activeColor: activeColor ?? theme.colorScheme.primary,
        selectedColor: selectedColor ?? theme.colorScheme.primary,
        inactiveColor: inactiveColor ?? Colors.grey.shade900,
        activeFillColor: fillColor ?? Colors.grey.shade500,
        selectedFillColor: fillColor ?? Colors.grey.shade500,
        inactiveFillColor: fillColor ?? Colors.grey.shade500,
        fieldOuterPadding: fieldPadding ?? EdgeInsets.symmetric(horizontal: 5.w),
      ),
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}