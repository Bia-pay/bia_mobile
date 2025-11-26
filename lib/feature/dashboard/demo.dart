import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../core/local/token_local_storage.dart';
import '../auth/authrepo/repo.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TokenLocalStorage tokenStorage = TokenLocalStorage();

  String? phone;
  String? userPassword;
  String? fullname;
  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;
  bool _showPasswordField = false;

  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometrics();
  }

  Future<void> _loadUserData() async {
    //userPhone = await tokenStorage.getPhone();
    userPassword = await tokenStorage.getPassword();

    final box = await Hive.openBox("authBox");
    final phone = box.get("phone");
    final fullname = box.get("fullname");
    final password = box.get("password");

    setState(() {});
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await auth.canCheckBiometrics;
    final supported = await auth.isDeviceSupported();

    setState(() => _canCheckBiometrics = canCheck && supported);

    if (_canCheckBiometrics) {
      await Future.delayed(const Duration(milliseconds: 500));
      _authenticate();
    } else {
      // fallback to password if device doesn't support biometrics
      setState(() => _showPasswordField = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);

      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Use your fingerprint to log in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate && mounted) {
        // ✅ Use saved token or credentials
        Navigator.pushReplacementNamed(context, RouteList.bottomNavBar);
      } else {
        // 👇 fallback to password field
        setState(() => _showPasswordField = true);
      }
    } catch (e) {
      debugPrint("⚠️ Biometric auth failed: $e");
      setState(() => _showPasswordField = true);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  /// 🔐 Password-based fallback login
  Future<void> _handlePasswordLogin() async {
    final enteredPassword = passwordController.text.trim();
    if (enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your password")),
      );
      return;
    }

    // Call your login API again
    final authRepo = ref.read(authRepositoryProvider);
    final body = {
      "phone": phone,
      "password": enteredPassword,
    };

    final response = await authRepo.logIn(body);

    if (response.responseSuccessful) {
      Navigator.pushReplacementNamed(context, RouteList.bottomNavBar);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.responseMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 100.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/svg/logo-one.png', height: 100.h),

            Text(
              'Welcome Back,',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 24.sp,
                color: themeContext.primaryTextColor,
              ),
            ),
            Text(
              fullname?.toUpperCase() ?? 'USER',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: themeContext.kPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30.h),

            // 🔄 Forgot Password
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, RouteList.loginScreen);
              },
              child: Text(
                'Forget Number / Password ?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: themeContext.titleTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!_showPasswordField && _canCheckBiometrics)
              GestureDetector(
                onTap: _isAuthenticating ? null : _authenticate,
                child: SvgPicture.asset(
                  'assets/svg/fingerprint.svg',
                  height: 100.h,
                ),
              )
            else
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
                    buttonColor: themeContext.kPrimary,
                    buttonTextColor: Colors.white,
                    buttonName: 'Login',
                    onPressed: _handlePasswordLogin,
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
          ],
        ),
      ),
    );
  }
}