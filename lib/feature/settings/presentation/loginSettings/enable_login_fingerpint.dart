
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../app/utils/custom_loader.dart';

class EnableTransactionPinFingerprint extends ConsumerStatefulWidget {
  const EnableTransactionPinFingerprint({super.key});

  @override
  ConsumerState<EnableTransactionPinFingerprint> createState() => _EnableTransactionPinFingerprintState();
}

class _EnableTransactionPinFingerprintState extends ConsumerState<EnableTransactionPinFingerprint> {
  bool _isLoading = false;
  String _biometricTypeName = 'Biometric';
  IconData _biometricIcon = Icons.fingerprint_rounded;

  @override
  void initState() {
    super.initState();
    _loadBiometricTypeName();
  }

  Future<void> _loadBiometricTypeName() async {
    final biometricService = BiometricService();
    final typeName = await biometricService.getBiometricTypeName();
    final icon = await biometricService.getBiometricIcon();
    setState(() {
      _biometricTypeName = typeName;
      _biometricIcon = icon;
    });
  }

  Future<void> _enableBiometricTransaction() async {
    setState(() => _isLoading = true);

    try {
      final biometricService = BiometricService();
      
      // Check biometric availability
      final canCheck = await biometricService.canCheckBiometrics();
      if (!canCheck) {
        _showSnack('Biometric not available on this device', pendingColor);
        return;
      }

      // Get current user
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      debugPrint('🔐 ENABLE PAYMENT BIOMETRIC:');
      debugPrint('   - userId from authBox: $userId');
      debugPrint('   - phone from authBox: $phone');
      debugPrint('   - effectiveUserId: $effectiveUserId');

      if (effectiveUserId.isEmpty) {
        _showSnack('User not found. Please login again.', errorColor);
        return;
      }

      // Get the saved PIN
      final settingsBox = await Hive.openBox('settingsBox');
      final savedPin = settingsBox.get('saved_pin_$effectiveUserId');
      
      if (savedPin == null) {
        _showSnack('Please set your transaction PIN first', pendingColor);
        return;
      }

      debugPrint('🔐 Attempting to enable payment biometric for user: $effectiveUserId');

      // Enable biometric with complete flow (includes authentication)
      final success = await biometricService.enablePaymentBiometric(
        userId: effectiveUserId,
        pin: savedPin,
      );

      debugPrint('🔐 Enable payment biometric result: $success');

      if (success && mounted) {
        // Verify it was actually saved
        final isEnabled = await biometricService.isPaymentEnabled(effectiveUserId);
        final savedPinCheck = await biometricService.getTransactionPin(effectiveUserId);
        
        debugPrint('🔐 Verification after enable:');
        debugPrint('   - isEnabled: $isEnabled');
        debugPrint('   - hasSavedPin: ${savedPinCheck != null}');
        
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
            SizedBox(height: 60.h),
            
            Container(
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.3),
                    primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Icon(_biometricIcon, color: Colors.white, size: 80.sp),
            ),
            
            SizedBox(height: 40.h),
            
            Text(
              'Enable $_biometricTypeName',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16.h),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Text(
                textAlign: TextAlign.center,
                'Use your $_biometricTypeName for a faster and secure way to authorize transactions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: lightSecondaryText,
                  height: 1.5,
                ),
              ),
            ),
            
            SizedBox(height: 20.h),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Tap the button below and authenticate with your $_biometricTypeName to enable this feature.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: lightText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enableBiometricTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CustomLoader(size: 20)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _biometricIcon,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Authenticate with $_biometricTypeName',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
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
