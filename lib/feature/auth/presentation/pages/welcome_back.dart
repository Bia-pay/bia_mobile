import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../authcontroller/authcontroller.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  bool _showPasswordField = false;

  String? phone;
  String? fullname;
  String? savedPassword;
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final authBox = await Hive.openBox("authBox");
    final settingsBox = await Hive.openBox("settingsBox");

    bool hasFingerprint = false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final availableBiometrics = await _auth.getAvailableBiometrics();

      hasFingerprint = (canCheck && isSupported) &&
          (availableBiometrics.contains(BiometricType.fingerprint) ||
              availableBiometrics.isNotEmpty);

      debugPrint("canCheckBiometrics: $canCheck");
      debugPrint("isDeviceSupported: $isSupported");
      debugPrint("availableBiometrics: $availableBiometrics");
      debugPrint("hasFingerprint final: $hasFingerprint");
    } catch (e) {
      debugPrint("⚠Biometric detection failed: $e");
    }

    final biometricEnabled = settingsBox.get("login_biometric_enabled", defaultValue: false);
    final savedPwd = settingsBox.get("biometric_login_password");
    final userPhone = authBox.get("phone");
    final userName = authBox.get("fullname") ?? "User";

    setState(() {
      _hasBiometric = hasFingerprint;
      _biometricEnabled = biometricEnabled;
      phone = userPhone;
      fullname = userName;
      savedPassword = savedPwd;
    });

    if (!hasFingerprint) {
      setState(() => _showPasswordField = true);
      return;
    }

    if (hasFingerprint && biometricEnabled) {
      Future.delayed(const Duration(milliseconds: 800), _authenticate);
    } else {
      setState(() => _showPasswordField = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
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
        Navigator.pushReplacementNamed(context, RouteList.bottomNavBar);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontSize: 26.sp,
                    color: lightText,
                  )),
                Text(
                  fullname?.toUpperCase() ?? 'USER',
                  style: context.textTheme.headlineLarge?.copyWith(
                    color: primaryColor, // ✅ Brand primary
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,                  ),
                ),
                SizedBox(height: 30.h),
                if (_hasBiometric && _biometricEnabled && !_showPasswordField)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _isAuthenticating ? null : _authenticate,
                        child: SvgPicture.asset(
                          fingerPrint,
                          height: 100.h,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      TextButton(
                        onPressed: () => setState(() => _showPasswordField = true),
                        child: Text(
                          'Use Password Instead',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: primaryColor,
                            ),
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
                        obscureText: true,
                        validator: (value) =>
                        value.isEmpty ? 'Password is required' : null,
                        suffixIcon: const Icon(Icons.remove_red_eye_outlined),
                      ),
                      SizedBox(height: 20.h),
                      CustomButton(
                        buttonName: 'Login',
                        buttonColor: primaryColor, // ✅ Brand primary
                        buttonTextColor: lightBackground,
                        onPressed: () async {
                          final authState = ref.read(authControllerProvider.notifier);
                          final success = await authState.logIn(
                            context,
                            phone!,
                            passwordController.text.trim(),
                          );

                          if (success) {
                            Navigator.pushNamed(context, RouteList.bottomNavBar);
                          }
                        },
                      ),
                    ],
                  ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, RouteList.loginScreen),
                  child: Text(
                    'Use another account',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: lightSecondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, RouteList.loginScreen),
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