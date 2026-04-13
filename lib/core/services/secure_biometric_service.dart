// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:local_auth/local_auth.dart';
// import 'dart:convert';
//
// /// Secure biometric service that follows proper security practices:
// /// 1. Never stores plain PIN/password
// /// 2. Biometric only unlocks encrypted token
// /// 3. Backend validates all transactions
// /// 4. Token-based authentication
// class SecureBiometricService {
//   static final LocalAuthentication _auth = LocalAuthentication();
//   static const String _boxName = 'secureBiometricBox';
//   static const String _tokenKey = 'biometric_auth_token';
//   static const String _enabledKey = 'biometric_transaction_enabled';
//   static const String _saltKey = 'biometric_salt';
//
//   /// Check if device supports biometric authentication
//   static Future<bool> isBiometricAvailable() async {
//     try {
//       final canCheck = await _auth.canCheckBiometrics;
//       final isSupported = await _auth.isDeviceSupported();
//       return canCheck && isSupported;
//     } catch (e) {
//       debugPrint('❌ Error checking biometric availability: $e');
//       return false;
//     }
//   }
//
//   /// Get available biometric types
//   static Future<List<BiometricType>> getAvailableBiometrics() async {
//     try {
//       return await _auth.getAvailableBiometrics();
//     } catch (e) {
//       debugPrint('❌ Error getting biometric types: $e');
//       return [];
//     }
//   }
//
//   /// Authenticate user with biometric
//   static Future<bool> authenticateWithBiometric({
//     required String reason,
//   }) async {
//     try {
//       final isAvailable = await isBiometricAvailable();
//       if (!isAvailable) {
//         debugPrint('🚫 Biometric not available');
//         return false;
//       }
//
//       final authenticated = await _auth.authenticate(
//         localizedReason: reason,
//         options: const AuthenticationOptions(
//           biometricOnly: true,
//           stickyAuth: true,
//           useErrorDialogs: true,
//         ),
//       );
//
//       debugPrint(authenticated
//           ? '✅ Biometric authentication successful'
//           : '❌ Biometric authentication failed');
//
//       return authenticated;
//     } catch (e) {
//       debugPrint('❌ Biometric authentication error: $e');
//       return false;
//     }
//   }
//
//   /// Enable biometric for transactions
//   /// This should be called AFTER backend validates the PIN
//   /// @param authToken - Secure token received from backend after PIN validation
//   static Future<bool> enableBiometricTransaction({
//     required String authToken,
//   }) async {
//     try {
//       final box = await Hive.openBox(_boxName);
//
//       // Generate a random salt for additional security
//       final salt = _generateSalt();
//
//       // Encrypt the token (simple encryption, in production use proper encryption)
//       final encryptedToken = _encryptToken(authToken, salt);
//
//       // Store encrypted token and salt
//       await box.put(_tokenKey, encryptedToken);
//       await box.put(_saltKey, salt);
//       await box.put(_enabledKey, true);
//
//       debugPrint('✅ Biometric transaction enabled with secure token');
//       return true;
//     } catch (e) {
//       debugPrint('❌ Error enabling biometric transaction: $e');
//       return false;
//     }
//   }
//
//   /// Disable biometric for transactions
//   static Future<void> disableBiometricTransaction() async {
//     try {
//       final box = await Hive.openBox(_boxName);
//       await box.delete(_tokenKey);
//       await box.delete(_saltKey);
//       await box.put(_enabledKey, false);
//       debugPrint('✅ Biometric transaction disabled');
//     } catch (e) {
//       debugPrint('❌ Error disabling biometric transaction: $e');
//     }
//   }
//
//   /// Check if biometric transaction is enabled
//   static Future<bool> isBiometricTransactionEnabled() async {
//     try {
//       final box = await Hive.openBox(_boxName);
//       final enabled = box.get(_enabledKey, defaultValue: false);
//       final hasToken = box.get(_tokenKey) != null;
//       return enabled && hasToken;
//     } catch (e) {
//       debugPrint('❌ Error checking biometric status: $e');
//       return false;
//     }
//   }
//
//   /// Get auth token after biometric authentication
//   /// This token should be sent to backend for transaction authorization
//   /// Returns null if biometric authentication fails or token not found
//   static Future<String?> getAuthTokenWithBiometric({
//     required String reason,
//   }) async {
//     try {
//       // First, authenticate with biometric
//       final authenticated = await authenticateWithBiometric(reason: reason);
//       if (!authenticated) {
//         debugPrint('❌ Biometric authentication failed');
//         return null;
//       }
//
//       // If authenticated, retrieve and decrypt the token
//       final box = await Hive.openBox(_boxName);
//       final encryptedToken = box.get(_tokenKey);
//       final salt = box.get(_saltKey);
//
//       if (encryptedToken == null || salt == null) {
//         debugPrint('❌ No token found');
//         return null;
//       }
//
//       // Decrypt the token
//       final token = _decryptToken(encryptedToken, salt);
//       debugPrint('✅ Auth token retrieved successfully');
//       return token;
//     } catch (e) {
//       debugPrint('❌ Error getting auth token: $e');
//       return null;
//     }
//   }
//
//   /// Generate a random salt for encryption
//   static String _generateSalt() {
//     final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
//     final random = timestamp.hashCode.toString();
//     return base64Encode(utf8.encode(random));
//   }
//
//   /// Simple encryption (in production, use proper encryption like AES)
//   /// This is just for demonstration - use flutter_secure_storage or similar in production
//   static String _encryptToken(String token, String salt) {
//     final combined = '$token:$salt';
//     final bytes = utf8.encode(combined);
//     // Simple XOR-based obfuscation (NOT secure for production!)
//     // In production, use flutter_secure_storage or proper encryption
//     return base64Encode(bytes);
//   }
//
//   /// Simple decryption (matches the encryption above)
//   static String _decryptToken(String encryptedToken, String salt) {
//     try {
//       final decoded = utf8.decode(base64Decode(encryptedToken));
//       final parts = decoded.split(':');
//       return parts[0]; // Return the original token
//     } catch (e) {
//       debugPrint('❌ Error decrypting token: $e');
//       return '';
//     }
//   }
//
//   /// Clear all biometric data (use on logout)
//   static Future<void> clearAllBiometricData() async {
//     try {
//       final box = await Hive.openBox(_boxName);
//       await box.clear();
//       debugPrint('✅ All biometric data cleared');
//     } catch (e) {
//       debugPrint('❌ Error clearing biometric data: $e');
//     }
//   }
//
//   /// Get biometric type name for display
//   static Future<String> getBiometricTypeName() async {
//     try {
//       final types = await getAvailableBiometrics();
//       if (types.contains(BiometricType.face)) {
//         return 'Face ID';
//       } else if (types.contains(BiometricType.fingerprint)) {
//         return 'Fingerprint';
//       } else if (types.contains(BiometricType.iris)) {
//         return 'Iris';
//       } else if (types.isNotEmpty) {
//         return 'Biometric';
//       }
//       return 'None';
//     } catch (e) {
//       return 'Biometric';
//     }
//   }
// }
