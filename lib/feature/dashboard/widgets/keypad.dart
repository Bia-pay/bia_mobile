import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app/utils/colors.dart';

typedef KeypadCallback = void Function(String key);

class CustomGridKeypad extends StatefulWidget {
  final KeypadCallback onKeyPressed;

  const CustomGridKeypad({super.key, required this.onKeyPressed});

  @override
  State<CustomGridKeypad> createState() => _CustomGridKeypadState();
}

class _CustomGridKeypadState extends State<CustomGridKeypad> {
  int? _selectedIndex;

  final List<String> _keys = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "x",
    "0",
    "ok",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 25.w),
      itemCount: _keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 35.w,
        mainAxisExtent: 70.h,
      ),
      itemBuilder: (context, index) {
        final key = _keys[index];

        Color keyColor = keyAColor;
        Color textColor = Colors.grey;

        if (key == "x") {
          keyColor = primaryColor.withOpacity(0.1);
          textColor = primaryColor;
        } else if (key == "ok") {
          keyColor = primaryColor;
          textColor = Colors.white;
        }

        final isSelected = _selectedIndex == index;

        return InkWell(
          borderRadius: BorderRadius.circular(50.r),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            setState(() => _selectedIndex = index);
            widget.onKeyPressed(key);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : keyColor,
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
            child: key == "x"
                ? SvgPicture.asset(
              'assets/svg/cancel.svg',
              height: 20.h,
              colorFilter: ColorFilter.mode(
                primaryColor,
                BlendMode.srcIn,
              ),
            )
                : key == "ok"
                ? Icon(
              Icons.arrow_forward,
              color: isSelected ? primaryColor : textColor,
              size: 24.sp,
            )
                : Text(
              key,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isSelected ? primaryColor : Colors.grey,
                fontSize: 24.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}