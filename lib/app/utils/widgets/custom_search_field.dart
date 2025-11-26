import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autoFocus;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.autoFocus = false,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  void _clearField() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.fillColor ?? Colors.grey.shade100;
    final border = widget.borderColor ?? Colors.grey.shade300;

    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 12.r),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          /// 🔍 Search Icon
          Icon(Icons.search_rounded,
              color: Colors.grey.shade600, size: 20.sp),

          SizedBox(width: 8.w),

          /// ✏️ Input Field
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autoFocus,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {});
                widget.onChanged?.call(value);
              },
            ),
          ),

          /// ❌ Clear Icon
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clearField,
              child: Icon(Icons.close_rounded,
                  color: Colors.grey.shade600, size: 18.sp),
            ),
        ],
      ),
    );
  }
}