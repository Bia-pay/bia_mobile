import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/header_section.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/phone_input_section.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/widgets/send_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/phone_input_widget.dart';
import '../../../../dashboard/widgets/keypad.dart';
import '../../../modal/country_code.dart';
import '../../../authcontroller/authcontroller.dart';

class ForgotPasswordScreen1 extends ConsumerStatefulWidget {
  const ForgotPasswordScreen1({super.key});

  @override
  ConsumerState<ForgotPasswordScreen1> createState() =>
      _ForgotPasswordScreen1State();
}

class _ForgotPasswordScreen1State extends ConsumerState<ForgotPasswordScreen1> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  int _selectedIndex = -1;
  bool showMinWarning = false;

  void addDigit(String value) {
    setState(() {
      String current = _phoneController.text.replaceAll('', '');

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      _phoneController.text = '$current';
      _codeController.text = _phoneController.text;

      _checkMinLimit();
    });
  }

  void removeDigit() {
    setState(() {
      String current = _phoneController.text.replaceAll('', '');

      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
      }

      if (current.isEmpty) {
        current = "0";
      }

      _phoneController.text = '$current';
      _codeController.text = _phoneController.text;

      _checkMinLimit();
    });
  }

  void _checkMinLimit() {
    final numericValue =
        num.tryParse(
          _phoneController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;

    showMinWarning = numericValue < 50 && numericValue != 0;
  }

  CountryCode _selectedCountry = CountryCodes.allCountries.firstWhere(
    (country) => country.code == 'NG',
    orElse: () => CountryCodes.allCountries.first,
  );

  bool _isPhoneNumberComplete = false; // Add this flag

  @override
  void initState() {
    super.initState();
    // Add listener to check when phone number is complete
    _phoneController.addListener(_checkPhoneNumberComplete);
  }

  Future<void> _sendForgotPasswordCode() async {
    // Extract clean phone number text
    String phoneNumber = _phoneController.text.trim();

    // Remove any non-numeric characters
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Remove leading 0
    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }

    // Dial code without "+"
    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');

    // Final number sent to API
    final fullPhoneNumber = '$dialCode$phoneNumber';

    debugPrint('Sending code to: $fullPhoneNumber (${_selectedCountry.name})');

    // Call API
    final authController = ref.read(authControllerProvider.notifier);
    final response = await authController.forgotPassword(
      context,
      fullPhoneNumber,
    );

    // Navigate if successful
    if (response != null && response.responseSuccessful) {
      if (!mounted) return;
      context.pushNamed(RouteList.forgotPasswordReset, extra: fullPhoneNumber);
    }
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
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.goNamed(
                RouteList.loginScreen,
              ); // Navigate to login as fallback
            }
          },
          icon: Icon(Icons.arrow_back_ios, color: darkBackground),
        ),
        title: const Text('Forgot password'),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        foregroundColor: darkBackground,
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
              if (!isSmallScreen) SizedBox(height: 20.h),
              // Header section
              SizedBox(height: 20.h),Container(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.all(Radius.circular(10.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05), // very light shadow
                      blurRadius: 8,
                      offset: const Offset(0, 2), // slight downward shadow
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhoneInputWidget(
                      controller: _phoneController,
                      label: 'Mobile Number',
                      hintText: '8000000000',
                      keyboardType: TextInputType.none,
                      backgroundColor: lightBackground,
                      borderColor: borderColor,
                      validator: (value) {
                        if (value.isEmpty) return 'Phone number is required';
                        if (value.length < 10) return 'Phone number too short';
                        return null;
                      },
                      onCountryChanged: (CountryCode? newValue) {
                        setState(() {
                          _selectedCountry = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 30.h),
                    Text(
                      "We'll send you a code to verify your phone number",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.spMin,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 80.h),
              SizedBox(
                height: 350.h,
                child: CustomGridKeypad(
                  onNumberPressed: (value) {
                    addDigit(value);
                  },

                  // Bottom-left action → delete
                  leftAction: ActionKey(
                    child: SvgPicture.asset(
                      'assets/svg/cancel.svg',
                      height: 20.h,
                      colorFilter: ColorFilter.mode(
                        primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    backgroundColor: primaryColor.withOpacity(0.1),
                    onTap: removeDigit,
                  ),

                  // Bottom-right action → send code
                  rightAction: ActionKey(
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                    backgroundColor: primaryColor,
                    onTap: _isPhoneNumberComplete
                        ? _sendForgotPasswordCode
                        : () {}, // or null if you later add disabled support
                  ),
                ),
              ),
              // Number pad
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
