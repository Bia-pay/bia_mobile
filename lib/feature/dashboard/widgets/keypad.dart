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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isLargeScreen = screenSize.height > 900;

    // Calculate available space properly
    final availableWidth = screenSize.width - (screenSize.width * 0.12); // minus padding
    final keySize = (availableWidth / 3).clamp(
      isSmallScreen ? 60.0 : 70.0,
      isLargeScreen ? 100.0 : 85.0,
    );

    // Calculate adaptive spacing and sizing
    final horizontalPadding = screenSize.width * 0.06; // 6% of screen width
    final mainSpacing = isSmallScreen ? 8.h : (isLargeScreen ? 20.h : 12.h);
    final crossSpacing = screenSize.width * 0.08; // 8% of screen width

    // Calculate key size based on available space
    final availableHeight = screenSize.height * 0.35; // Use 35% of screen height max
    final keyHeight = (availableHeight / 4).clamp(
      isSmallScreen ? 50.0 : 60.0,  // min
      isLargeScreen ? 90.0 : 75.0,  // max
    );

    // Font size scaling
    final fontSize = isSmallScreen ? 20.sp : (isLargeScreen ? 28.sp : 24.sp);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true, // Important: take only needed space
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          itemCount: 12,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: mainSpacing,
            crossAxisSpacing: crossSpacing,
            childAspectRatio: 1.0, // Square keys instead of fixed extent
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
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: grey,
                ),
              );
              onTap = () => widget.onNumberPressed(number);
            }
            // Left action (index 9)
            else if (index == 9) {
              if (widget.leftAction == null) return const SizedBox();
              child = widget.leftAction!.child;
              onTap = widget.leftAction!.onTap;
              bgColor = widget.leftAction!.backgroundColor ?? keyAColor;
            }
            // 0 (index 10)
            else if (index == 10) {
              child = Text(
                "0",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: grey,
                ),
              );
              onTap = () => widget.onNumberPressed("0");
            }
            // Right action (index 11)
            else {
              if (widget.rightAction == null) return const SizedBox();
              child = widget.rightAction!.child;
              onTap = widget.rightAction!.onTap;
              bgColor = widget.rightAction!.backgroundColor ?? keyAColor;
            }

            final isSelected = _selectedIndex == index;

            return InkWell(
              borderRadius: BorderRadius.circular(50.r),
              splashColor: transparent,
              highlightColor: transparent,
              onTap: onTap == null
                  ? null
                  : () {
                setState(() => _selectedIndex = index);
                onTap!();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  color: isSelected ? lightBackground : bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha:0.25),
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