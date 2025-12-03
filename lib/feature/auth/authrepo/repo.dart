import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../data/api_constant.dart';
import '../data/api_data.dart';
import '../modal/reponse/response_modal.dart';
import 'package:local_auth/local_auth.dart';

final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthRepository(this._apiClient);

  // ---------------- LOGIN ----------------
  Future<ResponseModel> logIn(
    Map<String, dynamic> body, {
    bool fromBiometric = false,
  }) async {
    debugPrint(' Attempting login...');

    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.LOGIN,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(" Success response: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};
        final userJson = Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson = Map<String, dynamic>.from(
          responseBody['wallet'] ?? {},
        );

        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        // ---------------- SAVE TOKENS CORRECTLY ----------------
        final box = await Hive.openBox("authBox");

        await box.put("token", accessToken);
        await box.put("refreshToken", refreshToken);

        // Save user details
        await box.put("fullname", userJson['fullname'] ?? '');
        await box.put("phone", userJson['phone'] ?? '');
        await box.put("balance", walletJson['balance'] ?? 0);
        await box.put("currency", walletJson['currency'] ?? 'NGN');
        await box.put("has_pin", false);

        // Save password only for biometric login
        if (!fromBiometric && body.containsKey('password')) {
          await box.put("password", body['password']);
          await box.put("login_biometric_enabled", true);
          debugPrint(" Credentials saved for biometric login.");
        }

        // Update API token
        _apiClient.updateHeaders(accessToken);

        debugPrint(" Login tokens saved successfully");

        return ResponseModel(
          responseMessage:
              jsonResponse['responseMessage'] ?? 'Login successful',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
          responseBody: ResponseBody(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserResponse.fromJson(userJson),
            wallet: WalletResponse.fromJson(walletJson),
          ),
        );
      }

      debugPrint(" Error response: $jsonResponse");
      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "Login failed",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint(' Exception during login: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
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
      final enabled = box.get('login_biometric_enabled', defaultValue: false);

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
      debugPrint(" Exception during biometric login: $e");
      return null;
    }
  }

  // ---------------- REGISTER STEP ONE ----------------
  Future<ResponseModel> registerStepOne(body) async {
    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.REGISTER_STEP_ONE,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint(" Success response: $jsonResponse");

        final responseModel = ResponseModel.fromJson(
          jsonResponse,
          response.statusCode,
        );

        final box = Hive.box("authBox");
        await box.put("fullname", responseModel.responseBody?.user?.fullname);
        await box.put("phone", responseModel.responseBody?.user?.phone);

        return responseModel;
      }

      debugPrint(" Error response: $jsonResponse");
      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "Unknown error",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint(' Exception during register step 1: $e');
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
      http.Response response = await _apiClient.postData(
        ApiConstant.REGISTER_STEP_TWO,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Success response: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};
        final userJson = Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson = Map<String, dynamic>.from(
          responseBody['wallet'] ?? {},
        );
        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        final box = await Hive.openBox("authBox");
        await box.put("token", accessToken);
        await box.put("refreshToken", refreshToken);
        await box.put("fullname", userJson['fullname']);
        await box.put("phone", userJson['phone']);
        await box.put("balance", walletJson['balance']);

        _apiClient.updateHeaders(accessToken);

        return ResponseModel(
          responseMessage: jsonResponse['responseMessage'] ?? 'OTP verified',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
          responseBody: ResponseBody(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserResponse.fromJson(userJson),
            wallet: WalletResponse.fromJson(walletJson),
          ),
        );
      }

      debugPrint("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "OTP failed",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('🔥 Exception during registerStepTwo: $e');
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
      http.Response response = await _apiClient.postData(
        ApiConstant.REGISTER_STEP_THREE,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Success response: $jsonResponse");

        final responseModel = ResponseModel.fromJson(
          jsonResponse,
          response.statusCode,
        );

        final box = Hive.box("authBox");
        await box.put("fullname", responseModel.responseBody?.user?.fullname);
        await box.put("has_pin", false);

        return responseModel;
      }

      debugPrint("❌ Error response: $jsonResponse");
      return ResponseModel(
        responseMessage:
            jsonResponse["responseMessage"] ?? "Registration failed",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Exception during register step 3: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // ---------------- SET PIN ----------------
  Future<ResponseModel> setPin(String pin, String confirmPin) async {
    try {
      http.Response response = await _apiClient.postData(ApiConstant.SET_PIN, {
        "pin": pin,
        "confirmPin": confirmPin,
      });

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final box = Hive.box("authBox");
        await box.put("has_pin", true);
        await box.put("saved_pin", pin);

        return ResponseModel(
          responseMessage:
              jsonResponse["responseMessage"] ?? "PIN set successfully",
          responseSuccessful: true,
          statusCode: response.statusCode,
        );
      }

      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "Failed to set PIN",
        responseSuccessful: false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong",
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
}
