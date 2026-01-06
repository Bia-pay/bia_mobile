import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../core/utils/biometric_helper.dart';
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
  String? biometricTypeName;
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final authBox = await Hive.openBox("authBox");
    
    // Check biometric availability using helper
    final availability = await BiometricHelper.checkBiometricAvailability();
    final biometricEnabled = await BiometricHelper.isLoginBiometricEnabled();
    
    // Get saved login credentials
    final settingsBox = await Hive.openBox("settingsBox");
    final savedPwd = settingsBox.get("biometric_login_password");
    final userPhone = authBox.get("phone");
    final userName = authBox.get("fullname") ?? "User";

    setState(() {
      _hasBiometric = availability.isAvailable;
      _biometricEnabled = biometricEnabled;
      biometricTypeName = availability.biometricTypeName;
      phone = userPhone;
      fullname = userName;
      savedPassword = savedPwd;
    });

    // ✅ Logic flow
    if (!availability.isAvailable) {
      debugPrint("🚫 No biometric hardware detected. Showing password field.");
      setState(() => _showPasswordField = true);
      return;
    }

    if (availability.isAvailable && biometricEnabled && savedPwd != null) {
      debugPrint("🔐 ${availability.biometricTypeName} login enabled. Launching authentication...");
      Future.delayed(const Duration(milliseconds: 800), _authenticate);
    } else {
      if (!biometricEnabled) {
        debugPrint("🧾 Biometric available but not enabled for login. Showing password field.");
      } else if (savedPwd == null) {
        debugPrint("⚠️ No saved password found. Showing password field.");
      }
      setState(() => _showPasswordField = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);
      
      final didAuthenticate = await BiometricHelper.authenticate(
        reason: 'Authenticate to log in',
        biometricOnly: true,
      );

      if (!didAuthenticate) {
        debugPrint("❌ Biometric authentication failed or cancelled");
        setState(() => _showPasswordField = true);
        return;
      }

      final authController = ref.read(authControllerProvider.notifier);

      if (phone == null || savedPassword == null) {
        _showError("Missing saved credentials. Please log in manually.");
        setState(() => _showPasswordField = true);
        return;
      }

      await authController.logIn(context, phone!, savedPassword!.trim());

      final box = Hive.box("authBox");
      final token = box.get("token");

      if (token != null && token.isNotEmpty && mounted) {
        context.go(RouteList.bottomNavBar);
      } else {
        _showError("Login failed. Please try again.");
        setState(() => _showPasswordField = true);
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
      setState(() => _showPasswordField = true);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(appLogoFull, height: 100.h),
                Text(
                  'Welcome Back,',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 26.sp,
                    color: lightText,
                  ),
                ),
                Text(
                  fullname?.toUpperCase() ?? 'USER',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: primaryColor, // ✅ Brand primary
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 30.h),
                if (_hasBiometric && _biometricEnabled && !_showPasswordField)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _isAuthenticating ? null : _authenticate,
                        child: Column(
                          children: [
                            SvgPicture.asset(fingerPrint, height: 100.h),
                            SizedBox(height: 10.h),
                            Text(
                              _isAuthenticating 
                                ? 'Authenticating...' 
                                : 'Tap to use ${biometricTypeName ?? 'Biometric'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: lightSecondaryText,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15.h),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showPasswordField = true),
                        child: Text(
                          'Use Password Instead',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: primaryColor),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      CustomTextFormField(
                        label: 'Password',
                        controller: passwordController,
                        hintText: 'Enter your password',
                        obscureText: _obscurePassword,
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
                      SizedBox(height: 20.h),
                      CustomButton(
                        buttonName: 'Login',
                        buttonColor: primaryColor, // ✅ Brand primary
                        buttonTextColor: lightBackground,
                        onPressed: () async {
                          final authState = ref.read(
                            authControllerProvider.notifier,
                          );
                          final success = await authState.logIn(
                            context,
                            phone!,
                            passwordController.text.trim(),
                          );

                          if (success && mounted) {
                            context.go(RouteList.bottomNavBar);
                          }
                        },
                      ),
                    ],
                  ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () => context.go(RouteList.loginScreen),
                  child: Text(
                    'Use another account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: lightSecondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () => context.go(RouteList.forgotPassword),
                  child: Text(
                    'Forgot Number / Password?',
                    style: TextStyle(
                      color: lightSecondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
