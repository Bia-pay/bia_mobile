// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:hive/hive.dart';
import 'package:bia/core/services/secure_storage_service.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../../../core/easy_loading_config.dart';
import '../../../core/local/transaction_cache.dart';
import '../interceptor/interceptor.dart';
import '../authrepo/repo.dart';
import '../modal/reponse/response_modal.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/dashboardcontroller/provider.dart';
import '../../dashboard/dashboardcontroller/qr_onboarding_provider.dart';
import '../../../app/socket/socket_provider.dart';
import '../../ai_chat/controller/ai_chat_controller.dart';

import '../../../core/utils/app_logger.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<bool>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository, ref);
    });

class AuthController extends StateNotifier<AsyncValue<bool>> {
  AuthRepository authRepository;
  Ref ref;
  bool isLoading = false;

  // Add this field to store the last response
  ResponseModel? _lastResponse;

  // Add this getter
  ResponseModel? get lastResponse => _lastResponse;

  AuthController(this.authRepository, this.ref) : super(const AsyncLoading());

  // Prevents duplicate simultaneous login calls (e.g. from both login.dart and welcome_back session lock)
  bool _loginInProgress = false;

  Future<bool> logIn(
      BuildContext context,
      String phone,
      String password,
      ) async {
    // Guard: If a login is already in progress (e.g. simultaneous calls from login.dart
    // and welcome_back session lock), silently ignore the duplicate.
    if (_loginInProgress) {
      debugPrint('⚠️ Login already in progress — ignoring duplicate call.');
      return false;
    }
    _loginInProgress = true;
    try {
    if (phone.isEmpty || password.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return false;
    }

    try {
      LoadingHelper.show('');

      Map<String, dynamic> body = {'phone': phone, 'password': password};

      final response = await authRepository.logIn(body);

      AppLogger.debug('Login response status: ${response.statusCode}');

      // Store the response
      _lastResponse = response;

      LoadingHelper.dismiss();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final appBox = await Hive.openBox('appBox');
        final isNew = appBox.get('is_new_registration', defaultValue: false);
        if (isNew) {
          await appBox.put('is_new_registration', false);
        } else {
          await appBox.put('qr_onboarding_completed', true);
          ref.read(qrOnboardingProvider.notifier).setOnboardingCompleted(true);
        }
        return true;
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
        return false;
      }
    } catch (e, stackTrace) {
      LoadingHelper.dismiss();
      debugPrint('🔥 AuthController.logIn Exception: $e');
      debugPrint('Stack trace: $stackTrace');
      // Clear last response on error
      _lastResponse = null;
      ToastHelper.showToast(
        context: context,
        message: '$e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return false;
    }
    } finally {
      _loginInProgress = false;
    }
  }
  Future<ResponseModel?> registerStepOne(
    BuildContext context,
    String phone,
  ) async {
    if (phone.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Phone number required",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
           LoadingHelper.show('');


      final body = {"phone": phone};
      final ResponseModel response = await authRepository.registerStepOne(body);

      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        EasyLoading.showToast(response.responseMessage);
        // ToastHelper.showToast(
        //   context: context,
        //   message: response.responseMessage,
        //   icon: Icons.check_circle,
        //   iconColor: Colors.green,
        //   position: ToastPosition.top,
        // );
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response; //  <--- important
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<void> logout({BuildContext? context, bool isManual = true}) async {
    try {
      EasyLoading.show(status: "Logging out...");

      // Hit the backend logout API if the user logs out themselves (manual)
      if (isManual) {
        try {
          await authRepository.logout();
        } catch (e) {
          debugPrint('⚠️ Error calling authRepository.logout(): $e');
        }
      }

      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');

      // Clear transaction cache and beneficiaries
      if (userId.isNotEmpty) {
        await TransactionCache.clearTransactions(userId);
        await clearRecentBeneficiaries(userId);
      }

      // Clear session keys in centralized secure storage (Requirement 8)
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.clearSession();

      if (isManual) {
        // Aggressively clear all SharedPreferences/Hive if manual logout
        await authBox.clear();
      } else {
        // Only remove tokens for session lock, keeping profile for "Welcome Back"
        await authBox.delete('token');
        await authBox.delete('refreshToken');
        await authBox.put('is_logged_in', false);
      }

      // Invalidate all global user state providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(userIdProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(socketNotifierProvider);
      ref.invalidate(aiChatControllerProvider);

      LoadingHelper.dismiss();

      final targetRoute = RouteList.loginScreen;

      if (context != null && context.mounted) {
        context.go(targetRoute);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged out successfully"),
            backgroundColor: successColor,
          ),
        );
      } else {
        // Fallback to global navigatorKey if context is unavailable
        navigatorKey.currentState?.context.go(targetRoute);
      }

    } catch (e) {
      LoadingHelper.dismiss();
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }


  Future<void> clearRecentBeneficiaries(String userId) async {
    final box = await Hive.openBox('recentBeneficiaries');
    await box.delete('beneficiaries_$userId');
    debugPrint('🗑️ Cleared beneficiaries for user $userId');
  }

  Future<ResponseModel?> registerStepTwo(
    BuildContext context,
    String otp,
    String phone,
  ) async {
    if (otp.isEmpty || phone.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Field is required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
           LoadingHelper.show('');


      Map<String, dynamic> body = {'otp': otp, 'phone': phone};

      // debugPrint("➡️ Sending verify OTP: $body");

      final ResponseModel response = await authRepository.registerStepTwo(body);

      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          position: ToastPosition.top,
        );
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response; //  IMPORTANT — return it to the UI
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<ResponseModel?> registerStepThree(
    BuildContext context,
    String fullname,
    String email,
    String password, {
    String? referralCode,
  }) async {
    if (email.isEmpty || fullname.isEmpty || password.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Field is required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
           LoadingHelper.show('');


      Map<String, dynamic> body = {
        'email': email,
        'fullname': fullname,
        'password': password,
      };

      if (referralCode != null && referralCode.isNotEmpty) {
        body['referralCode'] = referralCode;
      }

      // debugPrint(" Registering: $body");

      final ResponseModel response = await authRepository.registerStepThree(
        body,
      );

      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        final appBox = await Hive.openBox('appBox');
        await appBox.put('is_new_registration', true);

        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          position: ToastPosition.top,
        );
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ---------------- FORGOT PASSWORD ----------------
  Future<ResponseModel?> forgotPassword(
    BuildContext context,
    String phone,
  ) async {
    if (phone.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Phone number is required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
           LoadingHelper.show('');


      Map<String, dynamic> body = {'phone': phone};

      // debugPrint(" Sending forgot password OTP: $body");

      final ResponseModel response = await authRepository.forgotPassword(body);

      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          position: ToastPosition.top,
        );
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ---------------- RESEND OTP ----------------
  Future<ResponseModel?> resendOtp(
    BuildContext context,
    String phone,
  ) async {
    if (phone.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Phone number is required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      Map<String, dynamic> body = {'phone': phone};

      final ResponseModel response = await authRepository.resendOtp(body);

      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          position: ToastPosition.top,
        );
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ---------------- RESET PASSWORD ---------------
  Future<ResponseModel?> resetPassword(
    BuildContext context,
    String otp,
    String phone,
    String newPassword,
    String confirmNewPassword,
  ) async {
    if (otp.isEmpty ||
        phone.isEmpty ||
        newPassword.isEmpty ||
        confirmNewPassword.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    if (newPassword != confirmNewPassword) {
      ToastHelper.showToast(
        context: context,
        message: "Passwords do not match.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
           LoadingHelper.show('');


      Map<String, dynamic> body = {
        'otp': otp,
        'phone': phone,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
       };

      // debugPrint(" Resetting password: $body");

      final ResponseModel response = await authRepository.resetPassword(body);

      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          position: ToastPosition.top,
        );
      } else {
        ToastHelper.showToast(
          // ignore: use_build_context_synchronously
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ---------------- PRIVATE KEY CONTROLLER ---------------
  // Future<void> privateChatKeyController(
  //   BuildContext context,
  //   String keyLabel,
  // ) async {
  //   if (keyLabel.isEmpty) {
  //     debugPrint('All fields are required.');
  //     ToastHelper.showToast(
  //       context: context,
  //       message: "All fields are required.",
  //       icon: Icons.info,
  //       iconColor: errorColor,
  //       position: ToastPosition.top, // or ToastPosition.bottom
  //     );
  //     return;
  //   }

  //   try {
  //     EasyLoading.show(
  //       indicator: const CustomLoader(),
  //       maskType: EasyLoadingMaskType.black,
  //       dismissOnTap: false,
  //     );
  //     Map<String, dynamic> body = {'keyLabel': keyLabel};
  //     debugPrint(body);
  //     var response = await authRepository.signIn(body);
  //     LoadingHelper.dismiss();
  //     if (!mounted) return;

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       //  Display the response coming from responsebody
  //       debugPrint(response);
  //     } else {
  //       ToastHelper.showToast(
  //         context: context,
  //         message: response.responseMessage,
  //         icon: Icons.info,
  //         iconColor: errorColor,
  //         position: ToastPosition.top,
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error during sign-in: $e');
  //     LoadingHelper.dismiss();
  //     ToastHelper.showToast(
  //       context: context,
  //       message: '$e',
  //       icon: Icons.info,
  //       iconColor: errorColor,
  //       position: ToastPosition.top, // or ToastPosition.bottom
  //     );
  //   }
  // }
}
