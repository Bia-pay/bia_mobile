// import 'package:bia/core/__core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hive/hive.dart';
//
// import '../../../../app/utils/colors.dart';
// import '../../../../app/utils/custom_button.dart';
// import '../../../../app/utils/image.dart';
// import '../../../../app/utils/router/route_constant.dart';
// import '../../../../app/utils/widgets/custom_text_field.dart';
// import '../../../../core/utils/biometric_helper.dart';
// import '../../authcontroller/authcontroller.dart';
//
// class WelcomeBackScreen extends ConsumerStatefulWidget {
//   const WelcomeBackScreen({super.key});
//
//   @override
//   ConsumerState<WelcomeBackScreen> createState =>
//       _WelcomeBackScreenState();
// }
//
// class _WelcomeBackScreenState
//     extends ConsumerState<WelcomeBackScreen> {
//   bool _hasBiometric = false;
//   bool _biometricEnabled = false;
//   bool _isAuthenticating = false;
//   bool _showPasswordField = false;
//   bool _obscurePassword = true;
//
//   String? phone;
//   String? fullname;
//   String? savedPassword;
//   String? biometricTypeName;
//   String? pictureUrl;
//
//   final TextEditingController passwordController =
//   TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeSettings();
//   }
//
//   Future<void> _initializeSettings() async {
//     final authBox = await Hive.openBox("authBox");
//
//     final availability =
//     await BiometricHelper.checkBiometricAvailability();
//     final biometricEnabled =
//     await BiometricHelper.isLoginBiometricEnabled();
//
//     final settingsBox = await Hive.openBox("settingsBox");
//     final savedPwd =
//     settingsBox.get("biometric_login_password");
//
//     final userPhone = authBox.get("phone");
//     final userName = authBox.get("fullname") ?? "User";
//     final picture = authBox.get("picture");
//
//     setState(() {
//       _hasBiometric = availability.isAvailable;
//       _biometricEnabled = biometricEnabled;
//       biometricTypeName = availability.biometricTypeName;
//       phone = userPhone;
//       fullname = userName;
//       savedPassword = savedPwd;
//       pictureUrl = picture;
//     });
//
//     if (!availability.isAvailable) {
//       setState(() => _showPasswordField = true);
//       return;
//     }
//
//     if (availability.isAvailable &&
//         biometricEnabled &&
//         savedPwd != null) {
//       Future.delayed(const Duration(milliseconds: 800), _authenticate);
//     } else {
//       setState(() => _showPasswordField = true);
//     }
//   }
//
//   Future<void> _authenticate() async {
//     try {
//       setState(() => _isAuthenticating = true);
//
//       final didAuthenticate =
//       await BiometricHelper.authenticate(
//         reason: 'Authenticate to log in',
//         biometricOnly: true,
//       );
//
//       // ❗ DO NOT force password on cancel
//       if (!didAuthenticate) {
//         return;
//       }
//
//       final authController =
//       ref.read(authControllerProvider.notifier);
//
//       if (phone == null || savedPassword == null) {
//         _showError(
//             "Missing saved credentials. Please log in manually.");
//         setState(() => _showPasswordField = true);
//         return;
//       }
//
//       await authController.logIn(
//           context, phone!, savedPassword!.trim());
//
//       final box = Hive.box("authBox");
//       final token = box.get("token");
//
//       if (token != null &&
//           token.isNotEmpty &&
//           mounted) {
//         context.go(RouteList.bottomNavBar);
//       } else {
//         _showError("Login failed. Please try again.");
//       }
//     } catch (e) {
//       debugPrint("Biometric error: $e");
//     } finally {
//       if (mounted) {
//         setState(() => _isAuthenticating = false);
//       }
//     }
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: errorColor,
//       ),
//     );
//   }
//
//   Future<void> _loginWithPassword() async {
//     FocusScope.of(context).unfocus();
//
//     final authState = ref.read(
//       authControllerProvider.notifier,
//     );
//
//     final success = await authState.logIn(
//       context,
//       phone!,
//       passwordController.text.trim(),
//     );
//
//     if (success && mounted) {
//       context.go(RouteList.bottomNavBar);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightBackground,
//       resizeToAvoidBottomInset: false,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Padding(
//               padding: EdgeInsets.fromLTRB(
//                 38.w,
//                 15.h,
//                 38.w,
//                 MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: ConstrainedBox(
//                 constraints:
//                 BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment:
//                     CrossAxisAlignment.center,
//                     children: [
//                       Image.asset(appLogoFull, height: 50.h),
//
//                       Padding(
//                         padding:
//                         EdgeInsets.symmetric(vertical: 10.h),
//                         child: pictureUrl != null &&
//                             pictureUrl!.isNotEmpty
//                             ? CircleAvatar(
//                           radius: 30.r,
//                           backgroundColor:
//                           grey200,
//                           backgroundImage:
//                           NetworkImage(pictureUrl!),
//                         )
//                             : CircleAvatar(
//                           radius: 50.r,
//                           backgroundColor:
//                           Colors.grey.shade300,
//                           child: Icon(
//                             Icons.person,
//                             size: 40.sp,
//                             color: lightBackground,
//                           ),
//                         ),
//                       ),
//
//                       Text(
//                         'Welcome Back,',
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineLarge
//                             ?.copyWith(
//                           fontSize: 26.sp,
//                           color: lightText,
//                         ),
//                       ),
//                       Text(
//                         fullname?.toUpperCase() ?? 'USER',
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineLarge
//                             ?.copyWith(
//                           color: primaryColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18.sp,
//                         ),
//                       ),
//
//                       SizedBox(height: 30.h),
//
//                       if (_hasBiometric &&
//                           _biometricEnabled &&
//                           !_showPasswordField)
//                         Center(
//                           child: Column(
//                             children: [
//                               GestureDetector(
//                                 onTap: _isAuthenticating
//                                     ? null
//                                     : _authenticate,
//                                 child: Column(
//                                   children: [
//                                     SvgPicture.asset(
//                                       fingerPrint,
//                                       height: 50.h,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                   ],
//                                 ),
//                               ),
//
//                               SizedBox(height: 20.h),
//
//                               CustomButton(
//                                 buttonName: 'Try fingerprint again',
//                                 buttonColor: primaryColor,
//                                 buttonTextColor: lightBackground,
//                                 onPressed: _isAuthenticating
//                                     ? null
//                                     : _authenticate,
//                               ),
//
//                               SizedBox(height: 10.h),
//
//                               TextButton(
//                                 onPressed: () => setState(
//                                         () => _showPasswordField = true),
//                                 child: Text(
//                                   'Use Password Instead',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodyMedium
//                                       ?.copyWith(
//                                       color: primaryColor),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       else
//                         Column(
//                           children: [
//                             CustomTextFormField(
//                               label: 'Password',
//                               controller: passwordController,
//                               hintText: 'Enter your password',
//                               obscureText: _obscurePassword,
//                               keyboardType: TextInputType.number,
//                               maxLength: 6,
//                               textInputAction: TextInputAction.done,
//                               onSubmitted: (_) => _loginWithPassword(),
//                               validator: (value) =>
//                               value.isEmpty ? 'Password is required' : null,
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _obscurePassword
//                                       ? Icons.visibility_off_outlined
//                                       : Icons.visibility_outlined,
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     _obscurePassword = !_obscurePassword;
//                                   });
//                                 },
//                               ),
//                             ),
//                             SizedBox(height: 10.h),
//                             GestureDetector(
//                               onTap: () =>
//                                   context.go(RouteList.forgotPassword),
//                               child: Align(
//                                 alignment: Alignment.bottomRight,
//                                 child: Text(
//                                   'Forget Password?',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodySmall
//                                       ?.copyWith(
//                                     color: lightText,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(height: 20.h),
//                             CustomButton(
//                               buttonName: 'Login',
//                               buttonColor: primaryColor,
//                               buttonTextColor: lightBackground,
//                               onPressed: () async {
//                                 FocusScope.of(context).unfocus();
//
//                                 final authState = ref.read(
//                                   authControllerProvider.notifier,
//                                 );
//
//                                 final success =
//                                 await authState.logIn(
//                                   context,
//                                   phone!,
//                                   passwordController.text.trim(),
//                                 );
//
//                                 if (success && mounted) {
//                                   context.go(
//                                       RouteList.bottomNavBar);
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//
//                       SizedBox(height: 20.h),
//
//                       GestureDetector(
//                         onTap: () =>
//                             context.go(RouteList.loginScreen),
//                         child: Text(
//                           'Switch account',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyMedium
//                               ?.copyWith(
//                             color: lightSecondaryText,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:io';

