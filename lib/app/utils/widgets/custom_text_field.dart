import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final String? Function(String value) validator;
  final bool obscureText;
  final bool readOnly; // 👈 Added this line
  final IconData? icons;
  final ValueChanged<String>? onSubmitted;
  final String? images;
  final Color? hintColor;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

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
    this.readOnly = false, // 👈 Default false
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final error = widget.validator(widget.controller.text);
      if (error != _errorText) {
        setState(() {
          _errorText = error;
        });
      }
    });
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
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13.spMin,
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          readOnly: widget.readOnly, // 👈 Now supported
          decoration: InputDecoration(
            counterText: "",
            prefixIcon: widget.icons != null
                ? Icon(widget.icons, color: Colors.grey, size: 18.sp)
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
            hintStyle: context.textTheme.bodySmall?.copyWith(
              color: widget.hintColor ?? Colors.grey[400],
              fontWeight: FontWeight.w400,
              fontSize: 13.sp,
            ),
            errorText: _errorText,
            filled: true,
            fillColor: Colors.grey.shade100,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
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
        ),
      ],
    );
  }
}