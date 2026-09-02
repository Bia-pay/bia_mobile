import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonName,
    this.onPressed,
    this.textStyle,
    this.buttonBorderColor,
    this.icon,
    this.imageAsset,
    this.svgAsset,
    this.iconSize,
    this.spacing,
    this.isLoading = false,
    this.elevation = 4.0,
    this.borderRadius = 14.0,
  });

  final Color buttonColor;
  final Color buttonTextColor;
  final String buttonName;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final Color? buttonBorderColor;

  // Icon options
  final IconData? icon;
  final String? imageAsset;
  final String? svgAsset;

  final double? iconSize;
  final double? spacing;
  final bool isLoading;
  final double elevation;
  final double borderRadius;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    Widget? leading;

    if (widget.icon != null) {
      leading = Icon(
        widget.icon,
        size: widget.iconSize ?? 20.sp,
        color: widget.buttonTextColor,
      );
    } else if (widget.imageAsset != null) {
      leading = Image.asset(
        widget.imageAsset!,
        width: widget.iconSize ?? 20.sp,
        height: widget.iconSize ?? 20.sp,
      );
    } else if (widget.svgAsset != null) {
      leading = SvgPicture.asset(
        widget.svgAsset!,
        width: widget.iconSize ?? 20.sp,
        height: widget.iconSize ?? 20.sp,
        colorFilter: ColorFilter.mode(
          widget.buttonTextColor,
          BlendMode.srcIn,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        if (!widget.isLoading && widget.onPressed != null) {
          HapticFeedback.mediumImpact();
          widget.onPressed!();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.width > 600 ? 0 : 14.h,
            horizontal: MediaQuery.of(context).size.width > 600 ? 8 : 16.w,
          ),
          decoration: BoxDecoration(
            color: widget.buttonColor.withOpacity(isDisabled ? 0.6 : 1.0),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.buttonBorderColor ?? Colors.transparent,
              width: 1.w,
            ),
            boxShadow: isDisabled || widget.buttonColor == Colors.transparent
                ? []
                : [
                    BoxShadow(
                      color: widget.buttonColor.withOpacity(0.3),
                      blurRadius: widget.elevation * 2,
                      offset: Offset(0, widget.elevation),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24.sp,
                    width: 24.sp,
                    child: CircularProgressIndicator(
                      color: widget.buttonTextColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading,
                        SizedBox(width: widget.spacing ?? 12.w),
                      ],
                      Text(
                        widget.buttonName,
                        style: widget.textStyle ??
                            theme.textTheme.bodyLarge?.copyWith(
                              color: widget.buttonTextColor
                                  .withOpacity(isDisabled ? 0.8 : 1.0),
                              fontWeight: FontWeight.w700,
                              fontSize: MediaQuery.of(context).size.width > 600
                                  ? 16
                                  : null,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}