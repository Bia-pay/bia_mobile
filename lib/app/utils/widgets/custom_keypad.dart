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
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final double mainExtent = isTablet ? (widget.keySize ?? 60.0) : (widget.keySize ?? 70.h);
    final double spacingValue = isTablet ? (widget.spacing ?? 14.0) : (widget.spacing ?? 16.h);
    final EdgeInsets paddingValue = isTablet 
        ? (widget.padding ?? const EdgeInsets.symmetric(horizontal: 20.0))
        : (widget.padding ?? EdgeInsets.symmetric(horizontal: 25.w));

    Widget grid = GridView.builder(
      padding: paddingValue,
      itemCount: keys.length,
      shrinkWrap: isTablet,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: spacingValue,
        crossAxisSpacing: isTablet ? 20.0 : (widget.spacing ?? 35.w),
        mainAxisExtent: mainExtent,
      ),
      itemBuilder: (context, index) {
        String key = keys[index];
        return _buildKey(context, theme, key, index, isTablet);
      },
    );

    if (isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: grid,
        ),
      );
    }

    return grid;
  }

  Widget _buildKey(BuildContext context, ThemeData theme, String key, int index, bool isTablet) {
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
        child: _buildKeyContent(theme, key, textColor, index, isTablet),
      ),
    );
  }

  Widget _buildKeyContent(ThemeData theme, String key, Color textColor, int index, bool isTablet) {
    if (key == "delete") {
      return SvgPicture.asset(
        'assets/svg/cancel.svg',
        height: isTablet ? 18.0 : 20.h,
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
        size: isTablet ? 20.0 : 24.sp,
      );
    } else {
      return Text(
        key,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: _selectedIndex == index 
              ? primaryColor 
              : lightText,
          fontWeight: FontWeight.w500,
          fontSize: isTablet ? 22.0 : 24.sp,
        ),
      );
    }
  }
}

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