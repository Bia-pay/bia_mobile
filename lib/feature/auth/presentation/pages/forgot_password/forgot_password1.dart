import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _isPhoneNumberComplete = false;

  CountryCode _selectedCountry = CountryCodes.allCountries.firstWhere(
    (country) => country.code == 'NG',
    orElse: () => CountryCodes.allCountries.first,
  );

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkPhoneNumberComplete);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_checkPhoneNumberComplete);
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: isTablet ? accentColor : Colors.white,
      body: isTablet
          ? _buildTabletLayout(context, theme)
          : _buildPhoneLayout(context, theme),
    );
  }

  Widget _buildTabletLayout(BuildContext context, ThemeData theme) {
    return Stack(
      children: [
        _buildBackgroundOrbs(),
        SafeArea(
          child: Row(
            children: [
              // Left Side: Brand Panel (Flex 4)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button & Step Badge
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (GoRouter.of(context).canPop()) {
                                context.pop();
                              } else {
                                context.goNamed(RouteList.loginScreen);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'PASSWORD RECOVERY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn().scale(),

                      const Spacer(),

                      Text(
                        'Forgot Your\nPassword?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const SizedBox(height: 12),

                      Text(
                        "Enter your registered mobile number. We will send an OTP code to verify your identity.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const Spacer(flex: 2),

                      // Trust Badge
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_reset_rounded, color: primaryColor, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'SMS Verification Code & Secure Access Recovery',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),

              // Right Side: Form Card (Flex 6)
              Expanded(
                flex: 6,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      bottomLeft: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(-10, 0),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Title inside Card
                            Text(
                              'Enter Registered Phone',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkBackground,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'We will send a 6-digit OTP code to verify your phone number.',
                              style: TextStyle(
                                fontSize: 13,
                                color: lightSecondaryText,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Phone Input Box
                            PhoneInputWidget(
                              controller: _phoneController,
                              label: 'Mobile Number',
                              hintText: '800 000 0000',
                              keyboardType: TextInputType.none,
                              backgroundColor: offWhiteBackground,
                              borderColor: Colors.grey[300],
                              isTablet: true,
                              validator: (value) {
                                if (value.isEmpty) return 'Phone number is required';
                                final text = value.trim();
                                if (text.length == 11 && !text.startsWith('0')) {
                                  return '11-digit number must start with 0';
                                }
                                if (text.length != 10 && text.length != 11) {
                                  return 'Phone number must be 10 or 11 digits';
                                }
                                return null;
                              },
                              onCountryChanged: (CountryCode? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedCountry = newValue);
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            // Grid Keypad
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 340),
                                child: CustomGridKeypad(
                                  onNumberPressed: addDigit,
                                  leftAction: ActionKey(
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: _isPhoneNumberComplete
                                          ? lightBackground
                                          : lightBackground.withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                    backgroundColor: _isPhoneNumberComplete
                                        ? primaryColor
                                        : primaryColor.withValues(alpha: 0.3),
                                    onTap: _isPhoneNumberComplete
                                        ? () => _sendForgotPasswordCode()
                                        : () {},
                                  ),
                                  rightAction: ActionKey(
                                    child: const Icon(
                                      Icons.backspace_rounded,
                                      color: primaryColor,
                                      size: 22,
                                    ),
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    onTap: removeDigit,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context, ThemeData theme) {
    return Stack(
      children: [
        Positioned(
          top: -100.h,
          right: -100.w,
          width: 300.w,
          height: 300.h,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -150.h,
          left: -150.w,
          width: 350.w,
          height: 350.h,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondaryColor.withOpacity(0.4),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              final isSmallScreen = screenHeight < 700;

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
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  SizedBox(height: isSmallScreen ? 8.h : 16.h),

                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: isSmallScreen ? 70.r : 80.r,
                                        height: isSmallScreen ? 70.r : 80.r,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.04),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: isSmallScreen ? 50.r : 60.r,
                                        height: isSmallScreen ? 50.r : 60.r,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock_reset_rounded,
                                          size: isSmallScreen ? 28.sp : 32.sp,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 8.h : 12.h),
                                  Text(
                                    "Reset Your Password",
                                    style: Theme.of(context).textTheme.titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 20.sp : 24.sp,
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
                                  SizedBox(height: isSmallScreen ? 16.h : 24.h),

                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16.w : 20.w,
                                      vertical: isSmallScreen ? 16.h : 24.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28.r),
                                      border: Border.all(
                                        color: lightBorderColor,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.05),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: PhoneInputWidget(
                                      controller: _phoneController,
                                      label: 'Mobile Number',
                                      hintText: '800 000 0000',
                                      keyboardType: TextInputType.none,
                                      backgroundColor: offWhiteBackground,
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
                                  ),
                                  SizedBox(height: isSmallScreen ? 12.h : 24.h),
                                ],
                              ),
                            ),
                          ),

                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 360.w),
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
                          ),
                          SizedBox(height: isSmallScreen ? 8.h : 16.h),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomHeader(bool isSmallScreen) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteList.loginScreen);
            }
          },
          child: Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: lightBorderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 16.sp,
              color: darkBackground,
            ),
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

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -80.h,
          right: -80.w,
          child: Container(
            width: 260.r,
            height: 260.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.35),
                  primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 4.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15)),
        ),
        Positioned(
          top: 120.h,
          left: -100.w,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  secondaryColor.withOpacity(0.2),
                  secondaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(duration: 5.seconds, begin: -15, end: 15),
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
