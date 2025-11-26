import 'dart:convert';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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


  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      debugPrint(widget.phone);
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeContext;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -55,
            child: SvgPicture.asset(
              'assets/svg/create-account-vector.svg',
              height: 220.h,
            ),
          ),
          Positioned(
            bottom: -30,
            left: -25,
            child: SvgPicture.asset(
              'assets/svg/create-account-vector-one.svg',
              height: 250.h,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 300.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Verify OTP', style: context.textTheme.headlineLarge),
                  SizedBox(height: 20.h),
                  Text(
                      'Enter your Otp',
                      style: context.textTheme.bodyMedium),
                  SizedBox(height: 20.h),
                  PinCodeTextField(
                    appContext: context,
                    controller: otpController,
                    length: 6, // ✅ now 6 digits
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    obscureText: false,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10.r),
                      fieldHeight: 45.h,
                      fieldWidth: 45.w,
                      activeColor: theme.disabledBorderColor,
                      selectedColor: theme.kPrimary,
                      inactiveColor: theme.disabledBorderColor,
                      activeFillColor: theme.tertiaryBackgroundColor,
                      selectedFillColor: theme.kPrimary.withOpacity(0.1),
                      inactiveFillColor: theme.tertiaryBackgroundColor,
                    ),
                    enableActiveFill: true,
                    onChanged: (value) {
                      otpController.text = value;
                    },
                  ),
                  SizedBox(height: 20.h),

                  CustomButton(
                    buttonColor: theme.kPrimary,
                    buttonTextColor: Colors.white,
                    buttonName: _isLoading ? 'Verifying...' : 'Verify',
                    buttonBorderColor: Colors.transparent,
                    onPressed: () async {
                      final otp = otpController.text.trim();
                      final authState = ref.watch(authControllerProvider.notifier);

                      final response = await authState.registerStepTwo(context, otp, widget.phone);

                      if (response?.responseSuccessful == true) {
                        Navigator.pushNamed(
                          context,
                          RouteList.createAccountScreen,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response?.responseMessage ?? 'Registration failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}