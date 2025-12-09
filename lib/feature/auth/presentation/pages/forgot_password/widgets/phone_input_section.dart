import 'package:flutter/material.dart';
import '../../../../modal/country_code.dart';

class PhoneInputSection extends StatelessWidget {
  final double screenWidth;
  final TextEditingController phoneController;
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode?> onCountryChanged;

  const PhoneInputSection({
    super.key,
    required this.screenWidth,
    required this.phoneController,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Country code dropdown with all countries
          Container(
            width: screenWidth < 375 ? 120 : 140,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: DropdownButton<CountryCode>(
              value: selectedCountry,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              iconSize: screenWidth < 375 ? 16 : 20,
              elevation: 16,
              style: TextStyle(
                fontSize: screenWidth < 375 ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              onChanged: onCountryChanged,
              items: CountryCodes.allCountries
                  .map<DropdownMenuItem<CountryCode>>((CountryCode country) {
                return DropdownMenuItem<CountryCode>(
                  value: country,
                  child: Row(
                    children: [
                      Text(
                        country.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          country.dialCode,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Phone number input
          Expanded(
            child: TextField(
              controller: phoneController,
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                hintText: 'Phone number',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
