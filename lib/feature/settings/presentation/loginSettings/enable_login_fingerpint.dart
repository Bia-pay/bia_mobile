import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/widgets/pin_field.dart';
import '../../../../app/view/widget/app_textfield.dart';
import '../../../../core/utils/biometric_helper.dart';
import '../../../dashboard/widgets/keypad.dart';

class EnableTransactionPinFingerprint extends ConsumerStatefulWidget {
  const EnableTransactionPinFingerprint({super.key});

  @override
  ConsumerState<EnableTransactionPinFingerprint> createState() => _EnableTransactionPinFingerprintState();
}

class _EnableTransactionPinFingerprintState extends ConsumerState<EnableTransactionPinFingerprint> {
  final TextEditingController pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _biometricTypeName = 'Biometric';
  String password = ""; // Plain string password

  @override
  void initState() {
    super.initState();
    _loadBiometricTypeName();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  // Add character from keypad
  void addDigit(String value) {
    setState(() {
      password += value;
      pinController.text = password;
    });
  }

  // Remove last character
  void removeDigit() {
    setState(() {
      if (password.isNotEmpty) {
        password = password.substring(0, password.length - 1);
        pinController.text = password;
      }
    });
  }

  Future<void> _loadBiometricTypeName() async {
    final availability = await BiometricHelper.checkBiometricAvailability();
    setState(() {
      _biometricTypeName = availability.biometricTypeName;
    });
  }

  Future<void> _enableBiometricTransaction() async {
    final inputPin = pinController.text.trim();

    if (inputPin.length != 4) {
      _showSnack("Please enter a valid 4-digit PIN", errorColor);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check biometric availability
      final availability = await BiometricHelper.checkBiometricAvailability();
      if (!availability.isAvailable) {
        _showSnack(
          'Biometric authentication is not available on this device',
          pendingColor,
        );
        return;
      }

      final box = await Hive.openBox('settingsBox');

      // ✅ TRANSACTION BIOMETRIC KEYS (CORRECT)
      await box.put('saved_pin', inputPin);
      await box.put('biometric_enabled', true);

      _showSnack(
        '$_biometricTypeName transaction enabled successfully',
        successColor,
      );

      if (mounted) {
        context.pop(true); // ✅ notify caller (switch)
      }
    } catch (e) {
      _showSnack(
        'Failed to enable $_biometricTypeName transaction',
        errorColor,
      );
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
          'Enable $_biometricTypeName Pin',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            SizedBox(height: 10.h),
            Center(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    'Enter your account pin to save for $_biometricTypeName login.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: lightSecondaryText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 80.h),
            Text(
              'Account Pin',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            AppPinCodeField(
              controller: pinController,
              length: 4,
              fillColor: keyAColor,
              inactiveColor: keyAColor,
              activeColor: primaryColor,
              selectedColor: primaryColor,
            ),
            const Spacer(),
            SizedBox(
              height: 400.h,
              child: CustomGridKeypad(
                onKeyPressed: (key) {
                  if (key == "x") {
                    removeDigit();
                  } else if (key == "ok") {
                    _enableBiometricTransaction();
                  } else {
                    addDigit(key);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}