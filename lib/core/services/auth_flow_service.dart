import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../app/socket/socket_provider.dart';

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
      final accessToken = authBox.get('token');
      
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('❌ No access token found, cannot complete auth flow');
        return;
      }
      debugPrint('✅ Step 1: Access token verified');
      
      // Step 2: Always get a fresh FCM token
      debugPrint('🔥 Fetching fresh FCM token...');
      final newFcmToken = await FirebaseMessaging.instance.getToken();
      if (newFcmToken != null) {
        await authBox.put('fcmToken', newFcmToken);
        debugPrint('✅ Step 2: FCM token updated');
      } else {
        debugPrint('⚠️ Could not fetch fresh FCM token, using stored one if available');
      }
      
      final currentFcmToken = authBox.get('fcmToken');
      if (currentFcmToken == null || currentFcmToken.isEmpty) {
        debugPrint('❌ No FCM token available, cannot register');
        return;
      }
      
      // Step 3: Connect socket with both tokens
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
      final accessToken = authBox.get('token');
      final fcmToken = authBox.get('fcmToken');
      
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