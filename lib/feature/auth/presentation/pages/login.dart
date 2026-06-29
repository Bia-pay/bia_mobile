import 'dart:io';

import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/u_popup.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../app/utils/widgets/phone_input_widget.dart';
import '../../authcontroller/authcontroller.dart';

import 'dart:async';
import 'dart:io';

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
  bool _isLoginInProgress = false;

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

    final msg = response?.responseMessage ?? "Login failed";

    if (_isServerError(msg)) {
      return "Our servers are experiencing issues. Please try again later.";
    }

    if (msg.length > 200) {
      return "${msg.substring(0, 200)}...";
    }

    return msg;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_canLogin || isLoading || _isLoginInProgress) return;

    setState(() {
      isLoading = true;
      _isLoginInProgress = true;
    });

    LoadingHelper.show('Logging in...');

    final rawPhone = phoneController.text.trim();
    final normalizedPhone = rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;
    final fullPhoneNumber = '$_countryDialCode$normalizedPhone';

    final authState = ref.read(authControllerProvider.notifier);

    try {
      final success = await authState.logIn(
        context,
        fullPhoneNumber,
        passwordController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your network.');
        },
      );

      LoadingHelper.dismiss();

      // Check if API returned failure
      if (!success || _isApiFailure(authState.lastResponse)) {
        final errorMessage = _getErrorMessage(authState.lastResponse, null);

        // Check if it's a server error
        if (_isServerError(errorMessage)) {
          _showErrorModal(
            'Server Error',
            errorMessage,
            isNetworkError: true,
            onRetry: _login,
          );
        } else {
          _showErrorModal(
            'Login Failed',
            errorMessage,
          );
        }

        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
        return;
      }

      // After successful logIn, the repository has already persisted tokens to SecureStorage.
      // We can trust the 'success' boolean and the controller's state.
      if (mounted) {
        context.go(RouteList.bottomNavBar);
      }
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      } on TimeoutException catch (e) {
      LoadingHelper.dismiss();
      _showErrorModal(
        'Connection Timeout',
        'Request timed out. Network too slow or disconnected.',
        isNetworkError: true,
        onRetry: _login,
      );
      setState(() {
        isLoading = false;
        _isLoginInProgress = false;
      });
    } on SocketException catch (e) {
      LoadingHelper.dismiss();
      _showErrorModal(
        'Network Error',
        'Connection lost during login. Please check your network.',
        isNetworkError: true,
        onRetry: _login,
      );
      setState(() {
        isLoading = false;
        _isLoginInProgress = false;
      });
    } on HandshakeException catch (e) {
      LoadingHelper.dismiss();
      _showErrorModal(
        'Secure Connection Failed',
        'SSL/TLS error. Please check your network connection.',
        isNetworkError: true,
        onRetry: _login,
      );
      setState(() {
        isLoading = false;
        _isLoginInProgress = false;
      });
    } catch (e) {
      LoadingHelper.dismiss();
      debugPrint("Login error: $e");

      final errorMsg = _getErrorMessage(null, e);

      if (_isNetworkError(e)) {
        _showErrorModal(
          'No Internet Connection',
          errorMsg,
          isNetworkError: true,
          onRetry: _login,
        );
      } else if (_isServerError(e.toString())) {
        _showErrorModal(
          'Server Error',
          errorMsg,
          isNetworkError: true,
          onRetry: _login,
        );
      } else {
        _showErrorModal(
          'Login Failed',
          errorMsg,
        );
      }

      setState(() {
        isLoading = false;
        _isLoginInProgress = false;
      });
    }
  }

  void _refresh() => setState(() {});

  bool get _canLogin {
    final text = phoneController.text.trim();
    final isValidPhone = (text.length == 10 && !text.startsWith('0')) ||
                         (text.length == 11 && text.startsWith('0'));
    return isValidPhone && passwordController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: primaryColor, // Modern dark top bg
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -50.h,
            right: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 150.h,
            left: -80.w,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryColor.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.arrow_back_ios_new, size: 18.sp, color: Colors.white),
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),

                      SizedBox(height: 30.h),
                      // Text(
                      //   'Welcome Back',
                      //   style: theme.textTheme.headlineMedium?.copyWith(
                      //     fontSize: 32.sp,
                      //     fontWeight: FontWeight.w900,
                      //     color: Colors.white,
                      //     height: 1.1,
                      //   ),
                      // ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                      SizedBox(height: 10.h),
                      Text(
                        'Login to access your Bia account.',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Form Section (Bottom Sheet style)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.r),
                        topRight: Radius.circular(40.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          
                          PhoneInputWidget(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(passwordFocusNode);
                            },
                            label: 'Mobile Number',
                            hintText: '801 234 5678',
                             validator: (value) {
                              if (value.isEmpty) return 'Phone number is required';
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
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                          SizedBox(height: 24.h),

                          CustomTextFormField(
                            label: 'Password',
                            focusNode: passwordFocusNode,
                            controller: passwordController,
                            hintText: '******',
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            validator: (value) => value.isEmpty ? 'Password is required' : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: primaryColor.withOpacity(0.4),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                          SizedBox(height: 16.h),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.go(RouteList.forgotPassword),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),

                          SizedBox(height: 40.h),

                          CustomButton(
                            buttonColor: _canLogin ? primaryColor : inactiveColor,
                            buttonTextColor: Colors.white,
                            buttonName: 'Login',
                            isLoading: isLoading,
                            onPressed: _canLogin ? _login : null,
                            elevation: _canLogin ? 8.0 : 0.0,
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                          SizedBox(height: 30.h),

                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account?  ",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.go(RouteList.phoneRegScreen),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 700.ms),
                          SizedBox(height: 20.h + bottomInset),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}