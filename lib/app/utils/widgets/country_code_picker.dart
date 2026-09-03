import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../feature/auth/modal/country_code.dart';

class CountryCodePicker extends StatelessWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode?> onChanged;
  final bool showBorder;
  final bool isTablet;

  const CountryCodePicker({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
    this.showBorder = true,
    this.isTablet = false,
  });

  void _showCountryPickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CountryPickerDialog(
          selectedCountry: selectedCountry,
          onChanged: onChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = this.isTablet || MediaQuery.of(context).size.width > 600;
    return GestureDetector(
      onTap: () => _showCountryPickerDialog(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: isTablet
            ? const EdgeInsets.only(left: 14, right: 10, top: 10, bottom: 10)
            : EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  right: BorderSide(color: Colors.grey.shade300),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flag,
              style: TextStyle(fontSize: isTablet ? 16 : 18.sp),
            ),
            SizedBox(width: isTablet ? 4 : 6.w),
            Text(
              selectedCountry.dialCode,
              style: TextStyle(
                fontSize: isTablet ? 13 : 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0C284E),
              ),
            ),
            SizedBox(width: isTablet ? 2 : 2.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[600],
              size: isTablet ? 16 : 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerDialog extends StatefulWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode?> onChanged;

  const _CountryPickerDialog({
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCountries = CountryCodes.allCountries.where((country) {
      final nameMatches = country.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final codeMatches = country.dialCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || codeMatches;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Drag Handle
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          // Title
          Text(
            'Select Country',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0C284E),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16.h),
          // Search Input
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: TextStyle(
                  color: const Color(0xFF0C284E),
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search country or code...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[600],
                    size: 22.sp,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: Colors.grey[600], size: 20.sp),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Country List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: ListTile(
                    onTap: () {
                      widget.onChanged(country);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0x1426B4DF), // 8% opacity of primaryColor
                    leading: Text(
                      country.flag,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: const Color(0xFF0C284E),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.dialCode,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF26B4DF) : Colors.grey[600],
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 10.w),
                          Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFF26B4DF),
                            size: 20.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}