import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../authcontroller/authcontroller.dart';

class CreateAccountVerifyOtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const CreateAccountVerifyOtpScreen({super.key, required this.phone});

  @override
  ConsumerState<CreateAccountVerifyOtpScreen> createState() =>
      _CreateAccountVerifyOtpScreenState();
}

class _CreateAccountVerifyOtpScreenState
    extends ConsumerState<CreateAccountVerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode otpFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;
  bool _isLoading = false;
  bool _isOtpVerified = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _canSubmit {
    return _isOtpVerified &&
        passwordController.text.trim().length >= 6 &&
        confirmPasswordController.text.trim() == passwordController.text.trim() &&
        !_isLoading;
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    otpController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
    confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (otpController.text.trim().length < 6 || _isLoading || _isOtpVerified) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final authState = ref.read(authControllerProvider.notifier);
    final response = await authState.verifyOtpV2(
      context,
      otpController.text.trim(),
      widget.phone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response?.responseSuccessful == true) {
      setState(() {
        _isOtpVerified = true;
      });
      // Automatically shift focus to password creation field
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(passwordFocus);
        }
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isLoading) return;
    _startTimer();
    final authController = ref.read(authControllerProvider.notifier);
    await authController.resendOtpV2(context, widget.phone);
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please verify your OTP code first.'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    if (!_canSubmit || _isLoading) return;

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authState = ref.read(authControllerProvider.notifier);
    final response = await authState.createAccountV2(
      context,
      phone: widget.phone,
      otp: otpController.text.trim(),
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response?.responseSuccessful == true) {
      context.goNamed(RouteList.bottomNavBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: accentColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 🎨 1. Ambient Background Glow Orbs
          _buildBackgroundOrbs(),

          // 📱 2. Main Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Navigation Bar ───────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(14.r),
                            child: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2),

                      // Step Pill Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100.r),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'STEP 2 OF 2',
                              style: TextStyle(
                                fontSize: 11.spMin,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).scale(),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // ── Header Title & Subtitle ─────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security & Verification',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      SizedBox(height: 8.h),

                      RichText(
                        text: TextSpan(
                          text: "Verification code sent to ",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
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

                SizedBox(height: 24.h),

                // ── Bottom Sheet Form Area ───────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36.r),
                        topRight: Radius.circular(36.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36.r),
                        topRight: Radius.circular(36.r),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Drag Handle Accent
                            Center(
                              child: Container(
                                width: 40.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // 🔒 Step Notice / Verification Status Banner
                            _buildStatusBanner().animate().fadeIn(delay: 250.ms),

                            SizedBox(height: 20.h),

                            // OTP Input Field with Inline Verify Button
                            CustomTextFormField(
                              label: 'Verification Code (OTP)',
                              controller: otpController,
                              focusNode: otpFocus,
                              readOnly: _isOtpVerified,
                              textInputAction: _isOtpVerified
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isOtpVerified && otpController.text.length == 6) {
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
                                        color: successTextColor,
                                        size: 22.sp,
                                      ),
                                    )
                                  : Container(
                                      margin: EdgeInsets.all(6.r),
                                      child: TextButton(
                                        onPressed: otpController.text.trim().length == 6 && !_isLoading
                                            ? _verifyOtp
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                                          backgroundColor: otpController.text.trim().length == 6
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
                                            fontSize: 12.sp,
                                            color: otpController.text.trim().length == 6
                                                ? Colors.white
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ),
                              validator: (v) {
                                if (v.isEmpty) return 'OTP is required';
                                if (v.length != 6) return 'OTP must be 6 digits';
                                return null;
                              },
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

                            SizedBox(height: 10.h),

                            // Resend Code Row
                            if (!_isOtpVerified)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        text: "Didn't receive code?  ",
                                        style: TextStyle(
                                          color: lightSecondaryText,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13.sp,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: _canResend
                                                ? 'Resend'
                                                : 'Resend in ${_secondsRemaining}s',
                                            style: TextStyle(
                                              color: _canResend ? primaryColor : Colors.grey,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = _resendOtp,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 350.ms),

                            SizedBox(height: 24.h),

                            // ── Password Section Divider / Title ─────
                            Row(
                              children: [
                                Icon(
                                  _isOtpVerified
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 18.sp,
                                  color: _isOtpVerified ? primaryColor : Colors.grey,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'SECURITY PASSWORD',
                                  style: TextStyle(
                                    fontSize: 12.spMin,
                                    fontWeight: FontWeight.w800,
                                    color: _isOtpVerified ? primaryColor : Colors.grey,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 380.ms),

                            SizedBox(height: 12.h),

                            // Create Password Field
                            CustomTextFormField(
                              label: 'Create Password',
                              controller: passwordController,
                              focusNode: passwordFocus,
                              readOnly: !_isOtpVerified, // Locked until OTP is verified
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                if (_isOtpVerified) {
                                  FocusScope.of(context)
                                      .requestFocus(confirmPasswordFocus);
                                }
                              },
                              hintText: _isOtpVerified
                                  ? 'Min 6 characters'
                                  : 'Verify OTP above to unlock',
                              obscureText: _obscurePassword,
                              icons: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _isOtpVerified
                                      ? primaryColor.withOpacity(0.6)
                                      : Colors.grey.shade400,
                                ),
                                onPressed: _isOtpVerified
                                    ? () => setState(
                                        () => _obscurePassword = !_obscurePassword)
                                    : null,
                              ),
                              validator: (v) {
                                if (!_isOtpVerified) return null;
                                if (v.isEmpty) return 'Password required';
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08),

                            SizedBox(height: 18.h),

                            // Confirm Password Field
                            CustomTextFormField(
                              label: 'Confirm Password',
                              controller: confirmPasswordController,
                              focusNode: confirmPasswordFocus,
                              readOnly: !_isOtpVerified, // Locked until OTP is verified
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (_canSubmit) _createAccount();
                              },
                              hintText: _isOtpVerified
                                  ? 'Re-enter password'
                                  : 'Verify OTP above to unlock',
                              obscureText: _obscureConfirmPassword,
                              icons: Icons.lock_clock_outlined,
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
                                    ? () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword)
                                    : null,
                              ),
                              validator: (v) {
                                if (!_isOtpVerified) return null;
                                if (v.isEmpty) return 'Confirm password required';
                                if (v != passwordController.text.trim()) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),

                            SizedBox(height: 32.h),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: CustomButton(
                                buttonColor: _canSubmit ? primaryColor : inactiveColor,
                                buttonTextColor: Colors.white,
                                buttonName: 'Create Account',
                                isLoading: _isLoading,
                                onPressed: _canSubmit ? _createAccount : null,
                                elevation: _canSubmit ? 6.0 : 0.0,
                              ),
                            ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.96, 0.96)),

                            SizedBox(height: 24.h + bottomInset),
                          ],
                        ),
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

  Widget _buildStatusBanner() {
    if (_isOtpVerified) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: successLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: successColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: successColor,
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'OTP Verified Successfully! Now set your 6-digit password below.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: successTextColor,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: primaryColor.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.2),
              ),
              child: Icon(Icons.lock_rounded, color: primaryColor, size: 16.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Please enter and verify your OTP code to unlock password creation.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: lightText,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        // Top Right Glowing Orb
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

        // Middle Left Glowing Blob
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