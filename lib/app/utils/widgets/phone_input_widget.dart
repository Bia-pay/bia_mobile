import 'package:bia/app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../feature/auth/modal/country_code.dart';
import 'country_code_picker.dart';

class PhoneInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? label;
  final String? Function(String value) validator;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;
  final Color? hintColor;
  final ValueChanged<String>? onChanged;
  final CountryCode? initialCountry;
  final ValueChanged<CountryCode>? onCountryChanged;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isTablet;

  const PhoneInputWidget({
    super.key,
    required this.controller,
    required this.hintText,
    this.label,
    required this.validator,
    this.hintColor,
    this.onSubmitted,
    this.onChanged,
    this.readOnly = false,
    this.initialCountry,
    this.onCountryChanged,
    this.keyboardType,
    this.focusNode,
    this.textInputAction,
    this.backgroundColor,
    this.borderColor,
    this.isTablet = false,
  });

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  String? _errorText;
  late CountryCode _selectedCountry;
  late final VoidCallback _controllerListener;
  bool _hasInteracted = false;

  bool get _isKeyboardDisabled => widget.keyboardType == TextInputType.none;

  @override
  void initState() {
    super.initState();

    _selectedCountry =
        widget.initialCountry ??
            CountryCodes.allCountries.firstWhere(
                  (country) => country.code == 'NG',
              orElse: () => CountryCodes.allCountries.first,
            );

    _controllerListener = () {
      final text = widget.controller.text;
      
      if (text.isEmpty && !_hasInteracted) {
        if (_errorText != null) {
          setState(() => _errorText = null);
        }
        return;
      }

      final error = widget.validator(text);
      if (!mounted) return;
      if (error != _errorText) {
        setState(() => _errorText = error);
      }
    };

    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  void _onCountryChanged(CountryCode? newCountry) {
    if (newCountry != null && mounted) {
      setState(() => _selectedCountry = newCountry);
      widget.onCountryChanged?.call(newCountry);
    }
  }

  String get fullPhoneNumber {
    String phoneNumber = widget.controller.text.trim();
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }

    if (phoneNumber.length > 10) {
      phoneNumber = phoneNumber.substring(0, 10);
    }

    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    return '$dialCode$phoneNumber';
  }

  @override
  Widget build(BuildContext context) {
    final defaultBackground = Colors.grey.shade100;
    final defaultBorderColor = _errorText != null
        ? errorColor
        : Colors.grey[300]!;

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
        Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? defaultBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.borderColor ?? defaultBorderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CountryCodePicker(
                selectedCountry: _selectedCountry,
                onChanged: _onCountryChanged,
                showBorder: true,
                isTablet: widget.isTablet,
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: _isKeyboardDisabled
                      ? null
                      : [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _hasInteracted = true;
                    }
                    widget.onChanged?.call(value);
                  },
                  focusNode: widget.focusNode,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  readOnly: widget.readOnly || _isKeyboardDisabled,
                  enableInteractiveSelection: !_isKeyboardDisabled,
                  showCursor: !_isKeyboardDisabled,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: widget.hintText,
                    isDense: widget.isTablet,
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.hintColor ?? Colors.grey[400],
                      fontWeight: FontWeight.w400,
                      fontSize: widget.isTablet ? 12.5 : 13.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: widget.isTablet
                        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
                        : EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  ),
                  style: TextStyle(
                    fontSize: widget.isTablet ? 14 : 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h, left: 4.w),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: errorColor,
                fontSize: widget.isTablet ? 12 : 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
