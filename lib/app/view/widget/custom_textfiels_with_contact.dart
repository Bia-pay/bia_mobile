// lib/app/utils/widgets/custom_text_field_with_contacts.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/colors.dart';
import '../../utils/widgets/contact_picker.dart';

class CustomTextFieldWithContacts extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hint;
  final int? maxLength;
  final Function(String)? onChanged;
  final Function(String phone, String? name)? onContactSelected;
  final bool enabled;

  const CustomTextFieldWithContacts({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.hint = '',
    this.maxLength,
    this.onChanged,
    this.onContactSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isTablet = size.width > 600;
    final isLandscape = size.width > size.height;

    // Responsive dimensions
    final iconSize = isTablet ? 22.0 : (isSmall ? 20.sp : 24.sp);
    final fontSize = isTablet ? 15.0 : (isSmall ? 14.sp : 16.sp);
    final hintFontSize = isTablet ? 13.5 : (isSmall ? 12.sp : 14.sp);
    final fieldHeight = isTablet ? 44.0 : (isSmall ? 44.h : 48.h);
    final horizontalPadding = isTablet ? 10.0 : (isSmall ? 8.w : 12.w);

    return SizedBox(
      height: fieldHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left spacer to balance the icon (invisible but takes space)

          // Centered text field
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              enabled: enabled,
              //textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: semiTransparentBlack,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: grey400,
                  fontSize: hintFontSize,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
                // Remove all default padding
                filled: false,
              ),
              onChanged: onChanged,
            ),
          ),

          // Right side: Contacts icon (centered vertically)
          SizedBox(
            width: iconSize + horizontalPadding,
            child: Center(
              child: ContactsPickerSuffix(
                iconSize: iconSize,
                onContactSelected: (phone, name) {
                  controller.text = phone;
                  onChanged?.call(phone);
                  onContactSelected?.call(phone, name);
                },
                iconColor: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}