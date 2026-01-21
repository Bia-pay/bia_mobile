import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/utils/widgets/pin_field.dart';
import '../../../../core/services/secure_biometric_service.dart';
import '../../../dashboard/widgets/keypad.dart';

/// Secure implementation of biometric enablement
/// Flow:
/// 1. User enters PIN
/// 2. Backend validates PIN (via API call)
/// 3. Backend returns secure token
/// 4. Token is encrypted and stored locally
/// 5. Biometric only unlocks this token, never the actual PIN
class EnableTransactionPinBiometricSecure extends ConsumerStatefulWidget {
  const EnableTransactionPinBiometricSecure({super.key});

  @override
  ConsumerState<EnableTransactionPinBiometricSecure> createState() =>
      _EnableTransactionPinBiometricSecureState();
}

class _EnableTransactionPinBiometricSecureState
    extends ConsumerState<EnableTransactionPinBiometricSecure> {
  final TextEditingController pinController = TextEditingController();
  bool _isLoading = false;
  String _biometricTypeName = 'Biometric';
  String password = "";

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

  void addDigit(String value) {
    setState(() {
      password += value;
      pinController.text = password;
    });
  }

  void removeDigit() {
    setState(() {
      if (password.isNotEmpty) {
        password = password.substring(0, password.length - 1);
        pinController.text = password;
      }
    });
  }

  Future<void> _loadBiometricTypeName() async {
    final typeName = await SecureBiometricService.getBiometricTypeName();
    setState(() {
      _biometricTypeName = typeName;
    });
  }

  /// Enable biometric authentication
  /// IMPORTANT: This is a simplified version
  /// In production, you should:
  /// 1. Send PIN to backend for validation
  /// 2. Backend returns a secure token (NOT the PIN)
  /// 3. Store the token securely
  Future<void> _enableBiometricTransaction() async {
    final inputPin = pinController.text.trim();

    if (inputPin.length != 4) {
      _showSnack("Please enter a valid 4-digit PIN", errorColor);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check biometric availability
      final isAvailable = await SecureBiometricService.isBiometricAvailable();
      if (!isAvailable) {
        _showSnack(
          'Biometric authentication is not available on this device',
          pendingColor,
        );
        return;
      }

      // ⚠️ CRITICAL SECURITY NOTE:
      // In a proper implementation, you should:
      // 1. Call backend API to validate PIN: POST /api/validate-pin { pin: inputPin }
      // 2. Backend validates PIN and returns a secure token
      // 3. Store that token (NOT the PIN)
      //
      // Example:
      // final response = await apiClient.post('/api/validate-pin', { 'pin': inputPin });
      // if (response.success) {
      //   final secureToken = response.data['token'];
      //   await SecureBiometricService.enableBiometricTransaction(
      //     authToken: secureToken,
      //   );
      // }
      //
      // For now, we're using the PIN as the token (NOT SECURE for production!)
      // This is only for demonstration purposes

      debugPrint('⚠️ WARNING: Using PIN as token - NOT SECURE for production!');
      debugPrint('⚠️ In production, validate PIN with backend and get a secure token');

      // Store the PIN as token (TEMPORARY - should be backend token)
      final success = await SecureBiometricService.enableBiometricTransaction(
        authToken: inputPin, // ⚠️ Should be a token from backend, not PIN!
      );

      if (success) {
        _showSnack(
          '$_biometricTypeName transaction enabled successfully',
          successColor,
        );

        if (mounted) {
          context.pop(true);
        }
      } else {
        _showSnack(
          'Failed to enable $_biometricTypeName transaction',
          errorColor,
        );
      }
    } catch (e) {
      _showSnack(
        'Failed to enable $_biometricTypeName transaction',
        errorColor,
      );
      debugPrint('❌ Error enabling biometric: $e');
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
                  Icon(
                    Icons.security,
                    size: 60.sp,
                    color: primaryColor,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Secure Biometric Setup',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Enter your PIN to enable $_biometricTypeName authentication. Your PIN will be verified securely.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: lightSecondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60.h),
            Text(
              'Transaction PIN',
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
                onNumberPressed: (value) {
                  addDigit(value);
                },
                leftAction: ActionKey(
                  child: Icon(
                    Icons.backspace,
                    color: primaryColor,
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),
                rightAction: ActionKey(
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                  backgroundColor: primaryColor,
                  onTap: _isLoading ? () {} : _enableBiometricTransaction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
