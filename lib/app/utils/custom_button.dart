import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends ConsumerWidget {
  const CustomButton({
    super.key,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonName,
    this.onPressed,
    this.textStyle,
    this.buttonBorderColor,

    // One of these 3
    this.icon,
    this.imageAsset,
    this.svgAsset,

    this.iconSize,
    this.spacing,
  });

  final Color buttonColor;
  final Color buttonTextColor;
  final String buttonName;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final Color? buttonBorderColor;

  // Icon options
  final IconData? icon;
  final String? imageAsset;
  final String? svgAsset;

  final double? iconSize;
  final double? spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Widget? leading;

    if (icon != null) {
      leading = Icon(
        icon,
        size: iconSize ?? 18.sp,
        color: buttonTextColor,
      );
    } else if (imageAsset != null) {
      leading = Image.asset(
        imageAsset!,
        width: iconSize ?? 18.sp,
        height: iconSize ?? 18.sp,
      );
    } else if (svgAsset != null) {
      leading = SvgPicture.asset(
        svgAsset!,
        width: iconSize ?? 18.sp,
        height: iconSize ?? 18.sp,
        colorFilter: ColorFilter.mode(
          buttonTextColor,
          BlendMode.srcIn,
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: buttonBorderColor ?? Colors.transparent,
            width: 0.3.w,
          ),
          color: buttonColor,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                SizedBox(width: spacing ?? 8.w),
              ],
              Text(
                buttonName,
                style: textStyle ??
                    theme.textTheme.bodyMedium?.copyWith(
                      color: buttonTextColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}