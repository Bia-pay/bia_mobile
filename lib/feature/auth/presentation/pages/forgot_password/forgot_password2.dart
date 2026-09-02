import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  final FocusNode _otpFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _obscureConfirmPassword = true;
  bool _obscureNewPassword = true;
  bool _isOtpVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (_otpController.text.trim().length == 6) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Code verified! Enter your new password.'),
          backgroundColor: successColor,
        ),
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_newPasswordFocus);
        }
      });
    }
  }

  void _handleChangePassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your OTP first')),
      );
      return;
    }

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (newPassword.length != 6 || confirmPassword.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be 6 digits')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call reset password API
    final authController = ref.read(authControllerProvider.notifier);
    final response = await authController.resetPassword(
      context,
      otp,
      widget.phoneNumber,
      newPassword,
      confirmPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null && response.responseSuccessful) {
        context.go(RouteList.loginScreen);
      }
    }
  }

  void _handleResendOTP() async {
    final authController = ref.read(authControllerProvider.notifier);
    await authController.forgotPassword(context, widget.phoneNumber);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP code resent successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: isTablet ? accentColor : offWhiteBackground,
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
                            onTap: () => context.pop(),
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
                              'STEP 2 OF 2',
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
                        'Create New\nPassword',
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
                        "Verify your OTP code to unlock password reset, then create your new 6-digit PIN.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const Spacer(flex: 2),

                      // Security Card
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
                            const Icon(Icons.shield_outlined, color: primaryColor, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Encrypted Password Reset & Account Security',
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
                            // Title Header inside Card
                            Text(
                              'Reset Password Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkBackground,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Verification code was sent to ${widget.phoneNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                color: lightSecondaryText,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // OTP Input Field with Inline Verify Button
                            CustomTextFormField(
                              label: 'Verification Code (OTP)',
                              controller: _otpController,
                              focusNode: _otpFocus,
                              readOnly: _isOtpVerified,
                              isTablet: true,
                              textInputAction: _isOtpVerified
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isOtpVerified && _otpController.text.length == 6) {
                                  _verifyOtp();
                                }
                              },
                              hintText: 'Enter 6-digit OTP',
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              icons: Icons.pin_drop_outlined,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(6),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              suffixIcon: _isOtpVerified
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: successColor,
                                        size: 22,
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.all(4),
                                      child: TextButton(
                                        onPressed: _otpController.text.trim().length == 6 && !_isLoading
                                            ? _verifyOtp
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          backgroundColor: _otpController.text.trim().length == 6
                                              ? primaryColor
                                              : Colors.grey.shade200,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Verify',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _otpController.text.trim().length == 6
                                                ? Colors.white
                                                : Colors.grey.shade500,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ),
                              validator: (v) {
                                if (v.isEmpty) return 'OTP required';
                                if (v.length != 6) return 'OTP must be 6 digits';
                                return null;
                              },
                              autofillHints: const [
                                AutofillHints.oneTimeCode,
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Resend OTP Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: RichText(
                                text: TextSpan(
                                  text: "Didn't receive code? ",
                                  style: const TextStyle(
                                    color: lightSecondaryText,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Resend',
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _handleResendOTP,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // New Password
                            CustomTextFormField(
                              label: 'New Password',
                              controller: _newPasswordController,
                              focusNode: _newPasswordFocus,
                              readOnly: !_isOtpVerified,
                              isTablet: true,
                              hintText: _isOtpVerified
                                  ? 'Enter 6-digit new password'
                                  : 'Verify OTP above to unlock',
                              obscureText: _obscureNewPassword,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(6),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                if (!_isOtpVerified) return null;
                                if (v.isEmpty) return 'Password required';
                                if (v.length != 6) return 'Must be 6 digits';
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _isOtpVerified
                                      ? primaryColor.withOpacity(0.6)
                                      : Colors.grey.shade400,
                                ),
                                onPressed: _isOtpVerified
                                    ? () => setState(() => _obscureNewPassword = !_obscureNewPassword)
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Confirm Password
                            CustomTextFormField(
                              label: 'Confirm Password',
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              readOnly: !_isOtpVerified,
                              isTablet: true,
                              hintText: _isOtpVerified
                                  ? 'Re-enter 6-digit password'
                                  : 'Verify OTP above to unlock',
                              obscureText: _obscureConfirmPassword,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(6),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                if (!_isOtpVerified) return null;
                                if (v.isEmpty) return 'Confirm password required';
                                if (v.length != 6) return 'Must be 6 digits';
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
                                  color: _isOtpVerified
                                      ? primaryColor.withOpacity(0.6)
                                      : Colors.grey.shade400,
                                ),
                                onPressed: _isOtpVerified
                                    ? () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: CustomButton(
                                buttonName: 'Change Password',
                                buttonColor: _isOtpVerified ? primaryColor : inactiveColor,
                                buttonTextColor: Colors.white,
                                isLoading: _isLoading,
                                onPressed: _isOtpVerified ? _handleChangePassword : null,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
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
                  30.h,
                ),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.pop(),
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              color: Colors.transparent,
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 16.sp,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 16.h : 24.h),

                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_person_rounded,
                                size: 40.sp,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "Create New Password",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Enter the OTP sent to your phone and\nchoose a new secure password.",
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
                      ),

                      SizedBox(height: isSmallScreen ? 24.h : 36.h),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 28.h,
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
                              children: [
                                // OTP Input Field with Inline Verify Button
                                CustomTextFormField(
                                  label: 'Verification Code (OTP)',
                                  controller: _otpController,
                                  focusNode: _otpFocus,
                                  readOnly: _isOtpVerified,
                                  textInputAction: _isOtpVerified
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (!_isOtpVerified && _otpController.text.length == 6) {
                                      _verifyOtp();
                                    }
                                  },
                                  hintText: 'Enter 6-digit OTP',
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  icons: Icons.pin_drop_outlined,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(6),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  suffixIcon: _isOtpVerified
                                      ? Padding(
                                          padding: EdgeInsets.all(12.r),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: successColor,
                                            size: 22.sp,
                                          ),
                                        )
                                      : Container(
                                          margin: EdgeInsets.all(6.r),
                                          child: TextButton(
                                            onPressed: _otpController.text.trim().length == 6 && !_isLoading
                                                ? _verifyOtp
                                                : null,
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                                              backgroundColor: _otpController.text.trim().length == 6
                                                  ? primaryColor
                                                  : Colors.grey.shade200,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8.r),
                                              ),
                                            ),
                                            child: Text(
                                              'Verify',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _otpController.text.trim().length == 6
                                                    ? Colors.white
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                        ),
                                  validator: (v) {
                                    if (v.isEmpty) return 'OTP required';
                                    if (v.length != 6) return 'OTP must be 6 digits';
                                    return null;
                                  },
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
                                ),

                                SizedBox(height: 6.h),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Didn't receive code? ",
                                      style: TextStyle(
                                        color: lightSecondaryText,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13.sp,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Resend',
                                          style: const TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = _handleResendOTP,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 24.h),

                                CustomTextFormField(
                                  label: 'New Password',
                                  controller: _newPasswordController,
                                  focusNode: _newPasswordFocus,
                                  readOnly: !_isOtpVerified,
                                  hintText: _isOtpVerified
                                      ? 'Enter new password'
                                      : 'Verify OTP above to unlock',
                                  obscureText: _obscureNewPassword,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(6),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (v) {
                                    if (!_isOtpVerified) return null;
                                    if (v.isEmpty) return 'Password required';
                                    if (v.length != 6) return 'Must be 6 digits';
                                    return null;
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _isOtpVerified
                                          ? primaryColor.withOpacity(0.6)
                                          : Colors.grey.shade400,
                                    ),
                                    onPressed: _isOtpVerified
                                        ? () => setState(
                                            () => _obscureNewPassword = !_obscureNewPassword,
                                          )
                                        : null,
                                  ),
                                ),

                                SizedBox(height: 22.h),

                                CustomTextFormField(
                                  label: 'Confirm Password',
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocus,
                                  readOnly: !_isOtpVerified,
                                  hintText: _isOtpVerified
                                      ? 'Re-enter password'
                                      : 'Verify OTP above to unlock',
                                  obscureText: _obscureConfirmPassword,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(6),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (v) {
                                    if (!_isOtpVerified) return null;
                                    if (v.isEmpty) return 'Confirm password required';
                                    if (v.length != 6) return 'Must be 6 digits';
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
                                      color: _isOtpVerified
                                          ? primaryColor.withOpacity(0.6)
                                          : Colors.grey.shade400,
                                    ),
                                    onPressed: _isOtpVerified
                                        ? () => setState(
                                            () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                          )
                                        : null,
                                  ),
                                ),

                                SizedBox(height: 32.h),

                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    buttonName: 'Change Password',
                                    buttonColor: _isOtpVerified ? primaryColor : inactiveColor,
                                    buttonTextColor: Colors.white,
                                    isLoading: _isLoading,
                                    onPressed: _isOtpVerified ? _handleChangePassword : null,
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
}
