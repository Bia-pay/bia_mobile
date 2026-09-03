import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isTablet = MediaQuery.of(context).size.width > 600;

    final h = widget.height ?? (isTablet ? AppSearchField.defaultHeight : AppSearchField.defaultHeight.h);
    final fillColor =
    widget.isBackgroundTransparent ? Colors.transparent : lightgray;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Container(
      width: widget.width ?? (isTablet ? AppSearchField.defaultWidth : AppSearchField.defaultWidth.w),
      height: h,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(isTablet ? 14.0 : 20.r),
      ),
      child: TextField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: isTablet ? 14.0 : 14.sp,
          color: textColor,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 14.0 : 20.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 14.0 : 20.r),
            borderSide: const BorderSide(
              color: Colors.transparent,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 14.0 : 20.r),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          hintText: widget.hintText ?? 'Search',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: isTablet ? 14.0 : 14.sp,
            color: lightSecondaryText,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: isTablet ? 10.0 : 10.w, right: isTablet ? 6.0 : 6.w),
            child: Icon(
              Icons.search,
              color: widget.readOnly ? theme.disabledColor : primaryColor,
              size: isTablet ? 20.0 : 22.sp,
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
              color: lightSecondaryText,
              size: isTablet ? 18.0 : 20.sp,
            ),
          )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: isTablet ? 10.0 : 10.h),
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
    this.maxLength,
    this.inputFormatters,
    this.keyboardType,
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
    this.maxLength,
    this.inputFormatters,
    this.keyboardType,
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

  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;

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
    final isTablet = MediaQuery.of(context).size.width > 600;

    final h = widget.height ?? (isTablet ? 50.0 : AppField.defaultHeight.h);
    final fillColor =
    widget.isBackgroundTransparent ? Colors.transparent : lightgray;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Container(
      width: widget.width ?? (isTablet ? AppField.defaultWidth : AppField.defaultWidth.w),
      height: h,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 20.r),
      ),
      child: TextField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.center,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        maxLines: 1,

        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        keyboardType: widget.keyboardType,
        buildCounter: (
            context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
          return null;
        },

        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: isTablet ? 14.0 : 14.sp,
          color: textColor,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 20.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 10.0 : 10.r),
            borderSide: const BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 10.0 : 10.r),
            borderSide: const BorderSide(
              color: secondaryColor,
              width: 2,
            ),
          ),
          hintText: widget.hintText ?? 'Enter value',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: isTablet ? 13.5 : 13.sp,
            color: lightSecondaryText,
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
              color: lightSecondaryText,
              size: isTablet ? 18.0 : 20.sp,
            ),
          )
              : null,
          contentPadding:
          EdgeInsets.symmetric(horizontal: isTablet ? 14.0 : 16.w, vertical: isTablet ? 10.0 : 10.h),
        ),
      ),
    );
  }
}