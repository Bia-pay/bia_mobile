import 'dart:convert';
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

  // 🔐 Normal login (manual or biometric)
  Future<ResponseModel> logIn(Map<String, dynamic> body,
      {bool fromBiometric = false}) async {
    print('📡 Attempting login...');

    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.LOGIN,
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print("✅ Success response: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};

        // 🟩 Extract user, wallet, tokens
        final userJson = Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson = Map<String, dynamic>.from(responseBody['wallet'] ?? {});
        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        // 🟩 Save everything to Hive
        final box = await Hive.openBox("authBox");
        await box.put("token", accessToken);
        await box.put("refreshToken", refreshToken);
        await box.put("fullname", userJson['fullname'] ?? '');
        await box.put("phone", userJson['phone'] ?? '');
        await box.put("balance", walletJson['balance'] ?? 0);
        await box.put("currency", walletJson['currency'] ?? 'NGN');
        await box.put("has_pin", false); // assume new user has no PIN
        await box.put('refreshToken', refreshToken);  // long-lived refresh token

        // If this is a manual login, store credentials for biometric login
        if (!fromBiometric && body.containsKey('password')) {
          await box.put("password", body['password']);
          await box.put("login_biometric_enabled", true);
          print("🔐 Credentials saved for biometric login.");
        }

        // 🟩 Update API headers for future requests
        _apiClient.updateHeaders(accessToken);


        print("🔐 Tokens & wallet info saved successfully");

        return ResponseModel(
          responseMessage: jsonResponse['responseMessage'] ?? 'Login successful',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
          responseBody: ResponseBody(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserResponse.fromJson(userJson),
            wallet: WalletResponse.fromJson(walletJson),
          ),
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        print("❌ Error response: $jsonResponse");

        final errorMessage = jsonResponse["responseMessage"] ?? "Login failed";

        return ResponseModel(
          responseMessage: errorMessage,
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('🔥 Exception during login: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // 🔓 Fingerprint-based login using saved credentials
  Future<ResponseModel?> biometricLogin() async {
    try {
      final box = await Hive.openBox('authBox');
      final canCheck = await _localAuth.canCheckBiometrics;
      final enabled = box.get('login_biometric_enabled', defaultValue: false);

      if (!canCheck || !enabled) {
        print("🚫 Biometric login not enabled or device not supported.");
        return null;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to log in securely',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!authenticated) {
        print("❌ Authentication failed or canceled by user.");
        return null;
      }

      // 🔍 Retrieve saved credentials
      final phone = box.get('phone');
      final password = box.get('password');

      if (phone == null || password == null) {
        print("⚠️ Missing saved credentials in Hive.");
        return null;
      }

      print("✅ Biometric authentication success. Logging in automatically...");

      final body = {
        "phone": phone,
        "password": password,
      };

      return await logIn(body, fromBiometric: true);
    } catch (e) {
      print("🔥 Exception during biometric login: $e");
      return null;
    }
  }

  // 🧾 Register Step 1
  Future<ResponseModel> registerStepOne(body) async {
    print('Got here in auth repo');
    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.REGISTER_STEP_ONE,
        body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("✅ Success response: $jsonResponse");

        final userResponse = ResponseModel.fromJson(jsonResponse, response.statusCode);

        final box = Hive.box("authBox");
        await box.put("accessToken", userResponse.responseBody?.accessToken);
        await box.put("fullname", userResponse.responseBody?.user?.fullname);
        await box.put("phone", userResponse.responseBody?.user?.phone);

        return ResponseModel(
          responseMessage: 'Login Successful',
          responseSuccessful: true,
          statusCode: response.statusCode,
          responseBody: userResponse.responseBody,
        );
      } else {
        var jsonResponse = jsonDecode(response.body);
        print("❌ Error response: $jsonResponse");

        String errorMessage =
            jsonResponse["responseMessage"] ?? "Unknown error occurred";

        return ResponseModel(
          responseMessage: errorMessage,
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Exception during sign in: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // 🧾 Register Step 2
  Future<ResponseModel> registerStepTwo(Map<String, dynamic> body) async {
    print('📡 Register Step Two - Verifying OTP...');
    try {
      final response = await _apiClient.postData(
        ApiConstant.REGISTER_STEP_TWO,
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print("✅ Success response: $jsonResponse");

        final responseBody = jsonResponse['responseBody'] ?? {};

        final userJson = Map<String, dynamic>.from(responseBody['user'] ?? {});
        final walletJson = Map<String, dynamic>.from(responseBody['wallet'] ?? {});
        final accessToken = responseBody['accessToken'] ?? '';
        final refreshToken = responseBody['refreshToken'] ?? '';

        final box = await Hive.openBox("authBox");
        await box.put("accessToken", accessToken);
        await box.put("refreshToken", refreshToken);
        await box.put("fullname", userJson['fullname'] ?? '');
        await box.put("phone", userJson['phone'] ?? '');
        await box.put("balance", walletJson['balance'] ?? 0);

        _apiClient.updateHeaders(accessToken);

        print("🔐 Tokens & user info saved successfully");

        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ?? 'OTP verified successfully',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
          responseBody: ResponseBody(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: UserResponse.fromJson(userJson),
            wallet: WalletResponse.fromJson(walletJson),
          ),
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        print("❌ Error response: $jsonResponse");

        final errorMessage =
            jsonResponse["responseMessage"] ?? "Failed to verify OTP";

        return ResponseModel(
          responseMessage: errorMessage,
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('🔥 Exception during registerStepTwo: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  // 🧾 Register Step 3
  Future<ResponseModel> registerStepThree(body) async {
    print('Got here in auth repo');
    try {
      http.Response response = await _apiClient.postData(
        ApiConstant.REGISTER_STEP_THREE,
        body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("✅ Success response: $jsonResponse");

        final userResponse = ResponseModel.fromJson(jsonResponse, response.statusCode);

        final box = Hive.box("authBox");
        await box.put("accessToken", userResponse.responseBody?.accessToken);
        await box.put("fullname", userResponse.responseBody?.user?.fullname);
        await box.put("has_pin", false); // assume new user has no PIN
        return ResponseModel(
          responseMessage: 'Registration Successful',
          responseSuccessful: true,
          statusCode: response.statusCode,
          responseBody: userResponse.responseBody,
        );
      } else {
        var jsonResponse = jsonDecode(response.body);
        print("❌ Error response: $jsonResponse");

        String errorMessage =
            jsonResponse["responseMessage"] ?? "Unknown error occurred";

        return ResponseModel(
          responseMessage: errorMessage,
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Exception during registration: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }
  Future<ResponseModel> setPin(String pin, String confirmPin) async {
    try {
      final body = {
        "pin": pin,
        "confirmPin": confirmPin,
      };

      http.Response response = await _apiClient.postData(
        ApiConstant.SET_PIN, // add this constant
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final box = Hive.box("authBox");
        await box.put("has_pin", true);
        await box.put("saved_pin", pin);

        return ResponseModel(
          responseMessage: jsonResponse["responseMessage"] ?? "PIN set successfully",
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
}