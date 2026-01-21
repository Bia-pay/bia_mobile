import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../authcontroller/authcontroller.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});
  static const String routeName = '/createAccountScreen';

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get _canSubmit {
    return nameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;
  }

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    nameController.addListener(_refresh);
    emailController.addListener(_refresh);
    passwordController.addListener(_refresh);
    confirmPasswordController.addListener(_refresh);
  }

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
            color: blackColorOp,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Complete Registration',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 5.h),

                          CustomTextFormField(
                            label: 'Full Name',
                            controller: nameController,
                            hintText: 'Enter your full name',
                            validator: (v) =>
                            v.isEmpty ? 'Full name required' : null,
                          ),
                          SizedBox(height: 5.h),

                          CustomTextFormField(
                            label: 'Email Address',
                            controller: emailController,
                            hintText: 'Enter your email address',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v.isEmpty) return 'Email required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(v)) {
                                return 'Invalid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 5.h),

                          CustomTextFormField(
                            label: 'Password',
                            controller: passwordController,
                            hintText: 'Enter your password',
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v.isEmpty) return 'Password required';
                              if (v.length != 6) {
                                return 'Password must be 6 digits';
                              }
                              if (v == '123456') {
                                return 'Password too weak';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() =>
                                _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          SizedBox(height: 5.h),

                          CustomTextFormField(
                            label: 'Confirm Password',
                            controller: confirmPasswordController,
                            hintText: 'Re-enter your password',
                            obscureText: _obscureConfirmPassword,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v.isEmpty) {
                                return 'Confirm password required';
                              }
                              if (v !=
                                  passwordController.text.trim()) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() =>
                                _obscureConfirmPassword =
                                !_obscureConfirmPassword);
                              },
                            ),
                          ),
                          SizedBox(height: 5.h),


                          SizedBox(height: 10.h),

                          CustomButton(
                            buttonColor: _canSubmit
                                ? primaryColor
                                : inactiveColor,
                            buttonTextColor: secondaryColor,
                            buttonName: _isLoading
                                ? 'Creating Account...'
                                : 'Sign Up',
                            buttonBorderColor: Colors.transparent,
                            onPressed:
                            (!_canSubmit || _isLoading)
                                ? null
                                : () async {
                              final fullname =
                              nameController.text.trim();
                              final email =
                              emailController.text.trim();
                              final password =
                              passwordController.text.trim();
                              final confirmPassword =
                              confirmPasswordController
                                  .text
                                  .trim();

                              if (password.length < 6 ||
                                  password == '123456') {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Password is too weak'),
                                    backgroundColor:
                                    Colors.red,
                                  ),
                                );
                                return;
                              }

                              if (password !=
                                  confirmPassword) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Passwords do not match'),
                                    backgroundColor:
                                    Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() =>
                              _isLoading = true);

                              final authState = ref.read(
                                  authControllerProvider
                                      .notifier);

                              final response =
                              await authState
                                  .registerStepThree(
                                context,
                                fullname,
                                email,
                                password,
                              );

                              setState(() =>
                              _isLoading = false);

                              if (response
                                  ?.responseSuccessful ==
                                  true) {
                                context.pushNamed(
                                    RouteList
                                        .bottomNavBar);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response?.responseMessage ??
                                          'Registration failed',
                                    ),
                                    backgroundColor:
                                    Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
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