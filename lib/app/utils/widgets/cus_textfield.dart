import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final bool isPassword;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;
  final int? maxLines;
  final int? minLines;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.isPassword = false,
    this.readOnly = false,
    this.keyboardType,
    this.controller,
    this.textInputAction,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.validator,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
       // filled: true,
       // fillColor: widget.fillColor ?? Colors.grey.shade100,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20.sp, color: Colors.grey.shade600)
            : null,
        suffixIcon: widget.isPassword
            ? GestureDetector(
          onTap: () => setState(() => _obscureText = !_obscureText),
          child: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
            size: 20.sp,
          ),
        )
            : widget.suffixIcon != null
            ? GestureDetector(
          onTap: widget.onSuffixTap,
          child: Icon(
            widget.suffixIcon,
            size: 20.sp,
            color: Colors.grey.shade600,
          ),
        )
            : null,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide.none,
        ),
        errorBorder: baseBorder.copyWith(
            borderSide: BorderSide.none,),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric( vertical: 12.h),
      ),
      style: TextStyle(fontSize: 14.sp),
    );
  }
}