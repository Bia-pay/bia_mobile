import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

// Phone Registration
final registerPhoneProvider = FutureProvider.family((ref, String phone) async {
  final repo = ref.read(authRepositoryProvider);
  return await repo.registerPhone(phone);
});

// Resend OTP
final resendOtpProvider = FutureProvider.family((ref, String phone) async {
  final repo = ref.read(authRepositoryProvider);
  return await repo.resendOtp(phone);
});

// Complete Registration
final completeRegistrationProvider = FutureProvider.family(
      (ref, Map<String, String> userData) async {
    final repo = ref.read(authRepositoryProvider);
    return await repo.completeRegistration(
      fullname: userData['fullname']!,
      email: userData['email']!,
      password: userData['password']!,
    );
  },
);

// Forgot Password
final forgotPasswordProvider = FutureProvider.family((ref, String phone) async {
  final repo = ref.read(authRepositoryProvider);
  return await repo.forgotPassword(phone);
});

// Reset Password
final resetPasswordProvider = FutureProvider.family(
      (ref, Map<String, String> data) async {
    final repo = ref.read(authRepositoryProvider);
    return await repo.resetPassword(
      otp: data['otp']!,
      phone: data['phone']!,
      newPassword: data['newPassword']!,
      confirmNewPassword: data['confirmNewPassword']!,
    );
  },
);

// Login
final loginProvider = FutureProvider.family(
      (ref, Map<String, String> credentials) async {
    final repo = ref.read(authRepositoryProvider);
    return await repo.login(
      phone: credentials['phone']!,
      password: credentials['password']!,
    );
  },
);