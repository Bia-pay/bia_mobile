import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
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

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = context.themeContext;
    final authState = ref.watch(authControllerProvider.notifier);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          /// 🎨 Background decorations
          Positioned(
            top: -90.h,
            right: -55.w,
            child: SvgPicture.asset(
              'assets/svg/create-account-vector.svg',
              height: 250.h,
            ),
          ),
          Positioned(
            bottom: -130.h,
            left: -25.w,
            child: SvgPicture.asset(
              'assets/svg/create-account-vector-one.svg',
              height: 330.h,
            ),
          ),

          /// 🧩 Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 250.h, left: 35.w, right: 35.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🏷️ Header
                  Center(
                    child: Text(
                      'Login to Your Account',
                      style: context.textTheme.headlineLarge,
                    ),
                  ),
                  SizedBox(height: 40.h),

                  /// 📱 Mobile Number
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

                  /// 🔑 Password
                  CustomTextFormField(
                    label: 'Password',
                    controller: passwordController,
                    hintText: 'Enter your password',
                    obscureText: true,
                    validator: (value) =>
                    value.isEmpty ? 'Password is required' : null,
                    suffixIcon: const Icon(Icons.remove_red_eye_outlined),
                  ),

                  SizedBox(height: 40.h),

                  /// 🔘 Login Button
                  CustomButton(
                    buttonColor: theme.kPrimary,
                    buttonTextColor: Colors.white,
                    buttonName: isLoading ? 'Logging in...' : 'Login',
                    onPressed: isLoading ? null : () async {
                      final authState = ref.read(authControllerProvider.notifier);

                      final success = await authState.logIn(
                        context,
                        phoneController.text.trim(),
                        passwordController.text.trim(),
                      );

                      if (success) {
                        Navigator.pushNamed(context, RouteList.bottomNavBar);
                      }
                    },
                  ),

                  if (isLoading) ...[
                    SizedBox(height: 10.h),
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ],

                  SizedBox(height: 10.h),

                  /// 🔄 Forget password
                  Center(
                    child: Text(
                      'Forget Number / Password ?',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: theme.titleTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  /// 🧭 Sign Up Navigation
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
                                color: theme.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: 'Sign Up',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: theme.kPrimary,
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