import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/modal/reponse/response_modal.dart';
import '../../dashboard/dashboard_repo/repo.dart';
import '../../../app/utils/widgets/toast_helper.dart';

final qrPaymentControllerProvider = StateNotifierProvider.autoDispose<QrPaymentController, AsyncValue<void>>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return QrPaymentController(repo);
});

class QrPaymentController extends StateNotifier<AsyncValue<void>> {
  final DashboardRepository repository;

  QrPaymentController(this.repository) : super(const AsyncData(null));

  Future<ResponseModel?> initiateQrPayment({
    required BuildContext context,
    required String receiverAccount,
    required double amount,
    String? narration,
  }) async {
    state = const AsyncLoading();
    final response = await repository.initiateQrPayment(
      receiverAccount: receiverAccount,
      amount: amount,
      narration: narration,
    );

    state = const AsyncData(null);

    if (!response.responseSuccessful && context.mounted) {
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
      );
      return null;
    }
    return response;
  }

  Future<bool> authorizeQrPayment({
    required BuildContext context,
    required String requestId,
    required String pin,
  }) async {
    state = const AsyncLoading();
    final response = await repository.authorizeQrPayment(
      requestId: requestId,
      pin: pin,
    );

    state = const AsyncData(null);

    if (response.responseSuccessful) {
      return true;
    } else {
      if (context.mounted) {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
        );
      }
      return false;
    }
  }

  Future<ResponseModel?> payQrPayment({
    required BuildContext context,
    required String requestId,
    required String pin,
  }) async {
    state = const AsyncLoading();
    final response = await repository.payQrPayment(
      requestId: requestId,
      pin: pin,
    );

    state = const AsyncData(null);

    if (!response.responseSuccessful && context.mounted) {
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
      );
      return null;
    }
    return response;
  }

  Future<ResponseModel?> deductQrPayment({
    required BuildContext context,
    required String ownerAccount,
    required double amount,
    required String narration,
    required String pin,
  }) async {
    state = const AsyncLoading();
    final response = await repository.deductQrPayment(
      ownerAccount: ownerAccount,
      amount: amount,
      narration: narration,
      pin: pin,
    );

    state = const AsyncData(null);

    if (!response.responseSuccessful && context.mounted) {
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
      );
      return null;
    }
    return response;
  }
}
