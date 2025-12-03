import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/forgot_password1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../authcontroller/authcontroller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = '/loginScreen';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -90.h,
            right: -55.w,
            child: SvgPicture.asset(vector, height: 250.h),
          ),
          Positioned(
            bottom: -130.h,
            left: -25.w,
            child: SvgPicture.asset(vectorOne, height: 330.h),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 250.h, left: 35.w, right: 35.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Login to Your Account',
                      style: context.textTheme.headlineLarge,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  CustomTextFormField(
                    label: 'Mobile Number',
                    controller: phoneController,
                    hintText: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value.isEmpty) return 'Phone number required';
                      if (!RegExp(r'^[0-9]{13}$').hasMatch(value)) {
                        return 'Enter a valid 13-digit number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 25.h),
                  CustomTextFormField(
                    label: 'Password',
                    controller: passwordController,
                    hintText: 'Enter your password',
                    obscureText: _obscurePassword,
                    validator: (value) =>
                        value.isEmpty ? 'Password is required' : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 40.h),
                  CustomButton(
                    buttonColor: primaryColor,
                    buttonTextColor: Colors.white,
                    buttonName: isLoading ? 'Logging in...' : 'Login',
                    onPressed: isLoading
                        ? null
                        : () async {
                            final authState = ref.read(
                              authControllerProvider.notifier,
                            );
                            final success = await authState.logIn(
                              context,
                              phoneController.text.trim(),
                              passwordController.text.trim(),
                            );
                            if (success) {
                              Navigator.pushNamed(
                                context,
                                RouteList.bottomNavBar,
                              );
                            }
                          },
                  ),
                  if (isLoading) ...[
                    SizedBox(height: 10.h),
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen1(),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Forget Number / Password ?',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: lightText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, RouteList.phoneRegScreen);
                    },
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Don’t have an account? ',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: lightSecondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: 'Sign Up',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
