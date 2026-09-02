import 'dart:async';
import 'dart:io';

import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/u_popup.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../authcontroller/authcontroller.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});
  static const String routeName = '/createAccountScreen';

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode referralCodeFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get _canSubmit {
    return nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;
  }

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    nameController.addListener(_refresh);
    emailController.addListener(_refresh);
    passwordController.addListener(_refresh);
    confirmPasswordController.addListener(_refresh);
    referralCodeController.addListener(_refresh);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    referralCodeController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    referralCodeFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_canSubmit || _isLoading) return;

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.length < 6 || password == '123456') {
      UPopup.error(context, title: 'Weak Password', message: 'Please use a stronger 6-digit password.');
      return;
    }

    if (password != confirmPassword) {
      UPopup.error(context, title: 'Password Mismatch', message: 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    final authState = ref.read(authControllerProvider.notifier);

    try {
      final response = await authState.registerStepThree(
        context,
        nameController.text.trim(),
        emailController.text.trim(),
        password,
        referralCode: referralCodeController.text.trim().isNotEmpty
            ? referralCodeController.text.trim()
            : null,
      );

      setState(() => _isLoading = false);

      if (response?.responseSuccessful == true) {
        if (mounted) {
          context.pushNamed(RouteList.bottomNavBar);
        }
      } else {
        UPopup.error(context, title: 'Failed', message: response?.responseMessage ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      UPopup.error(context, title: 'Error', message: 'An unexpected error occurred.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: primaryColor, // Modern dark top bg
      resizeToAvoidBottomInset: true,
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
                color: Colors.white.withOpacity(0.05),
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
                color: secondaryColor.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.arrow_back_ios_new, size: 18.sp, color: Colors.white),
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),

                      SizedBox(height: 30.h),
                      Text(
                        'Complete Profile',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      SizedBox(height: 10.h),
                      Text(
                        'Just a few more details to secure your account.',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
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
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.r),
                        topRight: Radius.circular(40.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          
                          _buildFormFields(context),

                          SizedBox(height: 40.h),

                          CustomButton(
                            buttonColor: _canSubmit ? primaryColor : inactiveColor,
                            buttonTextColor: Colors.white,
                            buttonName: 'Sign Up',
                            isLoading: _isLoading,
                            onPressed: _canSubmit ? _register : null,
                            elevation: _canSubmit ? 8.0 : 0.0,
                          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                          SizedBox(height: 30.h),

                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Already have an account?  ",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.go(RouteList.loginScreen),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h + bottomInset),
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

  Widget _buildFormFields(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          label: 'Full Name',
          controller: nameController,
          focusNode: nameFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(emailFocus),
          hintText: 'John Doe',
          icons: Icons.person_outline,
          validator: (v) => v.isEmpty ? 'Full name required' : null,
        ).animate().fadeIn(delay: 400.ms),
        
        SizedBox(height: 20.h),

        CustomTextFormField(
          label: 'Email Address',
          controller: emailController,
          focusNode: emailFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocus),
          hintText: 'john@example.com',
          keyboardType: TextInputType.emailAddress,
          icons: Icons.email_outlined,
          validator: (v) {
            if (v.isEmpty) return 'Email required';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
              return 'Invalid email';
            }
            return null;
          },
        ).animate().fadeIn(delay: 500.ms),

        SizedBox(height: 20.h),

        CustomTextFormField(
          label: 'Create Pin (6 digits)',
          controller: passwordController,
          focusNode: passwordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(confirmPasswordFocus),
          hintText: '******',
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          maxLength: 6,
          icons: Icons.lock_outline,
          validator: (v) {
            if (v.isEmpty) return 'Password required';
            if (v.length != 6) return 'Pin must be 6 digits';
            return null;
          },
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.digitsOnly,
          ],
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: primaryColor.withOpacity(0.4),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ).animate().fadeIn(delay: 600.ms),

        SizedBox(height: 20.h),

        CustomTextFormField(
          label: 'Confirm Pin',
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(referralCodeFocus),
          hintText: '******',
          obscureText: _obscureConfirmPassword,
          keyboardType: TextInputType.number,
          maxLength: 6,
          icons: Icons.lock_clock_outlined,
          validator: (v) {
            if (v.isEmpty) return 'Confirm pin required';
            if (v != passwordController.text.trim()) {
              return 'Pins do not match';
            }
            return null;
          },
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.digitsOnly,
          ],
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: primaryColor.withOpacity(0.4),
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ).animate().fadeIn(delay: 650.ms),

        SizedBox(height: 20.h),

        CustomTextFormField(
          label: 'Referral Code (Optional)',
          controller: referralCodeController,
          focusNode: referralCodeFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _register(),
          hintText: 'Enter referral code',
          icons: Icons.card_giftcard_rounded,
          validator: (v) => null,
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }
}