import 'package:bia/core/__core.dart';
import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../core/services/biometric_service.dart';
import '../../authcontroller/authcontroller.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  bool _showPasswordField = false;
  bool _obscurePassword = true;

  String? phone;
  String? fullname;
  String? savedPassword;
  String? pictureUrl;
  bool _isLoading = true;
  String? _biometricTypeName = 'Biometric';

  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  // Show error modal with consistent messaging
  void _showErrorModal(
    String title,
    String message, {
    bool isNetworkError = false,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.all(24.w),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isNetworkError
                    ? pendingColor.withValues(alpha:0.1)
                    : errorColor.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                color: isNetworkError ? pendingColor : errorColor,
                size: 40.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: darkBackground,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: grey600),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                if (onRetry != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onRetry();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: lightBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Check connectivity before attempting login
  Future<bool> _checkConnectivity() async {
    try {
      final results = await Future.wait([
        InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5)),
        InternetAddress.lookup(
          'cloudflare.com',
        ).timeout(const Duration(seconds: 5)),
      ], eagerError: true).catchError((_) => <List<InternetAddress>>[]);

      return results.isNotEmpty && results.any((r) => r.isNotEmpty);
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
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

  Future<void> _initializeSettings() async {
    final authBox = await Hive.openBox("authBox");
    final biometricService = BiometricService();

    // Read exactly what was written during the last login
    final loadedUserId = authBox.get("userId")?.toString() ?? '';
    final loadedPhone  = authBox.get("phone")?.toString() ?? '';
    final loadedFullname = authBox.get("fullname")?.toString() ?? '';
    final loadedPicture  = authBox.get("picture")?.toString();

    debugPrint('📦 WelcomeBack authBox → userId: $loadedUserId  phone: $loadedPhone');

    // userId is the canonical identifier — phone is only a display fallback
    final effectiveUserId = loadedUserId.isNotEmpty ? loadedUserId : loadedPhone;

    if (effectiveUserId.isEmpty) {
      debugPrint('⚠️ No user identifier found, redirecting to login');
      if (mounted) context.go(RouteList.loginScreen);
      return;
    }

    // Resolve display name
    String effectiveFullname = loadedFullname.isNotEmpty ? loadedFullname : loadedPhone;
    if (effectiveFullname.isEmpty) effectiveFullname = 'User';

    // Check biometric for THIS specific user only
    final biometricEnabled = await biometricService.isLoginEnabled(effectiveUserId);
    final savedPwd        = await biometricService.getLoginPassword(effectiveUserId);
    final canCheck        = await biometricService.canCheckBiometrics();

    debugPrint('🔐 WelcomeBack biometric check → userId: $effectiveUserId  enabled: $biometricEnabled  hasPassword: ${savedPwd != null}  canCheck: $canCheck');

    setState(() {
      phone        = loadedPhone;
      fullname     = effectiveFullname;
      pictureUrl   = loadedPicture;
      savedPassword = savedPwd;
      _hasBiometric    = canCheck;
      // Only show biometric UI if ALL three conditions are true for THIS user
      _biometricEnabled = canCheck && biometricEnabled && savedPwd != null;
      _showPasswordField = !_biometricEnabled;
    });

    if (_biometricEnabled) {
      Future.delayed(const Duration(milliseconds: 600), _authenticate);
    }
  }

  // Main login logic with proper network error handling
  Future<void> _performLogin(
    String loginPhone,
    String loginPassword, {
    bool isBiometric = false,
  }) async {
    if (_isAuthenticating) return;

    // Check connectivity first
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _showErrorModal(
        'No Internet Connection',
        'Something went wrong. Please try again later.',
        isNetworkError: true,
        onRetry: () =>
            _performLogin(loginPhone, loginPassword, isBiometric: isBiometric),
      );
      return;
    }

    setState(() => _isAuthenticating = true);

    final authController = ref.read(authControllerProvider.notifier);

    try {
      final success = await authController
          .logIn(context, loginPhone, loginPassword.trim())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Connection timed out.');
            },
          );

      LoadingHelper.dismiss();

      if (success && mounted) {
        // Verify token exists and matches
        final box = await Hive.openBox("authBox");
        final token = box.get("token");
        final savedPhone = box.get("phone");

        if (token != null && token.isNotEmpty && savedPhone == loginPhone) {
          context.go(RouteList.bottomNavBar);
        } else {
          await box.delete("token");
          _showErrorModal(
            'Login Failed',
            'Unable to verify login. Please try again.',
          );
          _resetState(isBiometric);
        }
      } else {
        // API returned success=false (invalid credentials, user not found, etc.)
        LoadingHelper.dismiss();

        if (mounted) {
          _showErrorModal(
            'Login Failed',
            'Invalid credentials. Please check and try again.',
          );
          _resetState(isBiometric);
        }
      }
    } on TimeoutException catch (e) {
      LoadingHelper.dismiss();
      if (mounted) {
        _showErrorModal(
          'Connection Timeout',
          'Something went wrong. Please try again later.',
          isNetworkError: true,
          onRetry: () => _performLogin(
            loginPhone,
            loginPassword,
            isBiometric: isBiometric,
          ),
        );
        _resetState(isBiometric);
      }
    } on SocketException catch (e) {
      LoadingHelper.dismiss();
      if (mounted) {
        _showErrorModal(
          'Network Error',
          'Something went wrong. Please try again later.',
          isNetworkError: true,
          onRetry: () => _performLogin(
            loginPhone,
            loginPassword,
            isBiometric: isBiometric,
          ),
        );
        _resetState(isBiometric);
      }
    } on HandshakeException catch (e) {
      LoadingHelper.dismiss();
      if (mounted) {
        _showErrorModal(
          'Secure Connection Failed',
          'Something went wrong. Please try again later.',
          isNetworkError: true,
          onRetry: () => _performLogin(
            loginPhone,
            loginPassword,
            isBiometric: isBiometric,
          ),
        );
        _resetState(isBiometric);
      }
    } catch (e) {
      LoadingHelper.dismiss();
      debugPrint("Login error: $e");

      if (mounted) {
        final errorMsg = e.toString();

        // Check if it's a network-related error
        if (_isNetworkError(e) ||
            errorMsg.toLowerCase().contains('internet') ||
            errorMsg.toLowerCase().contains('connection') ||
            errorMsg.toLowerCase().contains('network') ||
            errorMsg.toLowerCase().contains('socket') ||
            errorMsg.toLowerCase().contains('timeout') ||
            errorMsg.toLowerCase().contains('failed host lookup') ||
            errorMsg.toLowerCase().contains('no route to host')) {
          _showErrorModal(
            'Connection Error',
            'Something went wrong. Please try again later.',
            isNetworkError: true,
            onRetry: () => _performLogin(
              loginPhone,
              loginPassword,
              isBiometric: isBiometric,
            ),
          );
        } else if (_isServerError(errorMsg)) {
          _showErrorModal(
            'Server Error',
            'Something went wrong. Please try again later.',
            isNetworkError: true,
            onRetry: () => _performLogin(
              loginPhone,
              loginPassword,
              isBiometric: isBiometric,
            ),
          );
        } else {
          _showErrorModal('Login Failed', errorMsg);
        }

        _resetState(isBiometric);
      }
    }
  }

  void _resetState(bool isBiometric) {
    if (isBiometric) {
      setState(() {
        _showPasswordField = true;
        _isAuthenticating = false;
      });
    } else {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    // Check if we have credentials
    if (phone == null || savedPassword == null) {
      _showErrorModal(
        'Missing Credentials',
        'Saved credentials not found. Please log in with password.',
      );
      setState(() => _showPasswordField = true);
      return;
    }

    // Perform biometric authentication
    final biometricService = BiometricService();
    final didAuthenticate = await biometricService.authenticate(
      reason: 'Authenticate to log in',
      biometricOnly: true,
    );

    if (!didAuthenticate) {
      // User cancelled biometric, stay on screen
      return;
    }

    // Use the shared login logic
    await _performLogin(phone!, savedPassword!, isBiometric: true);
  }

  Future<void> _loginWithPassword() async {
    FocusScope.of(context).unfocus();

    if (phone == null) {
      _showErrorModal('Error', 'Phone number not found. Please log in again.');
      return;
    }

    // Use the shared login logic
    await _performLogin(phone!, passwordController.text, isBiometric: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            final isTablet = maxWidth > 600;
            final isSmallPhone = maxHeight < 700;
            final isVerySmall = maxHeight < 600;

            final horizontalPadding = isTablet ? 80.w : 30.w;
            final cardMaxWidth = isTablet ? 400.w : double.infinity;
            final contentScale = isVerySmall
                ? 0.75
                : (isSmallPhone ? 0.85 : 1.0);
            final isCompact = isKeyboardOpen || isSmallPhone || isVerySmall;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500.w : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isKeyboardOpen)
                        SizedBox(
                          height:
                              (isVerySmall ? 20 : (isSmallPhone ? 30 : 60)) *
                              contentScale.h,
                        )
                      else
                        SizedBox(height: 8.h),

                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: (isTablet ? 32 : 24).w,
                            vertical: (isCompact ? 16 : 32) * contentScale.h,
                          ),
                          decoration: BoxDecoration(
                            color: lightBackground,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: darkBackground.withValues(alpha:0.02),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                appLogoFull,
                                height: (isCompact ? 35 : 50) * contentScale.h,
                              ),
                              SizedBox(
                                height: (isCompact ? 12 : 20) * contentScale.h,
                              ),
                              _buildProfileAvatar(contentScale),
                              SizedBox(
                                height: (isCompact ? 10 : 16) * contentScale.h,
                              ),
                              Text(
                                "Welcome Back",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      (isCompact ? 16 : 22) * contentScale.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                fullname?.toUpperCase() ?? "USER",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      (isCompact ? 11 : 14) * contentScale.sp,
                                ),
                              ),
                              SizedBox(
                                height: (isCompact ? 16 : 24) * contentScale.h,
                              ),
                              if (_hasBiometric &&
                                  _biometricEnabled &&
                                  !_showPasswordField)
                                _buildBiometricSection(contentScale, isCompact)
                              else
                                _buildPasswordSection(contentScale, isCompact),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: (isCompact ? 16 : 24) * contentScale.h),

                      GestureDetector(
                        onTap: () => context.go(RouteList.loginScreen),
                        child: Text(
                          "Switch Account",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: lightSecondaryText,
                            fontSize: (isCompact ? 10 : 12) * contentScale.sp,
                          ),
                        ),
                      ),

                      if (!isKeyboardOpen)
                        SizedBox(
                          height:
                              (isVerySmall ? 16 : (isSmallPhone ? 20 : 40)) *
                              contentScale.h,
                        )
                      else
                        SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double scale) {
    final avatarRadius = (45 * scale).r;

    return Container(
      padding: EdgeInsets.all((3 * scale).r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: grey200,
        backgroundImage: (pictureUrl != null && pictureUrl!.isNotEmpty)
            ? NetworkImage(pictureUrl!)
            : null,
        child: pictureUrl == null
            ? Icon(Icons.person, size: (32 * scale).sp, color: lightBackground)
            : null,
      ),
    );
  }

  Widget _buildBiometricSection(double scale, bool isCompact) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isAuthenticating ? null : _authenticate,
          child: Container(
            padding: EdgeInsets.all((isCompact ? 10 : 16) * scale.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha:0.08),
            ),
            child: SvgPicture.asset(
              fingerPrint,
              height: (isCompact ? 24 : 32) * scale.h,
            ),
          ),
        ),
        SizedBox(height: (isCompact ? 8 : 12) * scale.h),
        CustomButton(
          buttonName: "Authenticate",
          buttonColor: primaryColor,
          buttonTextColor: lightBackground,
          onPressed: _isAuthenticating ? null : _authenticate,
        ),
        SizedBox(height: (isCompact ? 4 : 8) * scale.h),
        TextButton(
          onPressed: () => setState(() => _showPasswordField = true),
          child: Text(
            "Use Password Instead",
            style: TextStyle(fontSize: (isCompact ? 10 : 12) * scale.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection(double scale, bool isCompact) {
    return Column(
      children: [
        CustomTextFormField(
          label: "Password",
          controller: passwordController,
          hintText: "Enter your password",
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loginWithPassword(),
          validator: (value) => value.isEmpty ? "Password is required" : null,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: (isCompact ? 18 : 22) * scale.sp,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        SizedBox(height: (isCompact ? 4 : 8) * scale.h),
        GestureDetector(
          onTap: () => context.go(RouteList.forgotPassword),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Forget Password?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: lightText,
                fontWeight: FontWeight.w500,
                fontSize: (isCompact ? 9 : 11) * scale.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: (isCompact ? 8 : 12) * scale.h),
        CustomButton(
          buttonName: "Login",
          buttonColor: primaryColor,
          buttonTextColor: lightBackground,
          onPressed: _isAuthenticating ? null : _loginWithPassword,
        ),
      ],
    );
  }
}
