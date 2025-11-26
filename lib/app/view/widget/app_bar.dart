import 'package:bia/core/constraint.dart';
import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? rightIcon;

  const CustomHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        GestureDetector(
          onTap: onBackPressed ?? () => Navigator.of(context).pop(),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            size: 21, // You can use ScreenUtil or your custom .sp(context)
          ),
        ),

        // Title
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 20,fontWeight: FontWeight.w600),
        ),

        // Right Icon (Optional)
        rightIcon ??
            Container(
              height: 45.h(context), // You can use .h(context) if you have ScreenUtil
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              child: RSvg(
                'assets/svg/bell.svg', // Default asset
              ),
            ),
      ],
    );
  }
}
