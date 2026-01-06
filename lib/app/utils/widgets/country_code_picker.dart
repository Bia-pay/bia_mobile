import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../feature/auth/modal/country_code.dart';

class CountryCodePicker extends StatelessWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode?> onChanged;
  final bool showBorder;

  const CountryCodePicker({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                right: BorderSide(color: Colors.grey.shade300),
              )
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CountryCode>(
          value: selectedCountry,
          isDense: true,
          items: CountryCodes.allCountries.map((CountryCode country) {
            return DropdownMenuItem<CountryCode>(
              value: country,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    country.flag,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    country.dialCode,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[600],
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}