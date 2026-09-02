import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final String? Function(String value) validator;
  final bool obscureText;
  final bool readOnly;
  final IconData? icons;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final String? images;
  final Color? hintColor;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool isTablet;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.label,
    required this.validator,
    this.hintColor,
    this.icons,
    this.images,
    this.onSubmitted,
    this.inputFormatters,
    this.suffixIcon,
    this.onChanged,
    this.maxLength,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.textInputAction,
    this.focusNode,
    this.autofillHints,
    this.isTablet = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  String? _errorText;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();

    _listener = () {
      if (!mounted) return;

      final error = widget.validator(widget.controller.text);

      if (error != _errorText) {
        setState(() {
          _errorText = error;
        });
      }
    };

    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 5.h),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: widget.isTablet ? 13 : 13.spMin,
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          autofillHints: widget.autofillHints,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          focusNode: widget.focusNode,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          textInputAction: widget.textInputAction,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            counterText: "",
            prefixIcon: widget.icons != null
                ? Icon(widget.icons, color: Colors.grey, size: widget.isTablet ? 18 : 18.sp)
                : widget.images != null
                ? Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Image.asset(
                      widget.images!,
                      width: 14.w,
                      height: 14.w,
                      fit: BoxFit.contain,
                    ),
                  )
                : null,
            suffixIcon: widget.suffixIcon,
            hintText: widget.hintText,
            isDense: widget.isTablet,
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.hintColor ?? Colors.grey[400],
              fontWeight: FontWeight.w400,
              fontSize: widget.isTablet ? 12.5 : 13.sp,
            ),
            errorText: _errorText,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: widget.isTablet
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
                : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          style: TextStyle(
            fontSize: widget.isTablet ? 14 : 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
