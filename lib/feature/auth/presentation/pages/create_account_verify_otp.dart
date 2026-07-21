import 'dart:async';
import 'package:bia/core/__core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/widgets/pin_field.dart';
import '../../../dashboard/widgets/keypad.dart';
import '../../authcontroller/authcontroller.dart';
import '../../../../app/utils/router/route_constant.dart';

class CreateAccountVerifyOtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const CreateAccountVerifyOtpScreen({super.key, required this.phone});

  @override
  ConsumerState<CreateAccountVerifyOtpScreen> createState() => _CreateAccountVerifyOtpScreenState();
}

class _CreateAccountVerifyOtpScreenState extends ConsumerState<CreateAccountVerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;
  bool _isLoading = false;
  String pin = "";

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void addDigit(String value) {
    if (pin.length >= 6) return;
    setState(() {
      pin += value;
      otpController.text = pin;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
      otpController.text = pin;
    });
  }

  Future<void> _verifyOtp() async {
    if (otpController.text.length < 6 || _isLoading) return;

    setState(() => _isLoading = true);
    final authState = ref.read(authControllerProvider.notifier);
    final response = await authState.registerStepTwo(context, otpController.text, widget.phone);
    setState(() => _isLoading = false);

    if (response?.responseSuccessful == true) {
      context.pushNamed(RouteList.createAccountScreen);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?.responseMessage ?? 'Verification failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    final topSpacing = isSmallScreen ? 10.h : (isLargeScreen ? 40.h : 30.h);
    final keypadSpacing = isSmallScreen ? 20.h : (isLargeScreen ? 60.h : 45.h);

    return Scaffold(
      backgroundColor: primaryColor, // Modern top bg
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -50.h,
            right: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 150.h,
            left: -80.w,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryColor.withValues(alpha: 0.1),
              ),
            ),
          ),
 
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.arrow_back_ios_new, size: 18.sp, color: Colors.white),
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),
 
                      SizedBox(height: 30.h),
                      Text(
                        'Verify Account',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      SizedBox(height: 10.h),
                      RichText(
                        text: TextSpan(
                          text: "We've sent a 6-digit code to ",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Outfit',
                          ),
                          children: [
                            TextSpan(
                              text: widget.phone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
 
                SizedBox(height: 20.h),
 
                // Form Section (Bottom Sheet style)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.r),
                        topRight: Radius.circular(40.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: topSpacing),
                          Center(
                            child: AppPinCodeField(
                              controller: otpController,
                              length: 6,
                              fillColor: Colors.transparent,
                              inactiveColor: primaryColor.withValues(alpha: 0.1),
                              activeColor: primaryColor,
                              selectedColor: secondaryColor,
                              onCompleted: (code) => _verifyOtp(),
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
 
                          SizedBox(height: 15.h),
                          
                          RichText(
                            text: TextSpan(
                              text: "Didn't receive code?  ",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 14.sp,
                              ),
                              children: [
                                TextSpan(
                                  text: _canResend ? 'Resend' : 'Resend in ${_secondsRemaining}s',
                                  style: TextStyle(
                                    color: _canResend ? primaryColor : primaryColor.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w800,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _canResend ? () async {
                                      _startTimer();
                                      final authController = ref.read(authControllerProvider.notifier);
                                      await authController.resendOtp(context, widget.phone);
                                    } : null,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 400.ms),
 
                          SizedBox(height: keypadSpacing),
 
                          CustomGridKeypad(
                            onNumberPressed: addDigit,
                            leftAction: ActionKey(
                              child: _isLoading 
                                ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(Icons.check_rounded, color: Colors.white, size: isSmallScreen ? 20.sp : 24.sp),
                              backgroundColor: primaryColor,
                              onTap: _verifyOtp,
                            ),
                            rightAction: ActionKey(
                              child: Icon(Icons.backspace_rounded, color: primaryColor, size: isSmallScreen ? 20.sp : 24.sp),
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              onTap: removeDigit,
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}