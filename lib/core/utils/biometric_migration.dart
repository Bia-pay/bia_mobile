import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/biometric_service.dart';

/// Helper class to migrate old global biometric settings to user-specific settings
/// This should be called once after updating to the new user-specific biometric system
class BiometricMigration {
  /// Migrate old global biometric settings to user-specific settings
  /// Call this after user logs in successfully
  static Future<void> migrateToUserSpecificSettings() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final settingsBox = await Hive.openBox('settingsBox');
      
      final userId = authBox.get('userId', defaultValue: '');
      
      if (userId.isEmpty) {
        debugPrint('⚠️ No userId found, skipping migration');
        return;
      }

      // Check if user already has new settings (already migrated)
      final hasNewSettings = settingsBox.containsKey('biometric_enabled_$userId') ||
                             settingsBox.containsKey('login_biometric_enabled_$userId');
      
      if (hasNewSettings) {
        debugPrint('✅ User $userId already has new biometric settings, skipping migration');
        return;
      }

      bool migrated = false;

      final biometricService = BiometricService();

      // Migrate transaction biometric settings
      final oldBiometricEnabled = settingsBox.get('biometric_enabled', defaultValue: false);
      final oldSavedPin = settingsBox.get('saved_pin');
      
      if (oldBiometricEnabled && oldSavedPin != null) {
        await biometricService.setPaymentEnabled(userId, true);
        await biometricService.saveTransactionPin(userId, oldSavedPin);
        debugPrint('✅ Migrated transaction biometric for user $userId');
        migrated = true;
      }

      // Migrate login biometric settings
      final oldLoginBiometricEnabled = settingsBox.get('login_biometric_enabled', defaultValue: false);
      final oldLoginPassword = settingsBox.get('biometric_login_password');
      
      if (oldLoginBiometricEnabled && oldLoginPassword != null) {
        final phone = authBox.get('phone', defaultValue: '');
        await biometricService.setLoginEnabled(userId, true);
        await biometricService.saveLoginCredentials(userId, phone, oldLoginPassword);
        debugPrint('✅ Migrated login biometric for user $userId');
        migrated = true;
      }

      if (migrated) {
        debugPrint('🎉 Successfully migrated biometric settings for user $userId');
        
        // Clean up old keys after successful migration so they don't leak
        await settingsBox.delete('biometric_enabled');
        await settingsBox.delete('saved_pin');
        await settingsBox.delete('login_biometric_enabled');
        await settingsBox.delete('biometric_login_password');
      } else {
        debugPrint('ℹ️ No old biometric settings found to migrate for user $userId');
      }
    } catch (e) {
      debugPrint('❌ Error during biometric migration: $e');
    }
  }

  /// Clean up old global biometric keys
  /// Call this after all users have been migrated
  static Future<void> cleanupOldGlobalKeys() async {
    try {
      final settingsBox = await Hive.openBox('settingsBox');
      
      await settingsBox.delete('biometric_enabled');
      await settingsBox.delete('saved_pin');
      await settingsBox.delete('login_biometric_enabled');
      await settingsBox.delete('biometric_login_password');
      
      debugPrint('✅ Cleaned up old global biometric keys');
    } catch (e) {
      debugPrint('❌ Error cleaning up old keys: $e');
    }
  }

  /// Check if migration is needed for current user
  static Future<bool> needsMigration() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final settingsBox = await Hive.openBox('settingsBox');
      
      final userId = authBox.get('userId', defaultValue: '');
      
      if (userId.isEmpty) return false;

      // Check if user has new settings
      final hasNewSettings = settingsBox.containsKey('biometric_enabled_$userId') ||
                             settingsBox.containsKey('login_biometric_enabled_$userId');
      
      if (hasNewSettings) return false;

      // Check if old settings exist
      final hasOldSettings = settingsBox.containsKey('biometric_enabled') ||
                             settingsBox.containsKey('login_biometric_enabled');
      
      return hasOldSettings;
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return false;
    }
  }
}
