import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../../app/socket/socket_provider.dart';
import '../../feature/auth/data/api_data.dart';

/// Service that handles the complete authentication flow:
/// 1. User logs in/registers
/// 2. Access token saved
/// 3. FCM token generated
/// 4. FCM token saved  
/// 5. Socket connects
/// 6. Socket sends { accessToken, fcmToken }
class AuthFlowService {
  final Ref ref;
  
  AuthFlowService(this.ref);

  /// Complete the authentication flow after successful login/register
  Future<void> completeAuthFlow() async {
    try {
      debugPrint('🚀 Starting complete auth flow...');
      
      // Step 1: Verify access token is saved
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      
      // Try getting from ApiClient first (if it was just primed)
      String? accessToken = ref.read(apiClientProvider).token;
      
      // If empty, try SecureStorage
      if (accessToken.isEmpty && userId.isNotEmpty) {
        const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
        accessToken = await storage.read(key: 'access_token_$userId');
      }
      
      // Legacy fallback
      if (accessToken == null || accessToken.isEmpty) {
        accessToken = authBox.get('token');
      }
      
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('❌ No access token found in ApiClient, SecureStorage or Hive. Cannot complete auth flow');
        return;
      }
      debugPrint('✅ Step 1: Access token verified');
      
      // Step 2: Try to get a fresh FCM token with iOS APNS retry logic
      debugPrint('🔥 Fetching fresh FCM token...');
      String? newFcmToken;
      try {
        newFcmToken = await FirebaseMessaging.instance.getToken();
      } catch (fcmError) {
        // On iOS, APNS token may not be ready immediately after app launch.
        // This is a known timing issue — we retry once after a short delay.
        debugPrint('⚠️ FCM token fetch failed (likely APNS not ready on iOS): $fcmError');
        debugPrint('⏳ Retrying FCM token fetch in 3 seconds...');
        await Future.delayed(const Duration(seconds: 3));
        try {
          newFcmToken = await FirebaseMessaging.instance.getToken();
        } catch (retryError) {
          debugPrint('⚠️ FCM token retry also failed: $retryError. Will proceed with cached token if available.');
        }
      }

      if (newFcmToken != null) {
        await authBox.put('fcmToken', newFcmToken);
        debugPrint('✅ Step 2: FCM token updated');
      } else {
        debugPrint('⚠️ Could not fetch fresh FCM token, using stored one if available');
      }
      
      final currentFcmToken = authBox.get('fcmToken');
      if (currentFcmToken == null || currentFcmToken.isEmpty) {
        // FCM token is unavailable (e.g. simulator or APNS not configured).
        // We still connect the socket so the session is established —
        // push notifications just won't be registered this session.
        debugPrint('⚠️ No FCM token available — connecting socket without push notification registration');
      }
      
      // Step 3: Connect socket (regardless of FCM status)
      debugPrint('🔌 Step 3: Connecting socket...');
      final socketNotifier = ref.read(socketNotifierProvider.notifier);
      await socketNotifier.connect();
      
      debugPrint('✅ Auth flow completed successfully!');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Auth flow failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Verify that all required tokens are present
  Future<bool> verifyAuthState() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final fcmToken = authBox.get('fcmToken');
      
      String? accessToken = authBox.get('token');
      if ((accessToken == null || accessToken.isEmpty) && userId.isNotEmpty) {
        const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
        accessToken = await storage.read(key: 'access_token_$userId');
      }
      
      return accessToken != null && 
             accessToken.isNotEmpty && 
             fcmToken != null && 
             fcmToken.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error verifying auth state: $e');
      return false;
    }
  }

  /// Clear all auth data and disconnect socket
  Future<void> clearAuthFlow() async {
    try {
      debugPrint('🧹 Clearing auth flow...');
      
      // Disconnect socket first
      final socketNotifier = ref.read(socketNotifierProvider.notifier);
      socketNotifier.disconnect();
      
      // Clear auth data
      final authBox = await Hive.openBox('authBox');
      await authBox.clear();
      
      debugPrint('✅ Auth flow cleared');
    } catch (e) {
      debugPrint('❌ Error clearing auth flow: $e');
    }
  }
}

// Provider for the auth flow service
final authFlowServiceProvider = Provider<AuthFlowService>((ref) {
  return AuthFlowService(ref);
});