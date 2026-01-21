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
  bool _obscurepin = true;
  bool _isLoading = false;
  String _biometricTypeName = 'Biometric';
  String pin = ""; // Plain string pin

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
      pin += value;
      pinController.text = pin;
    });
  }

  // Remove last character
  void removeDigit() {
    setState(() {
      if (pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
        pinController.text = pin;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.4),
                    primaryColor,
                    primaryColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.all(Radius.circular(10.r)),
              ),
              child: Icon(Icons.lock, color: Colors.white, size: 30.sp),
            ),
            SizedBox(height: 20.h),
            Text(
              'Enter Transaction PIN',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                textAlign: TextAlign.center,'Enter your 4-digit transaction PIN to enable $_biometricTypeName for transfer.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < pin.length;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16.w,
                  height: 16.h,
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  decoration: BoxDecoration(
                    color: isFilled ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? inactiveColor : disabledTextColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            SizedBox(height: 80.h),
            SizedBox(
              height: 400.h,
              child: CustomGridKeypad(
                onNumberPressed: (value) {
                  addDigit(value);
                },

                // Bottom-left → delete
                leftAction: ActionKey(
                  child: Icon(
                    Icons.backspace,
                    color: primaryColor,
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),

                // Bottom-right → enable biometric
                rightAction: ActionKey(
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  backgroundColor: primaryColor,
                  onTap: _enableBiometricTransaction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}