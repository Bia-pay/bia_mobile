import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../app/utils/widgets/phone_input_widget.dart';
import '../../authcontroller/authcontroller.dart';

class CreateAccountPhoneScreen extends ConsumerStatefulWidget {
  const CreateAccountPhoneScreen({super.key});

  @override
  ConsumerState<CreateAccountPhoneScreen> createState() =>
      _CreateAccountPhoneScreenState();
}

class _CreateAccountPhoneScreenState
    extends ConsumerState<CreateAccountPhoneScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController referralController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode referralFocusNode = FocusNode();

  bool _agreed = false;
  bool _isLoading = false;
  String _countryDialCode = '234';

  bool get _canProceed {
    final text = phoneController.text.trim();
    final isValidPhone = (text.length == 10 && !text.startsWith('0')) ||
        (text.length == 11 && text.startsWith('0'));
    return isValidPhone && _agreed;
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    referralController.dispose();
    phoneFocusNode.dispose();
    referralFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    if (!_canProceed || _isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final rawPhone = phoneController.text.trim();
    final normalizedPhone =
        rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;
    final fullPhoneNumber = '$_countryDialCode$normalizedPhone';

    final authState = ref.read(authControllerProvider.notifier);
    final response = await authState.registerV2(
      context,
      fullPhoneNumber,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response?.responseSuccessful == true) {
        context.pushNamed(
          RouteList.createAccountVerifyOtpScreen,
          extra: {
            'phone': fullPhoneNumber,
            'token': response?.responseBody?.token ?? '',
            'referralCode': referralController.text.trim(),
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: accentColor,
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
                      // Step Badge
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'STEP 1 OF 2',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(),

                      const Spacer(),

                      Text(
                        'Create Account',
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
                        'Enter your phone number to get started with your secure Bia wallet and instant payments.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const Spacer(flex: 2),

                      // Feature Trust Badge
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
                                '256-Bit Bank-Grade Encryption & Instant Setup',
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
                            _buildFormFields(context, theme, isTablet: true),
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
    return Stack(
      children: [
        _buildBackgroundOrbs(),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Navigation
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
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
                          'STEP 1 OF 2',
                          style: TextStyle(
                            fontSize: 11.spMin,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(),
              ),

              SizedBox(height: 16.h),

              // Header Titles
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    SizedBox(height: 8.h),

                    Text(
                      'Enter your phone number to get started with your secure Bia wallet.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Bottom Sheet Form Container
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
                          _buildFormFields(context, theme),
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
    );
  }

  Widget _buildFormFields(BuildContext context, ThemeData theme, {bool isTablet = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Input Card
        PhoneInputWidget(
          controller: phoneController,
          focusNode: phoneFocusNode,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(referralFocusNode),
          label: 'Mobile Phone Number',
          hintText: '801 234 5678',
          isTablet: isTablet,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            final text = value.trim();
            if (text.length == 11 && !text.startsWith('0')) {
              return '11-digit number must start with 0';
            }
            if (text.length != 10 && text.length != 11) {
              return 'Phone number must be 10 or 11 digits';
            }
            return null;
          },
          onCountryChanged: (country) {
            _countryDialCode = country.dialCode.replaceAll('+', '');
          },
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),

        SizedBox(height: isTablet ? 18 : 18.h),

        // Referral Code Input
        CustomTextFormField(
          label: 'Referral Code (Optional)',
          controller: referralController,
          focusNode: referralFocusNode,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleProceed(),
          hintText: 'Enter referral code if available',
          icons: Icons.card_giftcard_rounded,
          isTablet: isTablet,
          validator: (value) => null,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

        SizedBox(height: isTablet ? 22 : 22.h),

        // Terms & Conditions Checkbox Box
        Container(
          padding: EdgeInsets.all(isTablet ? 14 : 14.r),
          decoration: BoxDecoration(
            color: lightSurface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: _agreed ? primaryColor.withOpacity(0.4) : lightBorderColor,
              width: 1,
            ),
          ),
          child: _buildAgreedCheckbox(isTablet: isTablet),
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),

        SizedBox(height: isTablet ? 32 : 32.h),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: isTablet ? 54 : 56.h,
          child: CustomButton(
            buttonColor: _canProceed ? primaryColor : inactiveColor,
            buttonTextColor: Colors.white,
            buttonName: 'Continue',
            isLoading: _isLoading,
            onPressed: _canProceed ? _handleProceed : null,
            elevation: _canProceed ? 6.0 : 0.0,
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.96, 0.96)),

        SizedBox(height: isTablet ? 24 : 28.h),

        // Sign In Link
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                color: lightSecondaryText,
                fontWeight: FontWeight.w500,
                fontSize: isTablet ? 14 : 14.sp,
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
        ).animate().fadeIn(delay: 450.ms),

        SizedBox(height: isTablet ? 20 : 24.h),
      ],
    );
  }

  Widget _buildAgreedCheckbox({bool isTablet = false}) {
    return InkWell(
      onTap: () => setState(() => _agreed = !_agreed),
      borderRadius: BorderRadius.circular(8.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isTablet ? 22 : 22.r,
            height: isTablet ? 22 : 22.r,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: _agreed ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(7.r),
              border: Border.all(
                color: _agreed ? primaryColor : Colors.grey.shade400,
                width: 1.5,
              ),
              boxShadow: _agreed
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: _agreed
                ? Icon(
                    Icons.check_rounded,
                    size: isTablet ? 16 : 16.sp,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: isTablet ? 12 : 12.w),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'By continuing, I agree to the ',
                style: TextStyle(
                  color: lightText,
                  fontSize: isTablet ? 13.5 : 13.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
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
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
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