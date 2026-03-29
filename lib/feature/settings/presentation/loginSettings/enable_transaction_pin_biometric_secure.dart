import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/widgets/pin_field.dart';
import '../../../../core/services/biometric_service.dart';
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
    _debugCheckStoredData();
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
    final biometricService = BiometricService();
    final typeName = await biometricService.getBiometricTypeName();
    setState(() {
      _biometricTypeName = typeName;
    });
  }

  /// Enable biometric for transaction PIN
  /// Uses the entered PIN to enable biometric authentication
  Future<void> _enableBiometricTransaction() async {
    if (password.length != 4) {
      _showSnack('Please enter your 4-digit PIN', pendingColor);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final biometricService = BiometricService();
      
      // Check biometric availability
      final canCheck = await biometricService.canCheckBiometrics();
      if (!canCheck) {
        _showSnack('Biometric not available', pendingColor);
        return;
      }

      // Get current user
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) {
        _showSnack('User not found. Please login again.', errorColor);
        return;
      }

      debugPrint('🔐 Attempting to enable payment biometric for user: $effectiveUserId');
      debugPrint('🔐 Entered PIN length: ${password.length}');

      // Enable biometric with complete flow (includes authentication)
      final success = await biometricService.enablePaymentBiometric(
        userId: effectiveUserId,
        pin: password,
      );

      debugPrint('🔐 Enable payment biometric result: $success');

      if (success && mounted) {
        // Verify it was actually saved
        final isEnabled = await biometricService.isPaymentEnabled(effectiveUserId);
        final savedPin = await biometricService.getTransactionPin(effectiveUserId);
        
        debugPrint('🔐 Verification after enable:');
        debugPrint('   - isEnabled: $isEnabled');
        debugPrint('   - hasSavedPin: ${savedPin != null}');
        
        _showSnack('$_biometricTypeName enabled successfully!', successColor);
        context.pop(true);
      } else {
        _showSnack('Failed to enable biometric', errorColor);
      }
    } catch (e) {
      debugPrint('❌ Error enabling biometric: $e');
      _showSnack('Error: $e', errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _debugCheckStoredData() async {
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId', defaultValue: '');

    debugPrint('🔍 DEBUG: User ID: $userId');
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
