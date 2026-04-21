import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Handles device biometrics (fingerprint/FaceID) and user preferences
/// for login and payment confirmation.
/// 
/// Uses:
/// - SharedPreferences for user preferences (enabled/disabled state)
/// - FlutterSecureStorage for sensitive credentials (passwords, PINs)
/// - LocalAuthentication for biometric hardware interaction
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Preference keys (per-user)
  static String _loginEnabledKey(String userId) => 'biometric_login_enabled_$userId';
  static String _paymentEnabledKey(String userId) => 'biometric_payment_enabled_$userId';
  static String _initialPromptShownKey(String userId) => 'biometric_initial_prompt_shown_$userId';

  // Secure storage keys (per-user)
  static String _loginPasswordKey(String userId) => 'biometric_login_password_$userId';
  static String _transactionPinKey(String userId) => 'biometric_transaction_pin_$userId';

  // ==================== DEVICE CAPABILITIES ====================

  /// Check if device has biometric hardware
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }
  /// Check if biometrics can be used (hardware + enrolled)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get the type of biometric available (face, fingerprint, etc.)
  Future<BiometricType> getBiometricType() async {
    try {
      final List<BiometricType> availableBiometrics = 
          await _auth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      } else if (availableBiometrics.contains(BiometricType.fingerprint) || 
                 availableBiometrics.contains(BiometricType.strong)) {
        return BiometricType.fingerprint;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting biometric type: $e');
    }
    return BiometricType.fingerprint; // Default fallback
  }

  /// Get user-friendly name for biometric type
  Future<String> getBiometricTypeName() async {
    final type = await getBiometricType();
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
      case BiometricType.strong:
        return 'Fingerprint';
      case BiometricType.weak:
        return 'Biometric';
      default:
        return 'Biometric';
    }
  }

  // ==================== LOGIN BIOMETRIC ====================

  /// Check if user has ever set a login biometric preference
  /// This helps distinguish between "never set" vs "explicitly disabled"
  Future<bool> hasLoginPreferenceBeenSet(String userId) async {
    if (userId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    // Check if the key exists (regardless of value)
    return prefs.containsKey(_loginEnabledKey(userId));
  }

  /// Check if login biometric is enabled for user
  Future<bool> isLoginEnabled(String userId) async {
    if (userId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginEnabledKey(userId)) ?? false;
  }

  /// Enable/disable login biometric for user
  Future<void> setLoginEnabled(String userId, bool enabled) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginEnabledKey(userId), enabled);
    debugPrint('🔐 Login biometric ${enabled ? "enabled" : "disabled"} for user: $userId');
  }

  /// Save login credentials securely
  Future<void> saveLoginCredentials(String userId, String phone, String password) async {
    if (userId.isEmpty) return;
    await _storage.write(key: _loginPasswordKey(userId), value: password);
    debugPrint('🔐 Login credentials saved securely for user: $userId');
  }

  /// Get saved login credentials
  Future<String?> getLoginPassword(String userId) async {
    if (userId.isEmpty) return null;
    return await _storage.read(key: _loginPasswordKey(userId));
  }

  /// Clear login credentials
  Future<void> clearLoginCredentials(String userId) async {
    if (userId.isEmpty) return;
    await _storage.delete(key: _loginPasswordKey(userId));
    await setLoginEnabled(userId, false);
    debugPrint('🔐 Login credentials cleared for user: $userId');
  }

  // ==================== PAYMENT BIOMETRIC ====================

  /// Check if user has ever set a payment biometric preference
  Future<bool> hasPaymentPreferenceBeenSet(String userId) async {
    if (userId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_paymentEnabledKey(userId));
  }

  /// Check if payment biometric is enabled for user
  /// Check if payment biometric is enabled for user
  Future<bool> isPaymentEnabled(String userId) async {
    if (userId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paymentEnabledKey(userId)) ?? false;
  }
  /// Enable/disable payment biometric for user
  Future<void> setPaymentEnabled(String userId, bool enabled) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_paymentEnabledKey(userId), enabled);
    
    // Verify it was actually saved
    final verified = prefs.getBool(_paymentEnabledKey(userId)) ?? false;
    debugPrint('🔐 Payment biometric ${enabled ? "enabled" : "disabled"} for user: $userId');
    debugPrint('🔐 Verification - actual value in SharedPreferences: $verified');
    debugPrint('🔐 Key used: ${_paymentEnabledKey(userId)}');
  }

  /// Save transaction PIN securely
  Future<void> saveTransactionPin(String userId, String pin) async {
    if (userId.isEmpty) return;
    await _storage.write(key: _transactionPinKey(userId), value: pin);
    debugPrint('🔐 Transaction PIN saved securely for user: $userId');
  }

  /// Get saved transaction PIN
  Future<String?> getTransactionPin(String userId) async {
    if (userId.isEmpty) return null;
    final pin = await _storage.read(key: _transactionPinKey(userId));
    debugPrint('🔐 Transaction PIN retrieved: ${pin != null ? "****" : "NULL"}');
    return pin;
  }

  /// Clear transaction PIN
  Future<void> clearTransactionPin(String userId) async {
    if (userId.isEmpty) return;
    await _storage.delete(key: _transactionPinKey(userId));
    await setPaymentEnabled(userId, false);
    debugPrint('🔐 Transaction PIN cleared for user: $userId');
  }

  // ==================== INITIAL PROMPT (UX) ====================

  /// Check if we should show the initial biometric setup prompt
  Future<bool> shouldShowInitialPrompt(String userId) async {
    if (userId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_initialPromptShownKey(userId)) ?? false);
  }

  /// Mark that initial prompt has been shown
  Future<void> markInitialPromptShown(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initialPromptShownKey(userId), true);
  }

  // ==================== AUTHENTICATION ====================

  /// Perform biometric authentication with custom reason
  Future<bool> authenticate({required String reason, bool biometricOnly = true}) async {
    try {
      final supported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();

      if (!supported || !canCheck) {
        debugPrint('⚠️ Biometric not available');
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );

      debugPrint('🔐 Biometric auth result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      debugPrint('❌ Biometric auth error: $e');
      return false;
    }
  }

  // ==================== COMPLETE SETUP FLOWS ====================

  /// Complete flow to enable login biometric
  /// Complete flow to enable login biometric
  Future<bool> enableLoginBiometric({
    required String userId,
    required String phone,
    required String password,
  }) async {
    try {
      // 1. Check device capability
      if (!await canCheckBiometrics()) {
        debugPrint('❌ Biometric not available');
        return false;
      }

      // 2. Authenticate user
      final typeName = await getBiometricTypeName();
      final authenticated = await authenticate(
        reason: 'Authenticate to enable $typeName login',
        biometricOnly: true,
      );

      if (!authenticated) {
        debugPrint('❌ Biometric authentication failed');
        return false;
      }

      // 3. Save credentials securely (LOGIN uses password, not PIN!)
      await saveLoginCredentials(userId, phone, password);

      // 4. Enable the setting
      await setLoginEnabled(userId, true);

      debugPrint('✅ Login biometric enabled for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling login biometric: $e');
      return false;
    }
  }

  /// Complete flow to enable payment biometric
  Future<bool> enablePaymentBiometric({
    required String userId,
    required String pin,
  }) async {
    try {
      // 1. Check device capability
      if (!await canCheckBiometrics()) {
        debugPrint('❌ Biometric not available');
        return false;
      }

      // 2. Authenticate user
      final typeName = await getBiometricTypeName();
      final authenticated = await authenticate(
        reason: 'Authenticate to enable $typeName for payments',
        biometricOnly: true,
      );

      if (!authenticated) {
        debugPrint('❌ Biometric authentication failed');
        return false;
      }

      // 3. Save PIN securely
      await saveTransactionPin(userId, pin);

      // 4. Enable the setting
      await setPaymentEnabled(userId, true);

      debugPrint('✅ Payment biometric enabled for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling payment biometric: $e');
      return false;
    }
  }

  /// Disable login biometric
  Future<void> disableLoginBiometric(String userId) async {
    await clearLoginCredentials(userId);
    debugPrint('✅ Login biometric disabled for user: $userId');
  }

  /// Disable payment biometric
  Future<void> disablePaymentBiometric(String userId) async {
    await clearTransactionPin(userId);
    debugPrint('✅ Payment biometric disabled for user: $userId');
  }

  // ==================== LOGOUT CLEANUP ====================

  /// Clear credentials on logout but keep preferences (enabled/disabled choice persists)
  Future<void> clearUserBiometricData(String userId) async {
    if (userId.isEmpty) return;

    // Clear secure credentials only — preferences stay so user's choice persists
    await _storage.delete(key: _loginPasswordKey(userId));
    await _storage.delete(key: _transactionPinKey(userId));

    debugPrint('🔐 Cleared biometric credentials for user: $userId');
  }

  /// Complete reset - clear everything including preferences (use with caution)
  Future<void> completeReset(String userId) async {
    if (userId.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all preferences
    await prefs.remove(_loginEnabledKey(userId));
    await prefs.remove(_paymentEnabledKey(userId));
    await prefs.remove(_initialPromptShownKey(userId));
    
    // Clear all credentials
    await _storage.delete(key: _loginPasswordKey(userId));
    await _storage.delete(key: _transactionPinKey(userId));
    
    debugPrint('🔐 Complete biometric reset for user: $userId');
  }
}
