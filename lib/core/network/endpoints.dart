import '../constants.dart';

class Endpoints {
  static const String baseUrl = AppConstants.baseUrl;

  // 🔐 AUTH
  static const String registerPhone = '$baseUrl/api/v1/auth/register';
  static const String resendOtp = '$baseUrl/api/v1/auth/resend/otp';
  static const String completeRegistration = '$baseUrl/api/v1/auth/complete/registration';
  static const String forgotPassword = '$baseUrl/api/v1/auth/forgot/password';
  static const String resetPassword = '$baseUrl/api/v1/auth/reset/password';
  static const String login = '$baseUrl/api/v1/auth/login';
}