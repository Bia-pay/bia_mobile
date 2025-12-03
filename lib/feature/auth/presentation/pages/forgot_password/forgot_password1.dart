import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/header_section.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/number_pad_section.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/phone_input_section.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/send_button.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/verification_section.dart';
import 'package:flutter/material.dart';
import '../../../modal/country_code.dart';

class ForgotPasswordScreen1 extends StatefulWidget {
  const ForgotPasswordScreen1({super.key});

  @override
  State<ForgotPasswordScreen1> createState() => _ForgotPasswordScreen1State();
}

class _ForgotPasswordScreen1State extends State<ForgotPasswordScreen1> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  CountryCode _selectedCountry = CountryCodes.allCountries.firstWhere(
        (country) => country.code == 'NG',
    orElse: () => CountryCodes.allCountries.first,
  );

  bool _isPhoneNumberComplete = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _phoneController.text = '0398829xxx';
    // Add listener to check when phone number is complete
    _phoneController.addListener(_checkPhoneNumberComplete);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_checkPhoneNumberComplete);
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // Method to check if phone number is complete
  void _checkPhoneNumberComplete() {
    final phoneNumber = _phoneController.text;

    // Define your criteria for a complete phone number
    // Example: Phone number should have at least 10 digits (excluding country code)
    // Adjust this based on your requirements
    bool isComplete = phoneNumber.replaceAll(RegExp(r'\D'), '').length >= 10;

    if (_isPhoneNumberComplete != isComplete) {
      setState(() {
        _isPhoneNumberComplete = isComplete;
      });
    }
  }

  void _handleNumberPress(String number) {
    if (number == '.') return;

    final currentText = _codeController.text;
    setState(() {
      if (number == 'backspace') {
        if (currentText.isNotEmpty) {
          _codeController.text = currentText.substring(
            0,
            currentText.length - 1,
          );
        }
      } else {
        _codeController.text = currentText + number;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _getHorizontalPadding(screenWidth),
            vertical: _getVerticalPadding(screenHeight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSmallScreen) const SizedBox(height: 20),

              // Header section
              HeaderSection(screenWidth: screenWidth),
              const SizedBox(height: 30),

              // Phone input section
              PhoneInputSection(
                screenWidth: screenWidth,
                phoneController: _phoneController,
                selectedCountry: _selectedCountry,
                onCountryChanged: (CountryCode? newValue) {
                  setState(() {
                    _selectedCountry = newValue!;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Show message only when phone number is complete
              if (_isPhoneNumberComplete) ...[
                Text(
                  'We texted you a code to verify your phone number',
                  style: TextStyle(
                    fontSize: screenWidth < 375 ? 12 : 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // Verification section - show when phone number is complete
              if (_isPhoneNumberComplete) ...[
                VerificationSection(
                  screenWidth: screenWidth,
                  codeController: _codeController,
                ),
                const SizedBox(height: 30),
              ],

              // Send button - enable/disable based on phone number completion
              SendButton(
                screenWidth: screenWidth,
                isEnabled: _isPhoneNumberComplete,
                onPressed: _isPhoneNumberComplete
                    ? () {
                  final fullPhoneNumber =
                      '${_selectedCountry.dialCode}${_phoneController.text}';
                  debugPrint(
                    'Sending code to: $fullPhoneNumber (${_selectedCountry.name})',
                  );
                }
                    : null, // Disable button if phone not complete
              ),
              const SizedBox(height: 30),

              // Number pad
              NumberPadSection(
                screenWidth: screenWidth,
                onNumberPressed: _handleNumberPress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth < 375) return 16.0;
    if (screenWidth < 600) return 24.0;
    if (screenWidth < 900) return 32.0;
    return screenWidth * 0.1;
  }

  double _getVerticalPadding(double screenHeight) {
    if (screenHeight < 600) return 12.0;
    if (screenHeight < 700) return 16.0;
    if (screenHeight < 900) return 20.0;
    return 24.0;
  }
}