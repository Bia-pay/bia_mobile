import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../colors.dart';

class CustomKeypad extends StatefulWidget {
  final Function(String) onKeyPressed;
  final List<String>? customKeys;
  final Color? keyColor;
  final Color? textColor;
  final Color? activeKeyColor;
  final Color? activeTextColor;
  final double? keySize;
  final EdgeInsets? padding;
  final double? spacing;

  const CustomKeypad({
    super.key,
    required this.onKeyPressed,
    this.customKeys,
    this.keyColor,
    this.textColor,
    this.activeKeyColor,
    this.activeTextColor,
    this.keySize,
    this.padding,
    this.spacing,
  });

  @override
  State<CustomKeypad> createState() => _CustomKeypadState();
}

class _CustomKeypadState extends State<CustomKeypad> {
  int _selectedIndex = -1;

  List<String> get keys => widget.customKeys ?? ["1","2","3","4","5","6","7","8","9","delete","0","submit"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GridView.builder(
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 25.w),
      itemCount: keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: widget.spacing ?? 16.h,
        crossAxisSpacing: widget.spacing ?? 35.w,
        mainAxisExtent: widget.keySize ?? 70.h,
      ),
      itemBuilder: (context, index) {
        String key = keys[index];
        return _buildKey(context, theme, key, index);
      },
    );
  }

  Widget _buildKey(BuildContext context, ThemeData theme, String key, int index) {
    Color keyColor = widget.keyColor ?? keyAColor;
    Color textColor = widget.textColor ?? lightSecondaryText;
    
    // Special key styling
    if (key == "delete") {
      keyColor = primaryColor.withOpacity(0.1);
      textColor = primaryColor;
    } else if (key == "submit") {
      keyColor = primaryColor;
      textColor = whiteBackground;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(50.r),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        setState(() => _selectedIndex = index);
        widget.onKeyPressed(key);
        
        // Reset selection after a short delay
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() => _selectedIndex = -1);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _selectedIndex == index 
              ? (widget.activeKeyColor ?? Colors.white)
              : keyColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedIndex == index 
                ? primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: _buildKeyContent(theme, key, textColor, index),
      ),
    );
  }

  Widget _buildKeyContent(ThemeData theme, String key, Color textColor, int index) {
    if (key == "delete") {
      return SvgPicture.asset(
        'assets/svg/cancel.svg',
        height: 20.h,
        colorFilter: ColorFilter.mode(
          _selectedIndex == index ? primaryColor : primaryColor,
          BlendMode.srcIn,
        ),
      );
    } else if (key == "submit") {
      return Icon(
        Icons.arrow_forward,
        color: _selectedIndex == index 
            ? primaryColor 
            : (widget.activeTextColor ?? textColor),
        size: 24.sp,
      );
    } else {
      return Text(
        key,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: _selectedIndex == index 
              ? primaryColor 
              : lightText,
          fontWeight: FontWeight.w500,
          fontSize: 24.sp,
        ),
      );
    }
  }
}

// Alternative keypad layouts
class KeypadLayouts {
  static const List<String> standard = [
    "1","2","3","4","5","6","7","8","9","delete","0","submit"
  ];
  
  static const List<String> withClear = [
    "1","2","3","4","5","6","7","8","9","clear","0","submit"
  ];
  
  static const List<String> minimal = [
    "1","2","3","4","5","6","7","8","9","","0","submit"
  ];
}