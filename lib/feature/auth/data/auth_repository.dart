import 'package:bia/core/network/api_client.dart';
import 'package:bia/core/network/endpoints.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  /// 1️⃣ Register Phone
  Future<Map<String, dynamic>> registerPhone(String phone) async {
    return await _client.post(
      Endpoints.registerPhone,
      body: {'phone': phone},
    );
  }

  /// 2️⃣ Resend OTP
  Future<Map<String, dynamic>> resendOtp(String phone) async {
    return await _client.post(
      Endpoints.resendOtp,
      body: {'phone': phone},
    );
  }

  /// 3️⃣ Complete Registration
  Future<Map<String, dynamic>> completeRegistration({
    required String fullname,
    required String email,
    required String password,
  }) async {
    return await _client.post(
      Endpoints.completeRegistration,
      body: {
        'fullname': fullname,
        'email': email,
        'password': password,
      },
    );
  }

  /// 4️⃣ Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    return await _client.post(
      Endpoints.forgotPassword,
      body: {'phone': phone},
    );
  }

  /// 5️⃣ Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String otp,
    required String phone,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    return await _client.post(
      Endpoints.resetPassword,
      body: {
        'otp': otp,
        'phone': phone,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  /// 6️⃣ Login
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    return await _client.post(
      Endpoints.login,
      body: {'phone': phone, 'password': password},
    );
  }
}