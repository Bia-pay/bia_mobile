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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // OTP Section
            Text(
              'Enter OPT',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13.spMin,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _otpController,
                    hintText: '123456',
                    keyboardType: TextInputType.number, // 👈 if this is a PIN
                    maxLength: 6, // 👈 hard limit
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6), // 👈 blocks typing beyond 6
                      FilteringTextInputFormatter.digitsOnly, // 👈 optional (numeric only)
                    ],
                    validator: (v) {
                      if (v.isEmpty) return 'Password required';
                      if (v.length != 6) return 'Password must be exactly 6 characters';
                      if (v == '123456') return 'Password too weak';
                      return null;
                    },
                    // suffixIcon: IconButton(
                    //   icon: Icon(
                    //     _obscureNewPassword
                    //         ? Icons.visibility_off_outlined
                    //         : Icons.visibility_outlined,
                    //   ),
                    //   onPressed: () {
                    //     setState(() => _obscureNewPassword = !_obscureNewPassword);
                    //   },
                    // ),
                  ),
                ),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 120.w,
                  child: CustomButton(
                    buttonColor: primaryColor,
                    buttonTextColor: whiteBackground,
                    buttonName: 'Resend',
                    onPressed: _handleResendOTP,

                  ),
                ),
              ],
            ),

            SizedBox(height: 40.h),

            CustomTextFormField(
              label: 'Password',
              controller: _newPasswordController,
              hintText: 'Enter your password',
              obscureText: _obscureNewPassword,
              keyboardType: TextInputType.number, // 👈 if this is a PIN
              maxLength: 6, // 👈 hard limit
              inputFormatters: [
                LengthLimitingTextInputFormatter(6), // 👈 blocks typing beyond 6
                FilteringTextInputFormatter.digitsOnly, // 👈 optional (numeric only)
              ],
              validator: (v) {
                if (v.isEmpty) return 'Password required';
                if (v.length != 6) return 'Password must be exactly 6 characters';
                if (v == '123456') return 'Password too weak';
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
              ),
            ),
            SizedBox(height: 55.h),

            CustomTextFormField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              hintText: 'Re-enter your password',
              obscureText: _obscureConfirmPassword,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (v) {
                if (v.isEmpty) return 'Confirm password required';
                if (v.length != 6) return 'Password must be exactly 6 characters';
                if (v != _newPasswordController.text.trim()) {
                  return 'Passwords do not match';
                }
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
                  _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
            ),
            SizedBox(height: 20.h),
            // New Password Section

            SizedBox(height: 50.h),

            // Change Password Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                buttonName: 'Change password',
                buttonColor: primaryColor,
                buttonTextColor: Colors.white,
                onPressed: _handleChangePassword,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
