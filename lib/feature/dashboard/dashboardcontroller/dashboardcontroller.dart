import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:hive/hive.dart';
import '../../../core/helper/helper.dart';
import '../../auth/modal/reponse/response_modal.dart' hide WalletResponse;
import '../../settings/model/qr_code.dart';
import '../dashboard_repo/repo.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../model/deposit.dart';
import '../model/recent_transaction.dart';
import '../model/recent_transfer.dart';
import '../model/verify_transactions.dart';

final dashboardControllerProvider =
StateNotifierProvider<DashboardController, AsyncValue<ResponseBody?>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});

class DashboardController extends StateNotifier<AsyncValue<ResponseBody?>> {
  final DashboardRepository dashboardRepository;

  DashboardController(this.dashboardRepository) : super(const AsyncLoading());


  Future<ResponseModel?> sendMoney(BuildContext context,String account,String amount,String narration,String pin,{required bool save}) async {

    if (account.isEmpty || amount.isEmpty || narration.isEmpty || pin.isEmpty ) {
      // Note: 'save' is a bool, so it cannot be empty, no need to check it here.
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      // Show loading indicator
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      Map<String, dynamic> body = {
        'account': account.trim(),
        'amount': num.tryParse(amount) ?? 0,
        'narration': narration.trim(),
        'pin': pin.trim(),
        // ⚠️ THE FIX: Convert the boolean 'save' to a string 'true' or 'false'
        'save': save.toString(),
      };

      debugPrint("➡️ Sending funds: $body");

      // Call repository (assuming dashboardRepository is defined)
      final ResponseModel response = await dashboardRepository.sendMoney(body);

      EasyLoading.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: response.responseSuccessful ? Colors.green : Colors.red,
        position: ToastPosition.top,
      );
      return response;

    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }
  // ✅ SET PIN
  Future<ResponseModel?> setPin(BuildContext context,String pin,String confirmPin,) async {
    if (pin.isEmpty || confirmPin.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Both fields are required.",
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
      Map<String, dynamic> body = {'pin': pin, 'confirmPin': confirmPin};
      debugPrint("➡️ Setting PIN: $body");

      final ResponseModel response = await dashboardRepository.setPin(body);
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: response.responseSuccessful ? Colors.green : Colors.red,
        position: ToastPosition.top,
      );
      return response;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  // ✅ VERIFY ACCOUNT (Before Transfer)
  Future<ResponseModel?> verifyAccount(BuildContext context, String account) async {
    if (account.isEmpty || account.length != 10) {
      ToastHelper.showToast(
        context: context,
        message: "Enter a valid 10-digit account number",
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
      final Map<String, dynamic> body = {"account": account.trim()};
      debugPrint("➡️ Verifying account: $body");
      final ResponseModel response = await dashboardRepository.verifyAccount(body);

      EasyLoading.dismiss();
      return response;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<QrCodeResponse?> getUserQrCode(BuildContext context) async {
    try {
      EasyLoading.show(
        indicator: const CustomLoader(),
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      final qrResponse = await dashboardRepository.getUserQrCode();
      EasyLoading.dismiss();

      ToastHelper.showToast(
        context: context,
        message: qrResponse.responseMessage,
        icon: qrResponse.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: qrResponse.responseSuccessful ? Colors.green : Colors.red,
        position: ToastPosition.top,
      );

      return qrResponse;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<List<TransactionItem>> getRecentTransactions(BuildContext context) async {
    try {
      final response = await dashboardRepository.getRecentTransactions();

      if (response.responseSuccessful) {
        return response.transactions;
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.error,
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
        return [];
      }
    } catch (e) {
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return [];
    }
  }

  Future<List<RecentBeneficiaryItem>> getRecentBeneficiary(BuildContext context) async {
    try {
      final box = await Hive.openBox('recentBeneficiaries');
      final tokenBox = await Hive.openBox('authBox');
      final token = tokenBox.get('token', defaultValue: '');

      // Load saved beneficiaries for this user first
      final savedData = box.get(token, defaultValue: []);
      if (savedData.isNotEmpty) {
        final savedBeneficiaries = (savedData as List)
            .map((e) => RecentBeneficiaryItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Return saved list immediately
        Future.delayed(Duration.zero, () async {
          // Load fresh list in the background
          final freshList = await _fetchAndSaveRecentBeneficiaries(box, token);
          debugPrint("🔄 Updated recentBeneficiaries for user $token: ${freshList.length}");
        });

        return savedBeneficiaries;
      } else {
        // No saved data, fetch fresh immediately
        return await _fetchAndSaveRecentBeneficiaries(box, token);
      }
    } catch (e) {
      debugPrint("❌ Error getting recent beneficiaries: $e");
      return [];
    }
  }

// Helper method to fetch from API and save
  Future<List<RecentBeneficiaryItem>> _fetchAndSaveRecentBeneficiaries(Box box, String token) async {
    try {
      final response = await dashboardRepository.getRecentBeneficiary();

      if (response.responseSuccessful && response.beneficiaries.isNotEmpty) {
        // Save to Hive
        final jsonList = response.beneficiaries.map((e) => e.toJson()).toList();
        await box.put(token, jsonList);
        return response.beneficiaries;
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching recent beneficiaries from API: $e");
      return [];
    }
  }

  Future<void> loadWalletBalance() async {
    // Load saved balance immediately from Hive first
    final box = Hive.box('authBox');
    final savedBalance = box.get('balance', defaultValue: '0');
    final savedCurrency = box.get('currency', defaultValue: 'NGN');
    final savedTier = box.get('tier', defaultValue: 'BASIC');
    final savedLimits = Map<String, dynamic>.from(box.get('limits', defaultValue: {}));

    state = AsyncValue.data(WalletResponse(
      balance: savedBalance.toString(),
      currency: savedCurrency,
      limits: savedLimits,
    ));

    // Fetch fresh balance in the background
    try {
      final freshBalance = await dashboardRepository.getWalletBalance();
      if (freshBalance != null) {
        state = AsyncValue.data(refreshWalletBalance
        as ResponseBody?);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshWalletBalance() async {
    state = const AsyncLoading();
    await loadWalletBalance();
  }

// In your DashboardController
  Future<UserResponse?> fetchUserProfile(BuildContext context) async {
    try {
      // Call repository
      final user =  await dashboardRepository.getUserProfile();

      EasyLoading.dismiss();
      return user;
    } catch (e) {
      EasyLoading.dismiss();
      return null;
    }
  }
  // ✅ Deposit Money
  Future<DepositResponseModel?> depositMoney(BuildContext context, double amount) async {
    if (amount <= 0) {
      ToastHelper.showToast(
        context: context,
        message: "Enter a valid amount",
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

      final response = await dashboardRepository.depositMoney({"amount": amount});
      EasyLoading.dismiss();

      if (response.responseSuccessful && response.data != null) {
        print(response.data);
        return response;
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.error,
          iconColor: Colors.red,
          position: ToastPosition.top,
        );
        return null;
      }
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Deposit failed: $e",
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<VerifyTransactionResponse?> verifyDeposit(BuildContext context, String reference) async {

    final result =  await dashboardRepository.verifyPayment(reference);
   // final result = await repo.verifyPayment(reference);

    if (result != null && result.responseSuccessful) {
      print("💰 Payment Verified Successfully!");
      return result;
    } else {
      print("❌ Payment Verification Failed");
      return null;
    }
  }

  Future<ResponseModel?> changePin(BuildContext context,String oldPin,String newPin,String confirmNewPin, ) async {

    if (oldPin.isEmpty || newPin.isEmpty || confirmNewPin.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }

    if (newPin != confirmNewPin) {
      ToastHelper.showToast(
        context: context,
        message: "New PIN and Confirm PIN do not match.",
        icon: Icons.error,
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
      final body = {
        "currentPin": oldPin,
        "newPin": newPin,
        "confirmNewPin": confirmNewPin,
      };
      debugPrint("➡️ Updating PIN: $body");
      final response = await dashboardRepository.changePin(body);
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: response.responseSuccessful ? Colors.green : Colors.red,
        position: ToastPosition.top,
      );
      return response;
    } catch (e) {
      EasyLoading.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: Colors.red,
        position: ToastPosition.top,
      );
      return null;
    }
  }
}