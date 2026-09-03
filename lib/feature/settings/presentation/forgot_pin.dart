import 'dart:async';
import 'package:bia/core/__core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../app/utils/widgets/pin_field.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/widgets/keypad.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  final String phone;

  const ForgotPinScreen({super.key, required this.phone});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  late TextEditingController otpController;
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;
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

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  void initState() {
    super.initState();
    otpController = TextEditingController();
    _startTimer();
    debugPrint(widget.phone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
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
    final otp = otpController.text.trim();
    final controller = ref.read(dashboardControllerProvider.notifier);

    final response = await controller.verifyForgotPin(
      context,
      otp,
    );

    if (!mounted) return;

    if (response != null && response.responseSuccessful) {
      context.pushReplacementNamed(RouteList.restoreNewPin);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;
    final isTablet = screenWidth > 600;

    // Adaptive keypad height
    final keypadHeight = isTablet
        ? 370.0
        : (isSmallScreen ? (screenHeight * 0.35) : (isLargeScreen ? 400.h : 420.h));

    final box = Hive.box('authBox');
    final phone = box.get('phone', defaultValue: 'User');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 20.0 : 20.w,
                    isTablet ? 16.0 : (isSmallScreen ? 10.h : 20.h),
                    isTablet ? 20.0 : 20.w,
                    0,
                  ),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 10.0 : (isSmallScreen ? 8.w : 10.w)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: isTablet ? 18.0 : (isSmallScreen ? 18.sp : 20.sp),
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 20.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              'Enter 6-digit code',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 24.0 : (isSmallScreen ? 20.sp : (isLargeScreen ? 28.sp : 24.sp)),
                              ),
                            ),
                            SizedBox(height: isTablet ? 4.0 : 4.h),
                            // Subtitle & Phone
                            Text(
                              "We've sent a verification code to",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: borderColor,
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 14.0 : (isSmallScreen ? 11.sp : 14.sp),
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Your phone number ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: borderColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 14.0 : (isSmallScreen ? 11.sp : 14.sp),
                                ),
                                children: [
                                  TextSpan(
                                    text: phone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 14.0 : (isSmallScreen ? 11.sp : 14.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // PIN Field
                        AppPinCodeField(
                          controller: otpController,
                          length: 6,
                          fillColor: lightBackground,
                          inactiveColor: pinBorderColor,
                          activeColor: primaryColor,
                          selectedColor: primaryColor,
                          onCompleted: (code) => _verifyOtp(),
                        ),

                        // Resend Code
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "You didn't receive any code? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: borderColor,
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 13.0 : (isSmallScreen ? 11.sp : 14.sp),
                              ),
                              children: [
                                TextSpan(
                                  text: _canResend
                                      ? 'Resend code'
                                      : 'Resend code in $_secondsRemaining s',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _canResend ? primaryColor : borderColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isTablet ? 13.0 : (isSmallScreen ? 11.sp : 14.sp),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _canResend ? _restartTimer : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Keypad
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: isTablet ? 360 : double.infinity),
                            child: SizedBox(
                              height: keypadHeight,
                              child: CustomGridKeypad(
                                onNumberPressed: addDigit,
                                leftAction: ActionKey(
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: lightBackground,
                                    size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                  ),
                                  backgroundColor: primaryColor,
                                  onTap: _verifyOtp,
                                ),
                                rightAction: ActionKey(
                                  child: Icon(
                                    Icons.backspace_rounded,
                                    color: primaryColor,
                                    size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                  ),
                                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                                  onTap: removeDigit,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 8.0 : 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}