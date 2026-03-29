import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../../app/utils/device_helper.dart';
import '../../../core/local/transaction_cache.dart';
import '../../../core/services/auth_flow_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/utils/biometric_migration.dart';
import '../data/api_constant.dart';
import '../data/api_data.dart';
import '../modal/reponse/response_modal.dart';
import 'package:local_auth/local_auth.dart';

final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient, ref);
});

class AuthRepository {
  final ApiClient _apiClient;
  final Ref _ref;

  AuthRepository(this._apiClient, this._ref);

// ---------------- LOGOUT ----------------
  Future<ResponseModel> logout() async {
    try {
      final box = await Hive.openBox('authBox');

      // Get current user info for logging
      final userId = box.get('userId', defaultValue: '');
      final phone = box.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      // Call backend logout
      try {
        await _apiClient.deleteData(ApiConstant.LOGOUT);
      } catch (_) {}

      // Stop token refresh
      _apiClient.dispose();

      // Clear user cache
      if (userId.isNotEmpty) {
        await TransactionCache.clearTransactions(userId);
      }

      // 🔹 Clear biometric credentials but KEEP login credentials for next biometric login
      if (effectiveUserId.isNotEmpty) {
        await BiometricService().clearUserBiometricData(effectiveUserId, keepLoginCredentials: true);
      }

      // 🔹 ONLY delete sensitive tokens, NEVER clear user identification
      await box.delete('token');
      await box.delete('refreshToken');
      await box.delete('balance');
      await box.delete('saved_user_profile');
      // 🔹 DO NOT delete: userId, phone, fullname, picture

      debugPrint('🔐 Logout complete for user: $userId');

      return ResponseModel(
        responseMessage: "Logged out successfully",
        responseSuccessful: true,
        statusCode: 200,
      );
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      return ResponseModel(
        responseMessage: "Logout failed",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }



  Future<ResponseModel> logIn(
      Map<String, dynamic> body, {
        bool fromBiometric = false,
      }) async {
    print('📡 Attempting login...');

    try {
      final ipAddress = await DeviceHelper.getIpAddress();
      final deviceName = await DeviceHelper.getDeviceName();

      body['ipAddress'] = ipAddress;
      body['device'] = deviceName;

      print("📤 Final body sent to backend: $body");

      final response =
      await _apiClient.postData(ApiConstant.LOGIN, body);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        print("✅ Login Success: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};
        final userJson =
        Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson =
        Map<String, dynamic>.from(responseBody['wallet'] ?? {});
        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        final box = await Hive.openBox('authBox');
        
        // 🔹 Save password for biometric login (user-specific)
        if (!fromBiometric && body.containsKey('password')) {
          final userId = userJson['id']?.toString() ?? '';
          final phone = userJson['phone']?.toString() ?? '';
          final effectiveId = userId.isNotEmpty ? userId : phone;

          if (effectiveId.isNotEmpty) {
            final biometricService = BiometricService();
            final password = body['password'];

            // Always save credentials securely (for potential biometric use)
            await biometricService.saveLoginCredentials(effectiveId, phone, password);

            // 🔹 CRITICAL FIX: Only enable on FIRST login, never override user choice
            // Check if user has ever interacted with this setting
            final hasEverBeenSet = await biometricService.hasLoginPreferenceBeenSet(effectiveId);
            
            if (!hasEverBeenSet) {
              // First time ever - enable by default and mark as set
              await biometricService.setLoginEnabled(effectiveId, true);
              await biometricService.markInitialPromptShown(effectiveId);
              debugPrint('🔐 First login - enabled biometric for: $effectiveId');
            } else {
              // User has made a choice before - respect it (don't change anything)
              final currentSetting = await biometricService.isLoginEnabled(effectiveId);
              debugPrint('🔐 Existing user - keeping biometric setting: $currentSetting for: $effectiveId');
            }
          }
        }
        
        await box.put("token", accessToken);
        await box.put("refreshToken", refreshToken);
        await box.put("userId", userJson['id']?.toString() ?? '');
        await box.put("fullname", userJson['fullname'] ?? '');
        await box.put("phone", userJson['phone'] ?? '');
        await box.put("balance", walletJson['balance'] ?? 0);
        await box.put("currency", walletJson['currency'] ?? 'NGN');
        await box.put(
          "has_pin",
          userJson['pin'] != null &&
              userJson['pin'].toString().isNotEmpty,
        );

        // This duplicate code block is handled above - removed to prevent conflicts

        _apiClient.updateHeaders(accessToken);

        final authFlowService =
        _ref.read(authFlowServiceProvider);
        await authFlowService.completeAuthFlow();

        // Migrate old biometric settings to user-specific settings
        try {
          await BiometricMigration.migrateToUserSpecificSettings();
        } catch (e) {
          debugPrint('⚠️ Biometric migration skipped: $e');
        }

        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ??
              'Login successful',
          responseSuccessful: true,
          statusCode: response.statusCode,
        );
      }

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ??
            'Login failed',
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('🔥 Login Exception: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }  /// ---------------- SET PIN ----------------
  // Future<ResponseModel> setPin(String pin, String confirmPin) async {
  //   try {
  //     final body = {'pin': pin, 'confirmPin': confirmPin};
  //     final response = await _apiClient.postData(ApiConstant.SET_PIN, body);
  //     final jsonResponse = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200) {
  //       print("✅ PIN set successfully: $jsonResponse");
  //       return ResponseModel(
  //         responseMessage: jsonResponse['responseMessage'] ?? 'PIN set successfully',
  //         responseSuccessful: true,
  //         statusCode: response.statusCode,
  //       );
  //     }
  //
  //     return ResponseModel(
  //       responseMessage: jsonResponse['responseMessage'] ?? 'Failed to set PIN',
  //       responseSuccessful: false,
  //       statusCode: response.statusCode,
  //     );
  //   } catch (e) {
  //     print("🔥 Set PIN Exception: $e");
  //     return ResponseModel(
  //       responseMessage: 'Something went wrong. Try again.',
  //       responseSuccessful: false,
  //       statusCode: 500,
  //     );
  //   }
  // }
  /// ---------------- SET PIN ----------------
  Future<ResponseModel> setPin(String pin, String confirmPin) async {
    try {
      final body = {'pin': pin, 'confirmPin': confirmPin};
      final response = await _apiClient.postData(ApiConstant.SET_PIN, body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ PIN set successfully: $jsonResponse");

        // Save PIN securely for biometric use
        final authBox = await Hive.openBox('authBox');
        final userId = authBox.get('userId', defaultValue: '');
        final phone = authBox.get('phone', defaultValue: '');
        final effectiveUserId = userId.isNotEmpty ? userId : phone;

        if (effectiveUserId.isNotEmpty) {
          final biometricService = BiometricService();
          await biometricService.saveTransactionPin(effectiveUserId, pin);
          print("🔐 PIN saved securely for biometric use: $effectiveUserId");
        }

        return ResponseModel(
          responseMessage: jsonResponse['responseMessage'] ?? 'PIN set successfully',
          responseSuccessful: true,
          statusCode: response.statusCode,
        );
      }

      return ResponseModel(
        responseMessage: jsonResponse['responseMessage'] ?? 'Failed to set PIN',
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print("🔥 Set PIN Exception: $e");
      return ResponseModel(
        responseMessage: 'Something went wrong. Try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel?> biometricLogin() async {
    try {
      final box = await Hive.openBox('authBox');
      final biometricService = BiometricService();
      
      final userId = box.get('userId', defaultValue: '');
      final phone = box.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;
      
      if (effectiveUserId.isEmpty) {
        debugPrint('⚠️ No userId found for biometric login');
        return null;
      }

      // Check if biometric is enabled for this user
      final enabled = await biometricService.isLoginEnabled(effectiveUserId);
      final canCheck = await biometricService.canCheckBiometrics();

      if (!canCheck || !enabled) {
        debugPrint('⚠️ Biometric not available or not enabled');
        return null;
      }

      // Authenticate with biometric
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to log in',
        biometricOnly: true,
      );

      if (!authenticated) return null;

      // Get saved credentials
      final password = await biometricService.getLoginPassword(effectiveUserId);

      if (phone.isEmpty || password == null) {
        debugPrint('⚠️ Missing credentials for biometric login');
        return null;
      }

      return await logIn({
        "phone": phone,
        "password": password,
      }, fromBiometric: true);
    } catch (e) {
      debugPrint("🔥 Exception during biometric login: $e");
      return null;
    }
  }

  // ---------------- REGISTER STEP ONE ----------------
  Future<ResponseModel> registerStepOne(body) async {
    try {


      // --- API CALL ---
      http.Response response =
      await _apiClient.postData(ApiConstant.REGISTER_STEP_ONE, body);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Success response: $jsonResponse");

        final responseModel =
        ResponseModel.fromJson(jsonResponse, response.statusCode);

        final box = Hive.box("authBox");
        await box.put("userId", responseModel.responseBody?.user?.id?.toString() ?? '');
        await box.put("fullname", responseModel.responseBody?.user?.fullname);
        await box.put("phone", responseModel.responseBody?.user?.phone);
        await box.put("pin", responseModel.responseBody?.user?.pin);

        return responseModel;
      }

      // Error
      print("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "Unknown error",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );

    } catch (e) {
      print('❌ Exception during register step 1: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // ---------------- REGISTER STEP TWO ----------------
  Future<ResponseModel> registerStepTwo(Map<String, dynamic> body) async {
    try {
      http.Response response =
      await _apiClient.postData(ApiConstant.REGISTER_STEP_TWO, body);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Success response: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};
        final userJson =
        Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson =
        Map<String, dynamic>.from(responseBody['wallet'] ?? {});
        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        final box = await Hive.openBox("authBox");
        await box.put("token", accessToken);
        await box.put("refreshToken", refreshToken);
        await box.put("userId", userJson['id']?.toString() ?? '');
        await box.put("fullname", userJson['fullname']);
        await box.put("phone", userJson['phone']);
        await box.put(
          "has_pin",
          userJson['pin'] != null && userJson['pin'].toString().isNotEmpty,
        );
        await box.put("balance", walletJson['balance']);

        // Generate and save FCM token after successful registration
        final fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('🔥 FCM TOKEN GENERATED: $fcmToken');
        await box.put('fcmToken', fcmToken);
        print('💾 FCM token saved to Hive');

        _apiClient.updateHeaders(accessToken);

        // Complete the auth flow (connect socket with tokens)
        final authFlowService = _ref.read(authFlowServiceProvider);
        await authFlowService.completeAuthFlow();

        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ?? 'OTP verified',
          responseSuccessful:
          jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
          responseBody: ResponseBody(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserResponse.fromJson(userJson),
            wallet: WalletResponse.fromJson(walletJson),
          ),
        );
      }

      print("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage:
        jsonResponse["responseMessage"] ?? "OTP failed",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('🔥 Exception during registerStepTwo: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // ---------------- REGISTER STEP THREE ----------------
  Future<ResponseModel> registerStepThree(body) async {
    try {
      http.Response response =
      await _apiClient.postData(ApiConstant.REGISTER_STEP_THREE, body);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Success response: $jsonResponse");

        final responseModel =
        ResponseModel.fromJson(jsonResponse, response.statusCode);

        final box = Hive.box("authBox");
        await box.put("userId", responseModel.responseBody?.user?.id?.toString() ?? '');
        await box.put("fullname", responseModel.responseBody?.user?.fullname);
        await box.put("has_pin", false);
        await box.put("picture", responseModel.responseBody?.user?.picture);
        await box.put("phone", responseModel.responseBody?.user?.phone);
        await box.put("pin", responseModel.responseBody?.user?.pin);
        await box.put("balance", responseModel.responseBody?.wallet?.balance ?? 0);

        final picture = box.get('picture', defaultValue: 'picture');
        print('User Picture✅ $picture');
        return responseModel;
      }

      print("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage:
        jsonResponse["responseMessage"] ?? "Registration failed",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('❌ Exception during register step 3: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }
// ---------------- FORGOT PASSWORD ----------------
  Future<ResponseModel> forgotPassword(Map<String, dynamic> body) async {
    debugPrint('📡 Sending forgot password request...');

    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.FORGET_PASSWORD,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Success response: $jsonResponse");

        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ?? 'OTP sent successfully',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
        );
      }

      debugPrint("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage:
        jsonResponse["responseMessage"] ?? "Failed to send OTP",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('🔥 Exception during forgot password: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // ---------------- RESET PASSWORD ----------------
  Future<ResponseModel> resetPassword(Map<String, dynamic> body) async {
    debugPrint('📡 Resetting password...');

    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.RESET_PASSWORD,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Success response: $jsonResponse");

        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ?? 'Password reset successfully',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
        );
      }

      debugPrint("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage:
        jsonResponse["responseMessage"] ?? "Failed to reset password",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('🔥 Exception during reset password: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }
  // ---------------- SET PIN ----------------
  // Future<ResponseModel> setPin(String pin, String confirmPin) async {
  //   try {
  //     http.Response response =
  //     await _apiClient.postData(ApiConstant.SET_PIN, {
  //       "pin": pin,
  //       "confirmPin": confirmPin,
  //     });
  //
  //     final jsonResponse = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final box = Hive.box("authBox");
  //       await box.put("has_pin", true);
  //       await box.put("saved_pin", pin);
  //
  //       return ResponseModel(
  //         responseMessage:
  //         jsonResponse["responseMessage"] ?? "PIN set successfully",
  //         responseSuccessful: true,
  //         statusCode: response.statusCode,
  //       );
  //     }
  //
  //     return ResponseModel(
  //       responseMessage:
  //       jsonResponse["responseMessage"] ?? "Failed to set PIN",
  //       responseSuccessful: false,
  //       statusCode: response.statusCode,
  //     );
  //   } catch (e) {
  //     return ResponseModel(
  //       responseMessage: "Something went wrong",
  //       responseSuccessful: false,
  //       statusCode: 500,
  //     );
  //   }
  // }
}