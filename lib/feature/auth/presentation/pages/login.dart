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
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool _obscurePassword = true;
  String _countryDialCode = '234';

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    phoneController.addListener(_refresh);
    passwordController.addListener(_refresh);
  }
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_canLogin || isLoading) return;

    setState(() => isLoading = true);

    final rawPhone = phoneController.text.trim();

    final normalizedPhone =
    rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;

    final fullPhoneNumber = '$_countryDialCode$normalizedPhone';

    final authState = ref.read(authControllerProvider.notifier);

    final success = await authState.logIn(
      context,
      fullPhoneNumber,
      passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go(RouteList.bottomNavBar);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _refresh() => setState(() {});
  bool get _canLogin {
    return phoneController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          /// 🔥 Background Image
          Positioned.fill(
            child: Image.asset(
              login,
              fit: BoxFit.cover,
            ),
          ),

          /// 🔥 Light Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480, // Tablet support
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.08,
                        screenHeight * 0.10,
                        screenWidth * 0.08,
                        MediaQuery.of(context).viewInsets.bottom + 30.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          /// 🔹 Title
                          Text(
                            'Login to Your Account',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 26.spMin,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.06),

                          /// 🔹 Phone Input
                          PhoneInputWidget(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(passwordFocusNode);
                            },
                            label: 'Mobile Number',
                            hintText: '8012345678',
                            validator: (value) {
                              if (value.isEmpty)
                                return 'Phone number is required';
                              if (value.length < 10)
                                return 'Phone number too short';
                              return null;
                            },
                            onCountryChanged: (country) {
                              _countryDialCode =
                                  country.dialCode.replaceAll('+', '');
                            },
                          ),

                          SizedBox(height: 25.h),

                          /// 🔹 Password
                          CustomTextFormField(
                            label: 'Password',
                            controller: passwordController,
                            hintText: 'Enter your password',
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            validator: (value) =>
                            value.isEmpty
                                ? 'Password is required'
                                : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                  !_obscurePassword;
                                });
                              },
                            ),
                          ),

                          SizedBox(height: 12.h),

                          /// 🔹 Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () =>
                                  context.go(RouteList.forgotPassword),
                              child: Text(
                                'Forget Password?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: lightText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 40.h),

                          /// 🔹 Login Button
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              buttonColor: _canLogin
                                  ? primaryColor
                                  : inactiveColor,
                              buttonTextColor: Colors.white,
                              buttonName:
                              isLoading
                                  ? 'Logging in...'
                                  : 'Login',
                              onPressed:
                              (!_canLogin || isLoading)
                                  ? null
                                  : _login,
                            ),
                          ),

                          SizedBox(height: 25.h),

                          /// 🔹 Sign Up
                          GestureDetector(
                            onTap: () =>
                                context.go(RouteList.phoneRegScreen),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                    'Don’t have an account? ',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: lightSecondaryText,
                                      fontWeight:
                                      FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: primaryColor,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 40.h),
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