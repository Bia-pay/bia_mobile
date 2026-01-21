import 'dart:async';
import 'package:bia/core/__core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/widgets/pin_field.dart';
import '../../../dashboard/widgets/keypad.dart';
import '../../authcontroller/authcontroller.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';

class CreateAccountVerifyOtpScreen extends ConsumerStatefulWidget {
  final String phone; // ✅ Add this

  const CreateAccountVerifyOtpScreen({super.key, required this.phone});

  @override
  ConsumerState<CreateAccountVerifyOtpScreen> createState() =>
      _CreateAccountVerifyOtpScreenState();
}

class _CreateAccountVerifyOtpScreenState
    extends ConsumerState<CreateAccountVerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;
  bool _isLoading = false;
  String pin = "";
  bool showPinWarning = false;

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
    _startTimer();
    setState(() {
      debugPrint(widget.phone);
    });
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
      otpController.text = pin; // update controller
      showPinWarning = false;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
      otpController.text = pin; // update controller
    });
  }
  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    final authState = ref.read(authControllerProvider.notifier);

    final response = await authState.registerStepOne(
      context,
      widget.phone, // SAME normalized phone
    );

    setState(() => _isLoading = false);

    if (response?.responseSuccessful == true) {
      _restartTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response?.responseMessage ?? 'Failed to resend OTP',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            15.h,
            18.w,
            MediaQuery.of(context).viewInsets.bottom + 0.h,
          ),
          child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // CENTERED
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h,),
                    Text('Enter 6-digit code', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    SizedBox(height: 8.h),
                    Text("We've sent a verification code to",   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: borderColor,
                      fontWeight: FontWeight.w600,
                    ),),
                    SizedBox(height: 2.h),
                    RichText(
                      text: TextSpan(
                        text: 'Your phone number ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: borderColor,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: widget.phone,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.spMin
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: AppPinCodeField(
                          controller: otpController,
                          length: 6,
                          fillColor: lightBackground,
                          inactiveColor: pinBorderColor,
                          activeColor: primaryColor,
                          selectedColor: primaryColor,
                          onCompleted: (code) async {
                            final otp = otpController.text.trim();
                            final authState = ref.watch(
                              authControllerProvider.notifier,
                            );

                            final response = await authState.registerStepTwo(
                              context,
                              otp,
                              widget.phone,
                            );

                            if (response?.responseSuccessful == true) {
                              context.pushNamed(
                                RouteList.createAccountScreen,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response?.responseMessage ??
                                        'Registration failed',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "You didn't received any code? ",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:  borderColor,
                            fontWeight: FontWeight.w600,
                          ),                  children: [
                          TextSpan(
                            text: _canResend
                                ? 'Resend code'
                                : 'Resend code in $_secondsRemaining s',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _canResend ? primaryColor : keyAColor,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _canResend ? _resendOtp : null,
                          ),
                        ],
                        ),
                      ),
                    ),
                    SizedBox(height: 100.h),
                  ]),
              ),

              SizedBox(
                height: 350.h,
                child: CustomGridKeypad(
                  onNumberPressed: (value) {
                    addDigit(value);
                  },

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

                  rightAction: ActionKey(
                    child:  Icon(Icons.arrow_forward, color: lightBackground),
                    backgroundColor: primaryColor,
                    onTap: () async {
                      final otp = otpController.text.trim();
                      final authState = ref.watch(authControllerProvider.notifier);

                      final response = await authState.registerStepTwo(
                        context,
                        otp,
                        widget.phone,
                      );

                      if (response?.responseSuccessful == true) {
                        context.pushNamed(RouteList.createAccountScreen);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response?.responseMessage ?? 'Registration failed',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
