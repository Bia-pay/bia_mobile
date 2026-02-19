import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../../core/local/transaction_cache.dart';
import '../../../core/services/auth_flow_service.dart';
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
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Ref _ref;

  AuthRepository(this._apiClient, this._ref);

// ---------------- LOGOUT ----------------
  Future<ResponseModel> logout() async {
    try {
      final box = await Hive.openBox('authBox');
      final userId = box.get('userId', defaultValue: '');
      final biometricEnabled =
      box.get('login_biometric_enabled', defaultValue: false);

      // 🔹 Call backend logout
      try {
        await _apiClient.deleteData(ApiConstant.LOGOUT);
      } catch (_) {
        // Continue even if backend fails
      }

      // 🔹 Stop token refresh timer
      _apiClient.dispose();

      // 🔹 Clear user-specific cache
      if (userId.isNotEmpty) {
        await TransactionCache.clearTransactions(userId);
        final recentBox = await Hive.openBox('recentBeneficiaries');
        await recentBox.delete('beneficiaries_$userId');
      }

      // 🔹 Clear saved profile
      await box.delete('saved_user_profile');

      // 🔹 Clear Hive storage
      if (biometricEnabled) {
        await box.delete('token');
        await box.delete('refreshToken');
      } else {
        await box.clear();
      }

      return ResponseModel(
        responseMessage: "Logged out successfully",
        responseSuccessful: true,
        statusCode: 200,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Logout failed",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> logIn(Map<String, dynamic> body, {bool fromBiometric = false}) async {
    print('📡 Attempting login...');

    try {


      print("📤 Final body sent to backend: $body");

      // --- Continue with your original code ---
      final response = await _apiClient.postData(ApiConstant.LOGIN, body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Login Success: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};
        final userJson = Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson = Map<String, dynamic>.from(responseBody['wallet'] ?? {});
        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        final box = await Hive.openBox('authBox');
        await box.put("token", accessToken);
        await box.put("refreshToken", refreshToken);
        await box.put("userId", userJson['id']?.toString() ?? '');
        await box.put("fullname", userJson['fullname'] ?? '');
        await box.put("phone", userJson['phone'] ?? '');
        await box.put("balance", walletJson['balance'] ?? 0);
        await box.put("currency", walletJson['currency'] ?? 'NGN');
        await box.put(
          "has_pin",
          userJson['pin'] != null && userJson['pin'].toString().isNotEmpty,
        );
        await box.put("picture", userJson['picture']);
        if (!fromBiometric && body.containsKey('password')) {
          await box.put("password", body['password']);
          await box.put("login_biometric_enabled", true);
        }
        final picture = userJson['picture'];
        final fcmToken = await FirebaseMessaging.instance.getToken();

        debugPrint('🔥 RAW FCM TOKEN FROM FIREBASE: $fcmToken');
        final authBox = await Hive.openBox('authBox');
        await authBox.put('fcmToken', fcmToken);

        print('💾 FCM token saved to Hive');
        if (picture is String) {
          await box.put('picture', picture);
        } else {
          await box.delete('picture');
        }
        print('User Picture✅ $picture');
        _apiClient.updateHeaders(accessToken);

        // Complete the auth flow (connect socket with tokens)
        final authFlowService = _ref.read(authFlowServiceProvider);
        await authFlowService.completeAuthFlow();

        return ResponseModel(
          responseMessage: jsonResponse['responseMessage'] ?? 'Login successful',
          responseSuccessful: true,
          statusCode: response.statusCode,
          responseBody: ResponseBody(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserResponse.fromJson(userJson),
            wallet: WalletResponse.fromJson(walletJson),
          ),
        );
      }

      print("❌ Login Failed: $jsonResponse");
      return ResponseModel(
        responseMessage: jsonResponse['responseMessage'] ?? 'Login failed',
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
  }
  /// ---------------- SET PIN ----------------
  Future<ResponseModel> setPin(String pin, String confirmPin) async {
    try {
      final body = {'pin': pin, 'confirmPin': confirmPin};
      final response = await _apiClient.postData(ApiConstant.SET_PIN, body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ PIN set successfully: $jsonResponse");
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
  // ---------------- BIOMETRIC LOGIN ----------------
  Future<ResponseModel?> biometricLogin() async {
    try {
      final box = await Hive.openBox('authBox');
      final canCheck = await _localAuth.canCheckBiometrics;
      final enabled =
      box.get('login_biometric_enabled', defaultValue: false);

      if (!canCheck || !enabled) return null;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return null;

      final phone = box.get('phone');
      final password = box.get('password');

      if (phone == null || password == null) return null;

      return await logIn({
        "phone": phone,
        "password": password,
      }, fromBiometric: true);
    } catch (e) {
      print("🔥 Exception during biometric login: $e");
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