import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device has biometric hardware and it's available
  static Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      // Check if device can check biometrics
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        debugPrint('🚫 Device does not support biometrics');
        return BiometricAvailability(
          isAvailable: false,
          hasFingerprint: false,
          hasFaceId: false,
          availableTypes: [],
          message: 'Device does not support biometric authentication',
        );
      }

      // Get available biometric types
      final availableBiometrics = await _auth.getAvailableBiometrics();

      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
      final hasFaceId = availableBiometrics.contains(BiometricType.face);

      debugPrint('✅ Biometric availability:');
      debugPrint('   - Can check: $canCheck');
      debugPrint('   - Device supported: $isSupported');
      debugPrint('   - Available types: $availableBiometrics');
      debugPrint('   - Has fingerprint: $hasFingerprint');
      debugPrint('   - Has Face ID: $hasFaceId');

      return BiometricAvailability(
        isAvailable: availableBiometrics.isNotEmpty,
        hasFingerprint: hasFingerprint,
        hasFaceId: hasFaceId,
        availableTypes: availableBiometrics,
        message: availableBiometrics.isEmpty
            ? 'No biometric authentication enrolled'
            : 'Biometric authentication available',
      );
    } catch (e) {
      debugPrint('❌ Error checking biometric availability: $e');
      return BiometricAvailability(
        isAvailable: false,
        hasFingerprint: false,
        hasFaceId: false,
        availableTypes: [],
        message: 'Error checking biometric availability: $e',
      );
    }
  }

  /// Check if biometric is enabled for transactions
  static Future<bool> isTransactionBiometricEnabled() async {
    try {
      final box = await Hive.openBox('settingsBox');
      return box.get('biometric_enabled', defaultValue: false);
    } catch (e) {
      debugPrint('❌ Error checking biometric setting: $e');
      return false;
    }
  }

  /// Check if biometric is enabled for login
  static Future<bool> isLoginBiometricEnabled() async {
    try {
      final box = await Hive.openBox('settingsBox');
      return box.get('login_biometric_enabled', defaultValue: false);
    } catch (e) {
      debugPrint('❌ Error checking login biometric setting: $e');
      return false;
    }
  }

  /// Get saved PIN for biometric authentication
  static Future<String?> getSavedPin() async {
    try {
      final box = await Hive.openBox('settingsBox');
      return box.get('saved_pin');
    } catch (e) {
      debugPrint('❌ Error getting saved PIN: $e');
      return null;
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final availability = await checkBiometricAvailability();
      
      if (!availability.isAvailable) {
        debugPrint('🚫 Biometric not available');
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      debugPrint(didAuthenticate
          ? '✅ Biometric authentication successful'
          : '❌ Biometric authentication failed');

      return didAuthenticate;
    } catch (e) {
      debugPrint('❌ Biometric authentication error: $e');
      return false;
    }
  }

  /// Get biometric type name for display
  static String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.isNotEmpty) {
      return 'Biometric';
    }
    return 'None';
  }
}

/// Model for biometric availability information
class BiometricAvailability {
  final bool isAvailable;
  final bool hasFingerprint;
  final bool hasFaceId;
  final List<BiometricType> availableTypes;
  final String message;

  BiometricAvailability({
    required this.isAvailable,
    required this.hasFingerprint,
    required this.hasFaceId,
    required this.availableTypes,
    required this.message,
  });

  String get biometricTypeName => BiometricHelper.getBiometricTypeName(availableTypes);
}
