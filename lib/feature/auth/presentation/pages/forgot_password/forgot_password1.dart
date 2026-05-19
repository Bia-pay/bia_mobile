import 'dart:ui';
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

  bool showMinWarning = false;

  void addDigit(String value) {
    setState(() {
      String current = _phoneController.text;

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      _phoneController.text = current;
      _codeController.text = _phoneController.text;

      _checkMinLimit();
    });
  }

  void removeDigit() {
    setState(() {
      String current = _phoneController.text;

      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
      }

      if (current.isEmpty) {
        current = "0";
      }

      _phoneController.text = current;
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

  bool _isPhoneNumberComplete = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkPhoneNumberComplete);
  }

  Future<void> _sendForgotPasswordCode() async {
    String phoneNumber = _phoneController.text.trim();
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }

    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    final fullPhoneNumber = '$dialCode$phoneNumber';

    final authController = ref.read(authControllerProvider.notifier);
    final response = await authController.forgotPassword(
      context,
      fullPhoneNumber,
    );

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

  void _checkPhoneNumberComplete() {
    final phoneNumber = _phoneController.text
        .replaceAll(RegExp(r'\D'), '')
        .trim();
    final isComplete =
        (phoneNumber.length == 10 && !phoneNumber.startsWith('0')) ||
        (phoneNumber.length == 11 && phoneNumber.startsWith('0'));

    if (_isPhoneNumberComplete != isComplete) {
      setState(() {
        _isPhoneNumberComplete = isComplete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhiteBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 700;
            final isLargeScreen = screenHeight > 900;

            final keypadHeight = isSmallScreen
                ? screenHeight * 0.42
                : (isLargeScreen ? screenHeight * 0.5 : screenHeight * 0.45);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _getHorizontalPadding(screenWidth),
                    isSmallScreen ? 12.h : 20.h,
                    _getHorizontalPadding(screenWidth),
                    0,
                  ),
                  child: _buildCustomHeader(isSmallScreen),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getHorizontalPadding(screenWidth),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        /// 🔹 Lock Icon & Header Text
                        Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                size: 40.sp,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "Reset Your Password",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: darkBackground,
                                  ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Enter your registered mobile number below.\nWe'll send you an OTP to verify your identity.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isSmallScreen ? 11.sp : 13.sp,
                                    color: lightSecondaryText,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        /// 🔹 Glass Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12.w : 16.w,
                                vertical: isSmallScreen ? 16.h : 30.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: lightBorderColor.withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PhoneInputWidget(
                                    controller: _phoneController,
                                    label: 'Mobile Number',
                                    hintText: '800 000 0000',
                                    keyboardType: TextInputType.none,
                                    backgroundColor: offWhite,
                                    borderColor: Colors.transparent,
                                    validator: (value) {
                                      if (value.isEmpty)
                                        return 'Phone number is required';
                                      final text = value.trim();
                                      if (text.length == 11 &&
                                          !text.startsWith('0')) {
                                        return '11-digit number must start with 0';
                                      }
                                      if (text.length != 10 &&
                                          text.length != 11) {
                                        return 'Phone number must be 10 or 11 digits';
                                      }
                                      return null;
                                    },
                                    onCountryChanged: (CountryCode? newValue) {
                                      setState(() {
                                        _selectedCountry = newValue!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        /// 🔹 Keypad
                        SizedBox(
                          height: keypadHeight,
                          child: CustomGridKeypad(
                            onNumberPressed: addDigit,
                            leftAction: ActionKey(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: _isPhoneNumberComplete
                                    ? lightBackground
                                    : lightBackground.withValues(alpha: 0.5),
                                size: isSmallScreen ? 20.sp : 24.sp,
                              ),
                              backgroundColor: _isPhoneNumberComplete
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.3),
                              onTap: _isPhoneNumberComplete
                                  ? () => _sendForgotPasswordCode()
                                  : () {},
                            ),
                            rightAction: ActionKey(
                              child: Icon(
                                Icons.backspace_rounded,
                                color: primaryColor,
                                size: isSmallScreen ? 20.sp : 24.sp,
                              ),
                              backgroundColor: primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              onTap: removeDigit,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomHeader(bool isSmallScreen) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteList.loginScreen);
            }
          },
          child: Icon(
            Icons.arrow_back_ios_new,
            size: isSmallScreen ? 16.sp : 18.sp,
            color: darkBackground,
          ),
        ),
        SizedBox(width: isSmallScreen ? 32.w : 46.w),
        Expanded(
          child: Text(
            "",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 16.sp : 20.sp,
            ),
          ),
        ),
      ],
    );
  }

  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth < 375) return 16.0;
    if (screenWidth < 600) return 24.0;
    if (screenWidth < 900) return 32.0;
    return screenWidth * 0.1;
  }
}
