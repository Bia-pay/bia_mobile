import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/colors.dart';


class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
    this.isPrimary = true,
    this.isOutlined = false,
    this.borderRadius = 12,
    this.height = 52,
    this.prefix,
    this.suffix,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isPrimary;
  final bool isOutlined;
  final double borderRadius;
  final double height;
  final Widget? prefix;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // ---------------------------------------------------------
    // COLORS FROM YOUR NEW THEME FILE
    // ---------------------------------------------------------
    final Color bg = isPrimary
        ? primaryColor
        : (isLight ? lightSurface : darkSurface);

    final Color fg = isPrimary
        ? lightBackground
        : (isLight ? lightText : darkText);

    final Color disabledBg = isLight
        ? lightSurface
        : darkSurface.withOpacity(0.4);

    final Color disabledFg = isLight
        ? lightSecondaryText
        : darkSecondaryText;

    final Color outlineColor =
    isLight ? lightBorderColor : darkBorderColor;

    return SizedBox(
      height: height.h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isOutlined
              ? Colors.transparent
              : (enabled ? bg : disabledBg),
          foregroundColor: enabled ? fg : disabledFg,
          disabledForegroundColor: disabledFg,
          disabledBackgroundColor: disabledBg,
          side: isOutlined
              ? BorderSide(
            color: enabled ? outlineColor : outlineColor.withOpacity(0.5),
            width: 1.2,
          )
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 18.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix != null) ...[
              prefix!,
              SizedBox(width: 8.w),
            ],
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: enabled ? fg : disabledFg,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (suffix != null) ...[
              SizedBox(width: 8.w),
              suffix!,
            ],
          ],
        ),
      ),
    );
  }
}