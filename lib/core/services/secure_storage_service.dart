import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // Centralized Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';

  // Generic write method
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Generic read method
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Generic delete method
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Check if a key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Onboarding methods
  Future<bool> hasSeenOnboarding() async {
    final val = await read(keyHasSeenOnboarding);
    return val == 'true';
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    await write(keyHasSeenOnboarding, value.toString());
  }

  // Auth/Session status methods
  Future<bool> isLoggedIn() async {
    final val = await read(keyIsLoggedIn);
    return val == 'true';
  }

  Future<void> setLoggedIn(bool value) async {
    await write(keyIsLoggedIn, value.toString());
  }

  Future<String?> getAccessToken() async {
    return await read(keyAccessToken);
  }

  Future<void> setAccessToken(String token) async {
    await write(keyAccessToken, token);
  }

  Future<String?> getRefreshToken() async {
    return await read(keyRefreshToken);
  }

  Future<void> setRefreshToken(String token) async {
    await write(keyRefreshToken, token);
  }

  Future<String?> getUserId() async {
    return await read(keyUserId);
  }

  Future<void> setUserId(String userId) async {
    await write(keyUserId, userId);
  }

  // Clear Session (Clears authentication/tokens, keeps onboarding flag intact)
  Future<void> clearSession() async {
    await delete(keyIsLoggedIn);
    await delete(keyAccessToken);
    await delete(keyRefreshToken);
    await delete(keyUserId);
  }

  // Total Reset (used only in app wipe / testing, if needed)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

// Riverpod Provider
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
