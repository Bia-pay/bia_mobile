import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../core/services/biometric_service.dart';
import '../../../app/utils/custom_loader.dart';

class EnableLoginFingerprint extends ConsumerStatefulWidget {
  const EnableLoginFingerprint({super.key});

  @override
  ConsumerState<EnableLoginFingerprint> createState() => _EnableLoginFingerprintState();
}

class _EnableLoginFingerprintState extends ConsumerState<EnableLoginFingerprint> {
  bool _isLoading = false;
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricTypeName();
  }

  Future<void> _loadBiometricTypeName() async {
    final biometricService = BiometricService();
    final typeName = await biometricService.getBiometricTypeName();
    setState(() {
      _biometricTypeName = typeName;
    });
  }

  Future<void> _enableBiometricLogin() async {
    setState(() => _isLoading = true);

    try {
      final biometricService = BiometricService();
      
      // Check if biometric is available
      final canCheck = await biometricService.canCheckBiometrics();
      if (!canCheck) {
        _showSnack('Biometric authentication is not available on this device', pendingColor);
        return;
      }

      // Get the current user info
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;
      
      if (effectiveUserId.isEmpty) {
        _showSnack('User session not found. Please log in again.', errorColor);
        return;
      }

      // Get saved password
      final savedPassword = await biometricService.getLoginPassword(effectiveUserId);
      
      if (savedPassword == null) {
        _showSnack('Please log in again to enable biometric login', pendingColor);
        return;
      }

      // Enable biometric with complete flow (includes authentication)
      final success = await biometricService.enableLoginBiometric(
        userId: effectiveUserId,
        phone: phone,
        password: savedPassword,
      );

      if (success) {
        _showSnack("$_biometricTypeName login enabled successfully", successColor);
        if (mounted) {
          context.pop(true);
        }
      } else {
        _showSnack("Failed to enable $_biometricTypeName login", errorColor);
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 60.h),

            // Icon and description
            Container(
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.fingerprint,
                size: 80.sp,
                color: primaryColor,
              ),
            ),
            
            SizedBox(height: 40.h),
            
            Text(
              'Enable $_biometricTypeName Login',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16.h),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Use your $_biometricTypeName to quickly and securely log in to your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: lightSecondaryText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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

            // Enable button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enableBiometricLogin,
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
                            Icons.fingerprint,
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
