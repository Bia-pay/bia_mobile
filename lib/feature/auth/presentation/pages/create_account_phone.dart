import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/phone_input_widget.dart';
import '../../authcontroller/authcontroller.dart';

class PhoneRegScreen extends ConsumerStatefulWidget {
  const PhoneRegScreen({super.key});

  @override
  ConsumerState<PhoneRegScreen> createState() => _PhoneRegScreenState();
}

class _PhoneRegScreenState extends ConsumerState<PhoneRegScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _agreed = false;
  bool _isLoading = false;
  String _countryDialCode = '234';
  final FocusNode phoneFocusNode = FocusNode();

  bool get _canProceed =>
      phoneController.text.trim().length >= 10 && _agreed;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    if (!_canProceed || _isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final rawPhone = phoneController.text.trim();
    final normalizedPhone = rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;
    final fullPhoneNumber = '$_countryDialCode$normalizedPhone';

    final authState = ref.read(authControllerProvider.notifier);
    final response = await authState.registerStepOne(context, fullPhoneNumber);

    setState(() => _isLoading = false);

    if (response?.responseSuccessful == true) {
      context.pushNamed(
        RouteList.createAccountVerifyOtpScreen,
        extra: fullPhoneNumber,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?.responseMessage ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: primaryColor, // Dark/primary top background
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
                        'Create Account',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      SizedBox(height: 10.h),
                      Text(
                        'Enter your phone number to get started with Bia.',
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
                          PhoneInputWidget(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleProceed(),
                            label: 'Mobile Number',
                            hintText: '801 234 5678',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (value.length < 10) {
                                return 'Phone number too short';
                              }
                              return null;
                            },
                            onCountryChanged: (country) {
                              _countryDialCode = country.dialCode.replaceAll('+', '');
                            },
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                          SizedBox(height: 24.h),

                          _buildAgreedCheckbox().animate().fadeIn(delay: 400.ms),

                          SizedBox(height: 40.h),

                          CustomButton(
                            buttonColor: _canProceed ? primaryColor : inactiveColor,
                            buttonTextColor: Colors.white,
                            buttonName: 'Continue',
                            isLoading: _isLoading,
                            onPressed: _canProceed ? _handleProceed : null,
                            elevation: _canProceed ? 8.0 : 0.0,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

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
                                      ..onTap = () => context.pushNamed(RouteList.loginScreen),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 600.ms),
                          SizedBox(height: 20.h), // padding for bottom scrolling
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

  Widget _buildAgreedCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24.w,
          width: 24.w,
          child: Checkbox(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            activeColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
            side: BorderSide(color: Colors.grey.shade400, width: 1.5),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'By continuing, I agree to the ',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}