import 'dart:io';

import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

      // Verify token exists
      final box = await Hive.openBox("authBox");
      final token = box.get("token");
      final savedPhone = box.get("phone");

      if (token != null && token.isNotEmpty && savedPhone == fullPhoneNumber) {
        if (mounted) {
          context.go(RouteList.bottomNavBar);
        }
      } else {
        await box.delete("token");
        _showErrorModal(
          'Login Failed',
          'Unable to complete login. Please try again.',
        );
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      }
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
          Positioned.fill(
            child: Image.asset(
              login,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: darkBackground.withValues(alpha:0.05),
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
                      maxWidth: 480,
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
                          Text(
                            'Login to Your Account',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 26.spMin,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.06),
                          PhoneInputWidget(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(passwordFocusNode);
                            },
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
                            focusNode: passwordFocusNode,
                            controller: passwordController,
                            hintText: 'Enter your password',
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
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.go(RouteList.forgotPassword),
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
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              buttonColor: _canLogin ? primaryColor : inactiveColor,
                              buttonTextColor: lightBackground,
                              buttonName: isLoading ? 'Logging in...' : 'Login',
                              onPressed: (!_canLogin || isLoading) ? null : _login,
                            ),
                          ),
                          SizedBox(height: 25.h),
                          GestureDetector(
                            onTap: () => context.go(RouteList.phoneRegScreen),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Don\'t have an account? ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: lightSecondaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
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