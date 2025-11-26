import 'dart:convert';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  Future<void> _completeRegistration() async {
    final fullname = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullname.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/complete/registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
        }),
      );

      debugPrint('📩 Complete Registration Response: ${res.body}');
      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (res.statusCode == 200 || data['responseSuccessful'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['responseMessage'] ?? 'Registration successful')),
        );
        if (context.mounted) {
          Navigator.pushNamed(context, RouteList.loginScreen);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['responseMessage'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error completing registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeContext;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -55,
            child: SvgPicture.asset('assets/svg/create-account-vector.svg', height: 220.h),
          ),
          Positioned(
            bottom: -30,
            left: -25,
            child: SvgPicture.asset('assets/svg/create-account-vector-one.svg', height: 250.h),
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
                        activeColor: theme.kPrimary,
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
                                  color: theme.kPrimary,
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
                    buttonColor: theme.kPrimary,
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
                              color: theme.kPrimary,
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