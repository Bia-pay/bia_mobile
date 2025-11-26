import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 🔍 Search Field Widget
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.width,
    this.height,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.withClearButton = false,
    this.readOnly = false,
  }) : isBackgroundTransparent = false;

  const AppSearchField.transparent({
    super.key,
    this.width,
    this.height,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.withClearButton = false,
    this.readOnly = false,
  }) : isBackgroundTransparent = true;

  static const double defaultHeight = 48;
  static const double defaultWidth = 326;

  final double? width;
  final double? height;
  final String? initialValue;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool withClearButton;
  final bool readOnly;
  final bool isBackgroundTransparent;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    final h = widget.height ?? AppSearchField.defaultHeight.h;
    final fillColor =
    widget.isBackgroundTransparent ? Colors.transparent : themeContext.lightGray;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Container(
      width: widget.width ?? AppSearchField.defaultWidth.w,
      height: h,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: TextField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
          color: textColor,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText ?? 'Search',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            color: themeContext.secondaryTextColor,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 10.w, right: 6.w),
            child: Icon(
              Icons.search,
              color: widget.readOnly
                  ? theme.disabledColor
                  : themeContext.kPrimary,
              size: 22.sp,
            ),
          ),
          suffixIcon: widget.withClearButton
              ? IconButton(
            onPressed: widget.readOnly
                ? null
                : () {
              _controller.clear();
              widget.onChanged?.call('');
            },
            icon: Icon(
              Icons.clear,
              color: themeContext.secondaryTextColor,
              size: 20.sp,
            ),
          )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }
}

/// 🧾 General App Field
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    this.width,
    this.height,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.withClearButton = false,
    this.readOnly = false,
  }) : isBackgroundTransparent = false;

  const AppField.transparent({
    super.key,
    this.width,
    this.height,
    this.initialValue,
    this.onChanged,
    this.hintText,
    this.withClearButton = false,
    this.readOnly = false,
  }) : isBackgroundTransparent = true;

  static const double defaultHeight = 58;
  static const double defaultWidth = 326;

  final double? width;
  final double? height;
  final String? initialValue;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool withClearButton;
  final bool readOnly;
  final bool isBackgroundTransparent;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant AppField oldWidget) {
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    final h = widget.height ?? AppField.defaultHeight.h;
    final fillColor =
    widget.isBackgroundTransparent ? Colors.transparent : themeContext.lightGray;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Container(
      width: widget.width ?? AppField.defaultWidth.w,
      height: h,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: TextField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        maxLines: 1,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
          color: textColor,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText ?? 'Enter value',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13.sp,
            color: themeContext.secondaryTextColor,
          ),
          suffixIcon: widget.withClearButton
              ? IconButton(
            onPressed: widget.readOnly
                ? null
                : () {
              _controller.clear();
              widget.onChanged?.call('');
            },
            icon: Icon(
              Icons.clear,
              color: themeContext.secondaryTextColor,
              size: 20.sp,
            ),
          )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        ),
      ),
    );
  }
}