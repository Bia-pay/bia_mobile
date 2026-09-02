import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/u_popup.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../app/utils/widgets/phone_input_widget.dart';
import '../../../../core/easy_loading_config.dart';
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
  bool _isLoginInProgress = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_refresh);
    passwordController.addListener(_refresh);
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
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

        if (mounted) {
          setState(() {
            isLoading = false;
            _isLoginInProgress = false;
          });
        }
        return;
      }

      if (mounted) {
        context.go(RouteList.bottomNavBar);
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      }
    } on TimeoutException catch (_) {
      LoadingHelper.dismiss();
      _showErrorModal(
        'Connection Timeout',
        'Request timed out. Network too slow or disconnected.',
        isNetworkError: true,
        onRetry: _login,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      }
    } on SocketException catch (_) {
      LoadingHelper.dismiss();
      _showErrorModal(
        'Network Error',
        'Connection lost during login. Please check your network.',
        isNetworkError: true,
        onRetry: _login,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      }
    } on HandshakeException catch (_) {
      LoadingHelper.dismiss();
      _showErrorModal(
        'Secure Connection Failed',
        'SSL/TLS error. Please check your network connection.',
        isNetworkError: true,
        onRetry: _login,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      }
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

      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoginInProgress = false;
        });
      }
    }
  }

  bool get _canLogin {
    final text = phoneController.text.trim();
    final isValidPhone = (text.length == 10 && !text.startsWith('0')) ||
        (text.length == 11 && text.startsWith('0'));
    return isValidPhone && passwordController.text.trim().length == 6;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: accentColor,
      resizeToAvoidBottomInset: true,
      body: isTablet
          ? _buildTabletLayout(context, theme, bottomInset)
          : _buildPhoneLayout(context, theme, bottomInset),
    );
  }

  Widget _buildTabletLayout(BuildContext context, ThemeData theme, double bottomInset) {
    return Stack(
      children: [
        _buildBackgroundOrbs(),
        SafeArea(
          child: Row(
            children: [
              // Left Side: Brand Panel (Flex 4)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'WELCOME BACK',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(),

                      const Spacer(),

                      Text(
                        'Login to Bia',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const SizedBox(height: 12),

                      Text(
                        'Login to access your secure Bia wallet, instant rides, and cashless payments.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const Spacer(flex: 2),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_person_outlined, color: primaryColor, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Biometric Lock & Instant Wallet Access',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),

              // Right Side: Form Card (Flex 6)
              Expanded(
                flex: 6,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      bottomLeft: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(-10, 0),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFormFields(context, theme, bottomInset, isTablet: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context, ThemeData theme, double bottomInset) {
    return Stack(
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
              SizedBox(height: 26.h),

              // Header Title & Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    SizedBox(height: 8.h),

                    Text(
                      'Login to access your secure Bia wallet and instant payments.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Form Sheet Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36.r),
                      topRight: Radius.circular(36.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36.r),
                      topRight: Radius.circular(36.r),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildFormFields(context, theme, bottomInset),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context, ThemeData theme, double bottomInset, {bool isTablet = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Input Field
        PhoneInputWidget(
          controller: phoneController,
          focusNode: phoneFocusNode,
          textInputAction: TextInputAction.next,
          isTablet: isTablet,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
          label: 'Mobile Phone Number',
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
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),

        SizedBox(height: isTablet ? 18 : 18.h),

        // Password Field
        CustomTextFormField(
          label: 'Password',
          focusNode: passwordFocusNode,
          controller: passwordController,
          hintText: 'Enter 6-digit password',
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          isTablet: isTablet,
          onSubmitted: (_) => _login(),
          icons: Icons.lock_outline_rounded,
          validator: (value) => value.isEmpty ? 'Password is required' : null,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: primaryColor.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),

        SizedBox(height: isTablet ? 14 : 14.h),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => context.go(RouteList.forgotPassword),
            borderRadius: BorderRadius.circular(6.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 13.5 : 13.5.sp,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),

        SizedBox(height: isTablet ? 24 : 32.h),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: isTablet ? 54 : 56.h,
          child: CustomButton(
            buttonColor: _canLogin ? primaryColor : inactiveColor,
            buttonTextColor: Colors.white,
            buttonName: 'Login',
            isLoading: isLoading,
            onPressed: _canLogin ? _login : null,
            elevation: _canLogin ? 6.0 : 0.0,
          ),
        ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.96, 0.96)),

        SizedBox(height: isTablet ? 20 : 28.h),

        // Sign Up Footer Link
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(
                color: lightSecondaryText,
                fontWeight: FontWeight.w500,
                fontSize: isTablet ? 14 : 14.sp,
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
        ).animate().fadeIn(delay: 500.ms),

        SizedBox(height: 24.h + bottomInset),
      ],
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        // Top Right Glowing Orb
        Positioned(
          top: -80.h,
          right: -80.w,
          child: Container(
            width: 260.r,
            height: 260.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.35),
                  primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 4.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15)),
        ),

        // Middle Left Glowing Blob
        Positioned(
          top: 120.h,
          left: -100.w,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  secondaryColor.withOpacity(0.2),
                  secondaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(duration: 5.seconds, begin: -15, end: 15),
        ),
      ],
    );
  }
}