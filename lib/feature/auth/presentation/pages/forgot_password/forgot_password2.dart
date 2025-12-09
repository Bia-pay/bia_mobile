import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
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

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '123456',
                        hintStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 16.sp,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: _handleResendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 16.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Resend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30.h),

            // New Password Section
            Text(
              'Enter new password',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 12.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  hintText: '••••••••••••',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16.sp,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ),

            SizedBox(height: 30.h),

            // Confirm Password Section
            Text(
              'Confirm password',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 12.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: '••••••••••••',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16.sp,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ),

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
