import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/utils/colors.dart';

typedef NumberKeyCallback = void Function(String number);

class CustomGridKeypad extends StatelessWidget {
  final NumberKeyCallback onNumberPressed;
  final ActionKey? leftAction;
  final ActionKey? rightAction;
  final Color? keyColor;
  final Color? textColor;

  const CustomGridKeypad({
    super.key,
    required this.onNumberPressed,
    this.leftAction,
    this.rightAction,
    this.keyColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Original simplified spacing and sizing
    final horizontalPadding = 30.w;
    final mainSpacing = 15.h;
    final crossSpacing = 25.w;
    final fontSize = 26.sp;

    final List<String> numbers = [
      "1", "2", "3",
      "4", "5", "6",
      "7", "8", "9",
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        Widget child;
        VoidCallback? onTap;
        Color bgColor = keyColor ?? keyAColor;
        Color txtColor = textColor ?? grey;

        if (index < 9) {
          final number = numbers[index];
          child = Text(
            number,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: txtColor,
            ),
          );
          onTap = () => onNumberPressed(number);
        } else if (index == 9) {
          if (leftAction == null) return const SizedBox();
          child = leftAction!.child;
          onTap = leftAction!.onTap;
          bgColor = leftAction!.backgroundColor ?? bgColor;
        } else if (index == 10) {
          child = Text(
            "0",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: txtColor,
            ),
          );
          onTap = () => onNumberPressed("0");
        } else {
          if (rightAction == null) return const SizedBox();
          child = rightAction!.child;
          onTap = rightAction!.onTap;
          bgColor = rightAction!.backgroundColor ?? bgColor;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(50.r),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
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