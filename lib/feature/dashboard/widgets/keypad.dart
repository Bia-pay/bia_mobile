import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/utils/colors.dart';

typedef NumberKeyCallback = void Function(String number);

class CustomGridKeypad extends StatefulWidget {
  final NumberKeyCallback onNumberPressed;
  final ActionKey? leftAction;
  final ActionKey? rightAction;

  const CustomGridKeypad({
    super.key,
    required this.onNumberPressed,
    this.leftAction,
    this.rightAction,
  });

  @override
  State<CustomGridKeypad> createState() => _CustomGridKeypadState();
}

class _CustomGridKeypadState extends State<CustomGridKeypad> {
  int? _selectedIndex;

  final List<String> _numbers = [
    "1", "2", "3",
    "4", "5", "6",
    "7", "8", "9",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 25.w),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 35.w,
        mainAxisExtent: 70.h,
      ),
      itemBuilder: (context, index) {
        Widget child;
        VoidCallback? onTap;
        Color bgColor = keyAColor;

        // 1–9
        if (index < 9) {
          final number = _numbers[index];
          child = Text(
            number,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          );
          onTap = () => widget.onNumberPressed(number);
        }
        // Left action
        else if (index == 9) {
          if (widget.leftAction == null) return const SizedBox();
          child = widget.leftAction!.child;
          onTap = widget.leftAction!.onTap;
          bgColor = widget.leftAction!.backgroundColor ?? keyAColor;
        }
        // 0
        else if (index == 10) {
          child = Text(
            "0",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          );
          onTap = () => widget.onNumberPressed("0");
        }
        // Right action
        else {
          if (widget.rightAction == null) return const SizedBox();
          child = widget.rightAction!.child;
          onTap = widget.rightAction!.onTap;
          bgColor = widget.rightAction!.backgroundColor ?? keyAColor;
        }

        final isSelected = _selectedIndex == index;

        return InkWell(
          borderRadius: BorderRadius.circular(50.r),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap == null
              ? null
              : () {
            setState(() => _selectedIndex = index);
            onTap!();
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : [],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}

class ActionKey {
  final Widget child;
  final VoidCallback onTap;
  final Color? backgroundColor;

  ActionKey({
    required this.child,
    required this.onTap,
    this.backgroundColor,
  });
}