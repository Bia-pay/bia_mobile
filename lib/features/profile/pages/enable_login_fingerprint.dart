import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/view/widget/app_textfield.dart';
import '../../../core/utils/biometric_helper.dart';

class EnableLoginFingerprint extends ConsumerStatefulWidget {
  const EnableLoginFingerprint({super.key});

  @override
  ConsumerState<EnableLoginFingerprint> createState() => _EnableLoginFingerprintState();
}

class _EnableLoginFingerprintState extends ConsumerState<EnableLoginFingerprint> {
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricTypeName();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricTypeName() async {
    final availability = await BiometricHelper.checkBiometricAvailability();
    setState(() {
      _biometricTypeName = availability.biometricTypeName;
    });
  }

  Future<void> _enableBiometricLogin() async {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      _showSnack("Please enter your password", errorColor);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if biometric is available
      final availability = await BiometricHelper.checkBiometricAvailability();
      if (!availability.isAvailable) {
        _showSnack('Biometric authentication is not available on this device', pendingColor);
        return;
      }

      final box = await Hive.openBox('settingsBox');
      await box.put('biometric_login_password', password);
      await box.put('login_biometric_enabled', true);

      _showSnack("$_biometricTypeName login enabled successfully", successColor);

      if (mounted) {
        // Pop with result to indicate success
        context.pop(true);
      }
    } catch (e) {
      _showSnack("Failed to enable $_biometricTypeName login: $e", errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(
          'Enable $_biometricTypeName Login',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),

            // Icon and description
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 60.sp,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Enable $_biometricTypeName Login',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Enter your account password to save for $_biometricTypeName login.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: lightSecondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            // Password field
            Text(
              'Account Password',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),

            AppTextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              borderRadius: 8.r,
              decoration: InputDecoration(
                hintText: "Enter your password",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: lightSecondaryText,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: lightSecondaryText,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: lightBorderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),

            const Spacer(),

            // Enable button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enableBiometricLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Text(
                        'Enable $_biometricTypeName Login',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}