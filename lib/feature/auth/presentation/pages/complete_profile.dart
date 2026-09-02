import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../authcontroller/authcontroller.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode pinFocus = FocusNode();
  final FocusNode confirmPinFocus = FocusNode();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;

  bool get _canSubmit {
    return nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        pinController.text.trim().length == 4 &&
        confirmPinController.text.trim().length == 4 &&
        !_isLoading;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    pinFocus.dispose();
    confirmPinFocus.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    FocusScope.of(context).unfocus();
    if (!_canSubmit || _isLoading) return;

    final fullname = nameController.text.trim();
    final email = emailController.text.trim();
    final pin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authController = ref.read(authControllerProvider.notifier);
    final response = await authController.completeRegistrationV2(
      context,
      fullname: fullname,
      email: email,
      pin: pin,
      confirmPin: confirmPin,
    );
    setState(() => _isLoading = false);

    if (response?.responseSuccessful == true) {
      if (mounted) {
        context.pop(); // Go back to dashboard/calling page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: primaryColor,
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
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      SizedBox(height: 10.h),
                      Text(
                        'Please fill in your remaining details below.',
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

                          // Full Name
                          CustomTextFormField(
                            label: 'Full Name',
                            controller: nameController,
                            focusNode: nameFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(emailFocus),
                            hintText: 'John Doe',
                            icons: Icons.person_outline,
                            validator: (v) {
                              if (v.trim().isEmpty) return 'Full name is required';
                              return null;
                            },
                          ).animate().fadeIn(delay: 300.ms),

                          SizedBox(height: 20.h),

                          // Email
                          CustomTextFormField(
                            label: 'Email Address',
                            controller: emailController,
                            focusNode: emailFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(pinFocus),
                            hintText: 'john@example.com',
                            keyboardType: TextInputType.emailAddress,
                            icons: Icons.email_outlined,
                            validator: (v) {
                              if (v.trim().isEmpty) return 'Email is required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ).animate().fadeIn(delay: 400.ms),

                          SizedBox(height: 20.h),

                          // PIN (4 digits)
                          CustomTextFormField(
                            label: 'Transaction PIN (4 digits)',
                            controller: pinController,
                            focusNode: pinFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(confirmPinFocus),
                            hintText: '****',
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            icons: Icons.lock_outline,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: primaryColor.withOpacity(0.4),
                              ),
                              onPressed: () => setState(() => _obscurePin = !_obscurePin),
                            ),
                            validator: (v) {
                              if (v.trim().isEmpty) return 'PIN is required';
                              if (v.trim().length != 4) return 'PIN must be 4 digits';
                              return null;
                            },
                          ).animate().fadeIn(delay: 500.ms),

                          SizedBox(height: 20.h),

                          // Confirm PIN (4 digits)
                          CustomTextFormField(
                            label: 'Confirm PIN',
                            controller: confirmPinController,
                            focusNode: confirmPinFocus,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _completeRegistration(),
                            hintText: '****',
                            obscureText: _obscureConfirmPin,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            icons: Icons.lock_clock_outlined,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: primaryColor.withOpacity(0.4),
                              ),
                              onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                            ),
                            validator: (v) {
                              if (v.trim().isEmpty) return 'Please confirm PIN';
                              if (v.trim() != pinController.text.trim()) {
                                return 'PINs do not match';
                              }
                              return null;
                            },
                          ).animate().fadeIn(delay: 550.ms),

                          SizedBox(height: 40.h),

                          CustomButton(
                            buttonColor: _canSubmit ? primaryColor : inactiveColor,
                            buttonTextColor: Colors.white,
                            buttonName: 'Submit Details',
                            isLoading: _isLoading,
                            onPressed: _canSubmit ? _completeRegistration : null,
                            elevation: _canSubmit ? 8.0 : 0.0,
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                          SizedBox(height: bottomInset + 30.h),
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
