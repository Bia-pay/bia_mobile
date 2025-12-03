// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../authrepo/repo.dart';
import '../modal/reponse/response_modal.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<bool>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository);
    });

class AuthController extends StateNotifier<AsyncValue<bool>> {
  AuthRepository authRepository;
  bool isLoading = false;
  // bool get loading => _isLoading;
  AuthController(this.authRepository) : super(const AsyncLoading());

  Future<bool> logIn(
    BuildContext context,
    String phone,
    String password,
  ) async {
    if (phone.isEmpty || password.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return false;
    }

    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      Map<String, dynamic> body = {'phone': phone, 'password': password};

      final response = await authRepository.logIn(body);
      EasyLoading.dismiss();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.info,
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
        return false;
      }
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: '$e',
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return false;
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
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      final body = {"phone": phone};
      final ResponseModel response = await authRepository.registerStepOne(body);

      EasyLoading.dismiss();

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
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
      }

      return response; //  <--- important
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ignore: unused_element
  Future<void> _logout(BuildContext context) async {
    try {
      EasyLoading.show(status: "Logging out...");

      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('token', defaultValue: '');
      final biometricEnabled = authBox.get(
        'login_biometric_enabled',
        defaultValue: false,
      );

      // Clear this user's saved beneficiaries
      await clearRecentBeneficiaries(token);

      if (biometricEnabled) {
        await authBox.delete('token');
        await authBox.delete('refreshToken');
      } else {
        await authBox.clear();
      }

      EasyLoading.dismiss();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        biometricEnabled ? RouteList.welcomeBackScreen : RouteList.loginScreen,
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> clearRecentBeneficiaries(String token) async {
    final box = await Hive.openBox('recentBeneficiaries');
    await box.delete(token);
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
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      Map<String, dynamic> body = {'otp': otp, 'phone': phone};

      debugPrint("➡️ Sending verify OTP: $body");

      final ResponseModel response = await authRepository.registerStepTwo(body);

      EasyLoading.dismiss();

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
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
      }

      return response; //  IMPORTANT — return it to the UI
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<ResponseModel?> registerStepThree(
    BuildContext context,
    String fullname,
    String email,
    String password,
  ) async {
    if (email.isEmpty || fullname.isEmpty || password.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Field is required.",
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      Map<String, dynamic> body = {
        'email': email,
        'fullname': fullname,
        'password': password,
      };

      debugPrint(" Registering: $body");

      final ResponseModel response = await authRepository.registerStepThree(
        body,
      );

      EasyLoading.dismiss();

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
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: Colors.red,
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
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      Map<String, dynamic> body = {'phone': phone};

      debugPrint(" Sending forgot password OTP: $body");

      final ResponseModel response = await authRepository.forgotPassword(body);

      EasyLoading.dismiss();

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
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ---------------- RESET PASSWORD ----------------
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
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    if (newPassword != confirmNewPassword) {
      ToastHelper.showToast(
        context: context,
        message: "Passwords do not match.",
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      Map<String, dynamic> body = {
        'otp': otp,
        'phone': phone,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      };

      debugPrint(" Resetting password: $body");

      final ResponseModel response = await authRepository.resetPassword(body);

      EasyLoading.dismiss();

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
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
      }

      return response;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.info,
        iconColor: Colors.red,
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
  //       iconColor: Colors.red,
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
  //     EasyLoading.dismiss();
  //     if (!mounted) return;

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       //  Display the response coming from responsebody
  //       debugPrint(response);
  //     } else {
  //       ToastHelper.showToast(
  //         context: context,
  //         message: response.responseMessage,
  //         icon: Icons.info,
  //         iconColor: Colors.red,
  //         position: ToastPosition.top,
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error during sign-in: $e');
  //     EasyLoading.dismiss();
  //     ToastHelper.showToast(
  //       context: context,
  //       message: '$e',
  //       icon: Icons.info,
  //       iconColor: Colors.red,
  //       position: ToastPosition.top, // or ToastPosition.bottom
  //     );
  //   }
  // }
}
