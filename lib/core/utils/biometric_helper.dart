import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Get current user ID - CRITICAL for per-user isolation
  static Future<String?> _getCurrentUserId() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId');
      final phone = authBox.get('phone'); // Fallback to phone if userId not set

      // Use phone number as unique identifier if userId not available
      final uniqueId = userId?.toString() ?? phone?.toString();

      debugPrint('🔐 Current user ID: $uniqueId');
      return uniqueId;
    } catch (e) {
      debugPrint('❌ Error getting userId: $e');
      return null;
    }
  }

  /// Check if device has biometric hardware and it's available
  static Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        return BiometricAvailability(
          isAvailable: false,
          hasFingerprint: false,
          hasFaceId: false,
          availableTypes: [],
          message: 'Device does not support biometric authentication',
        );
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();
      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
      final hasFaceId = availableBiometrics.contains(BiometricType.face);

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

  /// Check if biometric is enabled for TRANSACTIONS (current user only)
  static Future<bool> isTransactionBiometricEnabled() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found, transaction biometric disabled');
        return false;
      }

      final box = await Hive.openBox('settingsBox');
      final isEnabled = box.get('biometric_enabled_$userId', defaultValue: false);

      debugPrint('🔐 Transaction biometric for $userId: $isEnabled');
      return isEnabled;
    } catch (e) {
      debugPrint('❌ Error checking transaction biometric: $e');
      return false;
    }
  }

  /// Check if biometric is enabled for LOGIN (current user only)
  static Future<bool> isLoginBiometricEnabled() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found, login biometric disabled');
        return false;
      }

      final box = await Hive.openBox('settingsBox');

      // Must have BOTH the flag AND the password stored
      final isEnabledFlag = box.get('login_biometric_enabled_$userId', defaultValue: false);
      final hasPassword = box.get('biometric_login_password_$userId') != null;

      final isFullyEnabled = isEnabledFlag && hasPassword;

      debugPrint('🔐 Login biometric for $userId: flag=$isEnabledFlag, hasPassword=$hasPassword, enabled=$isFullyEnabled');
      return isFullyEnabled;
    } catch (e) {
      debugPrint('❌ Error checking login biometric: $e');
      return false;
    }
  }

  /// Get saved password for current user only
  static Future<String?> getSavedPassword() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found, cannot get saved password');
        return null;
      }

      final box = await Hive.openBox('settingsBox');
      final password = box.get('biometric_login_password_$userId');

      debugPrint('🔐 Retrieved password for $userId: ${password != null ? 'exists' : 'null'}');
      return password;
    } catch (e) {
      debugPrint('❌ Error getting saved password: $e');
      return null;
    }
  }

  /// Get saved PIN for current user - checks multiple keys
  static Future<String?> getSavedPin() async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      // Try phone as fallback
      final authBox = await Hive.openBox('authBox');
      final phone = authBox.get('phone');
      if (phone == null || phone.toString().isEmpty) {
        return null;
      }
      // Use phone to look up
      final box = await Hive.openBox('settingsBox');
      return box.get('saved_pin_$phone') ??
          box.get('biometric_login_password_$phone');
    }
    
    final box = await Hive.openBox('settingsBox');
    return box.get('saved_pin_$userId') ?? 
           box.get('biometric_login_password_$userId');
  }

  /// Enable transaction biometric for current user only
  static Future<bool> enableTransactionBiometric(String pin) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found, cannot enable transaction biometric');
        return false;
      }

      final box = await Hive.openBox('settingsBox');
      await box.put('biometric_enabled_$userId', true);
      await box.put('saved_pin_$userId', pin);

      debugPrint('✅ Transaction biometric enabled for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling transaction biometric: $e');
      return false;
    }
  }

  /// Disable transaction biometric for current user only
  static Future<bool> disableTransactionBiometric() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found');
        return false;
      }

      final box = await Hive.openBox('settingsBox');
      await box.put('biometric_enabled_$userId', false);
      await box.delete('saved_pin_$userId');

      debugPrint('✅ Transaction biometric disabled for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling transaction biometric: $e');
      return false;
    }
  }

  /// Enable login biometric for current user only
  static Future<bool> enableLoginBiometric(String password) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found, cannot enable login biometric');
        return false;
      }

      final box = await Hive.openBox('settingsBox');
      await box.put('login_biometric_enabled_$userId', true);
      await box.put('biometric_login_password_$userId', password);

      debugPrint('✅ Login biometric enabled for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling login biometric: $e');
      return false;
    }
  }

  /// Disable login biometric for current user only
  static Future<bool> disableLoginBiometric() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found');
        return false;
      }

      final box = await Hive.openBox('settingsBox');
      await box.put('login_biometric_enabled_$userId', false);
      await box.delete('biometric_login_password_$userId');

      debugPrint('✅ Login biometric disabled for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling login biometric: $e');
      return false;
    }
  }

  /// Clear ALL biometric data for current user (call on logout)
  static Future<bool> clearCurrentUserBiometricData() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ No userId found, nothing to clear');
        return false;
      }

      final box = await Hive.openBox('settingsBox');

      // Delete all user-specific biometric keys
      await box.delete('biometric_enabled_$userId');
      await box.delete('saved_pin_$userId');
      await box.delete('login_biometric_enabled_$userId');
      await box.delete('biometric_login_password_$userId');

      debugPrint('🗑️ Cleared all biometric data for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing biometric data: $e');
      return false;
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