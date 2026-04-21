import 'dart:async';
import 'dart:io';

import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/u_popup.dart';
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

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

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
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  // Show error modal
  void _showErrorModal(String title, String message, {bool isNetworkError = false, VoidCallback? onRetry}) {
    if (onRetry != null) {
      UPopup.confirm(
        context,
        title: title,
        message: message,
        confirmLabel: 'Retry',
        cancelLabel: 'OK',
        onConfirm: onRetry,
      );
    } else {
      UPopup.error(
        context,
        title: title,
        message: message,
        confirmLabel: 'OK',
      );
    }
  }

  // Show success modal
  void _showSuccessModal(String title, String message) {
    UPopup.success(
      context,
      title: title,
      message: message,
      confirmLabel: 'Continue',
      onConfirm: () => context.pushNamed(RouteList.bottomNavBar),
    );
  }

  // Check if API response indicates failure
  bool _isApiFailure(dynamic response) {
    if (response == null) return true;
    return response.responseSuccessful == false;
  }

  // Check if error is a server/database error
  bool _isServerError(String errorMessage) {
    final msg = errorMessage.toLowerCase();
    return msg.contains('database') ||
        msg.contains('prisma') ||
        msg.contains('server') ||
        msg.contains('internal server error') ||
        msg.contains('500') ||
        msg.contains("can't reach") ||
        msg.contains('connection refused');
  }

  // Check if error is a network error
  bool _isNetworkError(dynamic error) {
    if (error == null) return false;
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('timeout') ||
        (msg.contains('connection') && !msg.contains('database')) ||
        msg.contains('network') ||
        msg.contains('internet') ||
        msg.contains('failed host lookup') ||
        msg.contains('no route to host');
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic response, dynamic error) {
    if (error != null) {
      if (_isNetworkError(error)) {
        return "No internet connection. Please check your network and try again.";
      }
      if (_isServerError(error.toString())) {
        return "Our servers are experiencing issues. Please try again later.";
      }
      return error.toString();
    }

    final msg = response?.responseMessage ?? "Registration failed";

    if (_isServerError(msg)) {
      return "Our servers are experiencing issues. Please try again later.";
    }

    if (msg.length > 200) {
      return "${msg.substring(0, 200)}...";
    }

    return msg;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_canSubmit || _isLoading) return;

    final fullname = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password.length < 6 || password == '123456') {
      _showErrorModal(
        'Weak Password',
        'Password is too weak. Please use a stronger 6-digit password.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showErrorModal(
        'Password Mismatch',
        'Passwords do not match. Please check and try again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final authState = ref.read(authControllerProvider.notifier);

    try {
      final response = await authState.registerStepThree(
        context,
        fullname,
        email,
        password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out.');
        },
      );

      setState(() => _isLoading = false);

      // Check if API returned failure
      if (_isApiFailure(response)) {
        final errorMessage = _getErrorMessage(response, null);

        if (_isServerError(errorMessage)) {
          _showErrorModal(
            'Server Error',
            errorMessage,
            isNetworkError: true,
            onRetry: _register,
          );
        } else {
          _showErrorModal(
            'Registration Failed',
            errorMessage,
          );
        }
        return;
      }

      // Success - show success modal
      _showSuccessModal(
        'Registration Successful',
        'Your account has been created successfully!',
      );

    } on TimeoutException catch (e) {
      setState(() => _isLoading = false);
      _showErrorModal(
        'Connection Timeout',
        'Request timed out. Network too slow or disconnected.',
        isNetworkError: true,
        onRetry: _register,
      );
    } on SocketException catch (e) {
      setState(() => _isLoading = false);
      _showErrorModal(
        'Network Error',
        'Connection lost during registration. Please check your network.',
        isNetworkError: true,
        onRetry: _register,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      final errorMsg = _getErrorMessage(null, e);

      if (_isNetworkError(e)) {
        _showErrorModal(
          'No Internet Connection',
          errorMsg,
          isNetworkError: true,
          onRetry: _register,
        );
      } else if (_isServerError(e.toString())) {
        _showErrorModal(
          'Server Error',
          errorMsg,
          isNetworkError: true,
          onRetry: _register,
        );
      } else {
        _showErrorModal(
          'Registration Failed',
          errorMsg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              login,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: blackColorOp,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.08,
                        screenHeight * 0.05,
                        screenWidth * 0.08,
                        bottomInset + 30.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            'Complete Registration',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 25.h),
                          CustomTextFormField(
                            label: 'Full Name',
                            controller: nameController,
                            focusNode: nameFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(emailFocus),
                            hintText: 'Enter your full name',
                            validator: (v) => v.isEmpty ? 'Full name required' : null,
                          ),
                          SizedBox(height: 18.h),
                          CustomTextFormField(
                            label: 'Email Address',
                            controller: emailController,
                            focusNode: emailFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocus),
                            hintText: 'Enter your email address',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v.isEmpty) return 'Email required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Invalid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 18.h),
                          CustomTextFormField(
                            label: 'Password',
                            controller: passwordController,
                            focusNode: passwordFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(confirmPasswordFocus),
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
                              if (v.length != 6) return 'Password must be 6 digits';
                              if (v == '123456') return 'Password too weak';
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          SizedBox(height: 18.h),
                          CustomTextFormField(
                            label: 'Confirm Password',
                            controller: confirmPasswordController,
                            focusNode: confirmPasswordFocus,
                            textInputAction: TextInputAction.done,
                            hintText: 'Re-enter your password',
                            obscureText: _obscureConfirmPassword,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v.isEmpty) return 'Confirm password required';
                              if (v != passwordController.text.trim()) {
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
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                          ),
                          SizedBox(height: 30.h),
                          CustomButton(
                            buttonColor: _canSubmit ? primaryColor : inactiveColor,
                            buttonTextColor: secondaryColor,
                            buttonName: _isLoading ? 'Creating Account...' : 'Sign Up',
                            buttonBorderColor: Colors.transparent,
                            onPressed: (!_canSubmit || _isLoading) ? null : _register,
                          ),
                          SizedBox(height: 25.h),
                          GestureDetector(
                            onTap: () => context.go(RouteList.loginScreen),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: "Already have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Sign In",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
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