import 'dart:convert';
import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:http/http.dart' as http;
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

  bool _agreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
              padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 160.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Complete Registration', style: context.textTheme.headlineLarge),
                  SizedBox(height: 20.h),

                  CustomTextFormField(
                    label: 'Full Name',
                    controller: nameController,
                    hintText: 'Enter your full name',
                    validator: (v) => v.isEmpty ? 'Full name required' : null,
                  ),
                  SizedBox(height: 25.h),

                  CustomTextFormField(
                    label: 'Email Address',
                    controller: emailController,
                    hintText: 'Enter your email address',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v.isEmpty) return 'Email required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 25.h),

                  CustomTextFormField(
                    label: 'Password',
                    controller: passwordController,
                    hintText: 'Enter your password',
                    obscureText: true,
                    validator: (v) => v.isEmpty ? 'Password required' : null,
                    suffixIcon: const Icon(Icons.remove_red_eye_outlined),
                  ),
                  SizedBox(height: 25.h),

                  CustomTextFormField(
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    hintText: 'Re-enter your password',
                    obscureText: true,
                    validator: (v) => v.isEmpty ? 'Confirm password' : null,
                    suffixIcon: const Icon(Icons.remove_red_eye_outlined),
                  ),
                  SizedBox(height: 20.h),

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
                    buttonColor: primaryColor,
                    buttonTextColor: Colors.white,
                    buttonName: _isLoading ? 'Creating Account...' : 'Sign Up',
                    buttonBorderColor: Colors.transparent,
                    onPressed: () async {
                      final fullname = nameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      final authState = ref.watch(authControllerProvider.notifier);

                      final response = await authState.registerStepThree(context, fullname, email, password);

                      if (response?.responseSuccessful == true) {
                        Navigator.pushNamed(
                          context,
                          RouteList.bottomNavBar,
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
                              color:primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}