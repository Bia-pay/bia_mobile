import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/custom_text_field.dart';
import '../../../authcontroller/authcontroller.dart';

class ForgotPasswordScreen2 extends ConsumerStatefulWidget {
  final String phoneNumber;

  const ForgotPasswordScreen2({super.key, required this.phoneNumber});

  @override
  ConsumerState<ForgotPasswordScreen2> createState() =>
      _ForgotPasswordScreen2State();
}

class _ForgotPasswordScreen2State extends ConsumerState<ForgotPasswordScreen2> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureConfirmPassword = true;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    final otp = _otpController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Call reset password API
    final authController = ref.read(authControllerProvider.notifier);
    final response = await authController.resetPassword(
      context,
      otp,
      widget.phoneNumber,
      newPassword,
      confirmPassword,
    );

    // Navigate to login screen if successful
    if (response != null && response.responseSuccessful) {
      if (!mounted) return;
      context.go(RouteList.loginScreen);
    }
  }

  void _handleResendOTP() async {
    // Call forgot password API again to resend OTP
    final authController = ref.read(authControllerProvider.notifier);
    await authController.forgotPassword(context, widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: offWhiteBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 650;
            final isKeyboardOpen = bottomInset > 0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.07,
                    isKeyboardOpen ? 20.h : 40.h,
                    screenWidth * 0.07,
                    bottomInset + 30.h,
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    
                        /// 🔹 HEADER
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 16.sp,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 38.w),
                            Text(
                              'Change Password',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                    
                        SizedBox(height: isSmallScreen ? 30.h : 50.h),
                    
                        /// 🔹 GLASS CARD
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 28.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(22.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                    
                                  /// OTP TITLE
                                  Text(
                                    'Enter OTP',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                    
                                  SizedBox(height: 14.h),
                    
                                  /// OTP ROW
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextFormField(
                                          controller: _otpController,
                                          hintText: '123456',
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(6),
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          validator: (v) {
                                            if (v.isEmpty) return 'OTP required';
                                            if (v.length != 6) return 'OTP must be 6 digits';
                                            return null;
                                          },
                                          textInputAction: TextInputAction.done,
                                          // 🔥 ADD THIS
                                          autofillHints: const [AutofillHints.oneTimeCode],
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      SizedBox(
                                        width: 110.w,
                                        height: 52.h,
                                        child: CustomButton(
                                          buttonColor: primaryColor,
                                          buttonTextColor: Colors.white,
                                          buttonName: 'Resend',
                                          onPressed: _handleResendOTP,
                                        ),
                                      ),
                                    ],
                                  ),
                    
                                  SizedBox(height: 28.h),
                    
                                  /// NEW PASSWORD
                                  CustomTextFormField(
                                    label: 'New Password',
                                    controller: _newPasswordController,
                                    hintText: 'Enter new password',
                                    obscureText: _obscureNewPassword,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(6),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (v) {
                                      if (v.isEmpty)
                                        return 'Password required';
                                      if (v.length != 6)
                                        return 'Must be 6 digits';
                                      if (v == '123456')
                                        return 'Password too weak';
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                        _obscureNewPassword =
                                        !_obscureNewPassword);
                                      },
                                    ),
                                  ),
                    
                                  SizedBox(height: 22.h),
                    
                                  /// CONFIRM PASSWORD
                                  CustomTextFormField(
                                    label: 'Confirm Password',
                                    controller:
                                    _confirmPasswordController,
                                    hintText: 'Re-enter password',
                                    obscureText:
                                    _obscureConfirmPassword,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(6),
                                      FilteringTextInputFormatter
                                          .digitsOnly,
                                    ],
                                    validator: (v) {
                                      if (v.isEmpty)
                                        return 'Confirm password required';
                                      if (v.length != 6)
                                        return 'Must be 6 digits';
                                      if (v !=
                                          _newPasswordController.text
                                              .trim())
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                        _obscureConfirmPassword =
                                        !_obscureConfirmPassword);
                                      },
                                    ),
                                  ),
                    
                                  SizedBox(height: 32.h),
                    
                                  /// SUBMIT
                                  SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      buttonName: 'Change Password',
                                      buttonColor: primaryColor,
                                      buttonTextColor: Colors.white,
                                      onPressed: _handleChangePassword,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
