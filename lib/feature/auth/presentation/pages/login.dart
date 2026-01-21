import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:bia/feature/auth/presentation/pages/forgot_password/forgot_password1.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../app/utils/widgets/phone_input_widget.dart';
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
  String _countryDialCode = '234';
  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    phoneController.addListener(_refresh);
    passwordController.addListener(_refresh);
  }

  void _refresh() => setState(() {});
  bool get _canLogin {
    return phoneController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(login),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.05),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    18.w,
                    15.h,
                    18.w,
                    MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,                        children: [
                          Center(
                            child: Text(
                              'Login to Your Account',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ),
                          SizedBox(height: 40.h),

                          PhoneInputWidget(
                            controller: phoneController,
                            label: 'Mobile Number',
                            hintText: '8012345678',
                            validator: (value) {
                              if (value.isEmpty) return 'Phone number is required';
                              if (value.length < 10) return 'Phone number too short';
                              return null;
                            },
                            onCountryChanged: (country) {
                              _countryDialCode = country.dialCode.replaceAll('+', '');
                            },
                          ),
                          SizedBox(height: 25.h),
                          CustomTextFormField(
                            label: 'Password',
                            controller: passwordController,
                            hintText: 'Enter your password',
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
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
                        SizedBox(height: 10.h),
                        GestureDetector(
                          onTap: () => context.go(RouteList.forgotPassword),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'Forget Password?',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: lightText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                          SizedBox(height: 40.h),
                          CustomButton(
                          buttonColor: _canLogin ? primaryColor : inactiveColor,
                          buttonTextColor: Colors.white,
                          buttonName: isLoading ? 'Logging in...' : 'Login',
                          onPressed: (!_canLogin || isLoading)
                              ? null
                              : () async {
                            final rawPhone = phoneController.text.trim();

                            final normalizedPhone = rawPhone.startsWith('0')
                                ? rawPhone.substring(1)
                                : rawPhone;

                            final fullPhoneNumber =
                                '$_countryDialCode$normalizedPhone';

                            final authState = ref.read(
                              authControllerProvider.notifier,
                            );

                            final success = await authState.logIn(
                              context,
                              fullPhoneNumber,
                              passwordController.text.trim(),
                            );

                            if (success && mounted) {
                              context.go(RouteList.bottomNavBar);
                            }
                          },
                        ),
                          if (isLoading) ...[
                            SizedBox(height: 10.h),
                            const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                          SizedBox(height: 20.h),
                          GestureDetector(
                            onTap: () => context.go(RouteList.phoneRegScreen),
                            child: Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Don’t have an account? ',
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(
                                        color: lightSecondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
