import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? titleColor;
  final double elevation;
  final double height;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.backgroundColor,
    this.titleColor,
    this.elevation = 0,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: backgroundColor ?? lightBackground,
      elevation: elevation,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: height.h,
      leadingWidth: showBackButton ? 56.w : 0,
      leading: showBackButton
          ? IconButton(
        onPressed: onBackPressed ?? () {
          if (context.canPop()) {
            context.pop();
          }
        },
        icon: const Icon(Icons.arrow_back_ios),
        color: titleColor ?? Colors.black87,
        iconSize: 20.sp,
      )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
          color: titleColor ?? Colors.black87,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height.h);
}