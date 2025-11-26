import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
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

      debugPrint("🧠 canCheckBiometrics: $canCheck");
      debugPrint("🧠 isDeviceSupported: $isSupported");
      debugPrint("🧠 availableBiometrics: $availableBiometrics");
      debugPrint("✅ hasFingerprint final: $hasFingerprint");
    } catch (e) {
      debugPrint("⚠️ Biometric detection failed: $e");
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

    // ✅ Logic flow
    if (!hasFingerprint) {
      debugPrint("🚫 No fingerprint hardware detected. Showing password only.");
      setState(() => _showPasswordField = true);
      return;
    }

    if (hasFingerprint && biometricEnabled) {
      debugPrint("🔐 Fingerprint login enabled. Launching biometric...");
      Future.delayed(const Duration(milliseconds: 800), _authenticate);
    } else {
      debugPrint("🧾 Fingerprint available but not enabled. Showing password field.");
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

      // ✅ After biometric success, log in using saved password
      final authController = ref.read(authControllerProvider.notifier);

      if (phone == null || savedPassword == null) {
        _showError("Missing saved credentials. Please log in manually.");
        setState(() => _showPasswordField = true);
        return;
      }

      await authController.logIn(context, phone!, savedPassword!.trim());

      final box = Hive.box("authB ox");
      final token = box.get("token");

      if (token != null && token.isNotEmpty && mounted) {
        Navigator.pushReplacementNamed(context, RouteList.bottomNavBar);
      } else {
        _showError("Login failed. Please try again.");
        setState(() => _showPasswordField = true);
      }
    } catch (e) {
      debugPrint("⚠️ Biometric error: $e");
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
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/svg/logo-one.png', height: 100.h),
                SizedBox(height: 20.h),
                Text('Welcome Back,',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 24.sp,
                      color: themeContext.primaryTextColor,
                    )),
                Text(fullname?.toUpperCase() ?? 'USER',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: themeContext.kPrimary,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 30.h),

                /// ✅ Biometric Login
                if (_hasBiometric && _biometricEnabled && !_showPasswordField)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _isAuthenticating ? null : _authenticate,
                        child: SvgPicture.asset(
                          'assets/svg/fingerprint.svg',
                          height: 100.h,
                          colorFilter: ColorFilter.mode(themeContext.kPrimary, BlendMode.srcIn),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      TextButton(
                        onPressed: () => setState(() => _showPasswordField = true),
                        child: Text(
                          'Use Password Instead',
                          style: theme.textTheme.bodyMedium?.copyWith(color: themeContext.kPrimary),
                        ),
                      ),
                    ],
                  )
                else
                /// ✅ Password Field (Fallback)
                  Column(
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      CustomButton(
                        buttonName: 'Login',
                        buttonColor: themeContext.kPrimary,
                        buttonTextColor: Colors.white,
                        onPressed: () async {
                          final authState = ref.read(authControllerProvider.notifier);

                          final success = await authState.logIn(
                            context,
                            phone!,
                            passwordController.text.trim(),
                          );
                          final box = Hive.box("authBox");
                          final token = box.get("token");

                          if (success) {
                            Navigator.pushNamed(context, RouteList.bottomNavBar);
                          }
                        },
                      ),
                    ],
                  ),

                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, RouteList.loginScreen);
                  },
                  child: Text(
                    'Use another account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: themeContext.titleTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, RouteList.loginScreen);
                  },
                  child: Text(
                    'Forgot Number / Password?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: themeContext.titleTextColor,
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