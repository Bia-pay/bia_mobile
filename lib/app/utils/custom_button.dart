import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ------------------ CUSTOM BUTTON HELPER ------------------
class CustomButton extends ConsumerWidget {
  const CustomButton({
    super.key,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonName,
    this.onPressed,
    this.textStyle,
    this.buttonBorderColor,
  });
  final Color buttonColor;
  final Color buttonTextColor;
  final String buttonName;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final Color? buttonBorderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
        decoration: BoxDecoration(
          border: Border.all(color: buttonBorderColor ?? Colors.transparent,
          width: 1.w),
          color: buttonColor,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Text(
            buttonName,
            style:
                textStyle ??
                TextStyle(
                  color: buttonTextColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
