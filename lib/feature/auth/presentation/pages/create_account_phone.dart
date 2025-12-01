import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import '../../../../app/utils/image.dart';
import '../../authcontroller/authcontroller.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import 'create_account_verify_otp.dart';

class PhoneRegScreen extends ConsumerStatefulWidget {
  const PhoneRegScreen({super.key});

  @override
  ConsumerState<PhoneRegScreen> createState() => _PhoneRegScreenState();
}

class _PhoneRegScreenState extends ConsumerState<PhoneRegScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _agreed = false;
  final bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -55,
            child: SvgPicture.asset(vector, height: 220.h),
          ),
          Positioned(
            bottom: -30,
            left: -25,
            child: SvgPicture.asset(vectorOne, height: 250.h),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 240.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Create Your Account', style: context.textTheme.headlineLarge),
                  SizedBox(height: 10.h),
                  Text('Enter your phone number', style: context.textTheme.bodyLarge),
                  SizedBox(height: 20.h),
                  CustomTextFormField(
                    label: 'Mobile Number',
                    controller: phoneController,
                    hintText: 'e.g. 2348112345678',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value.isEmpty) return 'Phone number required';
                      if (!RegExp(r'^[0-9]{13}$').hasMatch(value)) {
                        return 'Enter a valid 13-digit number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15.h),

                  Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: primaryColor,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree with ',
                            style: context.textTheme.bodySmall,
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  CustomButton(
                    buttonColor:primaryColor,
                    buttonTextColor: Colors.white,
                    buttonName: _isLoading ? 'Please wait...' : 'Next',
                    buttonBorderColor: Colors.transparent,
                    onPressed: _isLoading
                        ? null
                        : () async {
                      final phone = phoneController.text.trim();
                      final authState = ref.watch(authControllerProvider.notifier);

                      final response = await authState.registerStepOne(context, phone);

                      if (response?.responseSuccessful == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateAccountVerifyOtpScreen(phone: phone),
                          ),
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
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RouteList.loginScreen),
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: context.textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 25.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}