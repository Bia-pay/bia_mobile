import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final horizontalPadding = isTablet ? 8.0 : 32.w;
    final mainSpacing = isTablet ? 12.0 : 16.h;
    final crossSpacing = isTablet ? 16.0 : 24.w;
    final fontSize = isTablet ? 22.0 : 24.sp;
    final aspectRatio = 1.0;

    final List<String> numbers = [
      "1", "2", "3",
      "4", "5", "6",
      "7", "8", "9",
    ];

    Widget grid = GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        Widget child;
        VoidCallback? onTap;
        Color bgColor;

        if (index < 9) {
          final number = numbers[index];
          child = Text(
            number,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          );
          onTap = () => onNumberPressed(number);
          bgColor = keyColor ?? const Color(0xFFF1F5F9);
        } else if (index == 9) {
          if (leftAction == null) return const SizedBox();
          child = leftAction!.child;
          onTap = leftAction!.onTap;
          bgColor = leftAction!.backgroundColor ?? const Color(0xFFF1F5F9);
        } else if (index == 10) {
          child = Text(
            "0",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          );
          onTap = () => onNumberPressed("0");
          bgColor = keyColor ?? const Color(0xFFF1F5F9);
        } else {
          if (rightAction == null) return const SizedBox();
          child = rightAction!.child;
          onTap = rightAction!.onTap;
          bgColor = rightAction!.backgroundColor ?? const Color(0xFFF1F5F9);
        }

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: bgColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: child,
              ),
            ),
          ),
        );
      },
    );

    if (isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: grid,
        ),
      );
    }

    return grid;
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