import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/colors.dart';
import '../../../core/easy_loading_config.dart';
import '../../../core/helper/helper.dart' hide WalletResponse;
import '../../auth/modal/reponse/response_modal.dart';
import '../../auth/modal/verify_bank.dart';
import '../../settings/model/qr_code.dart';
import '../dashboard_repo/repo.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../model/bank_model.dart';
import '../model/data_model.dart';
import '../model/deposit.dart';
import '../model/favourite_beneficiary.dart';
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
  Box? _authBox;
  Box? _recentBeneficiariesBox;

  DashboardController(this.dashboardRepository) : super(const AsyncData(null)) {
    // Initial state setup from Hive
    _initWalletState();
  }

  Future<Box> _getAuthBox() async {
    if (_authBox == null || !_authBox!.isOpen) {
      _authBox = await Hive.openBox("authBox");
    }
    return _authBox!;
  }

  Future<Box> _getRecentBeneficiariesBox() async {
    if (_recentBeneficiariesBox == null || !_recentBeneficiariesBox!.isOpen) {
      _recentBeneficiariesBox = await Hive.openBox("recentBeneficiaries");
    }
    return _recentBeneficiariesBox!;
  }

  void _initWalletState() {
    final box = Hive.box('authBox');
    final savedBalance = box.get('balance', defaultValue: '0');
    final savedCurrency = box.get('currency', defaultValue: 'NGN');
    final savedLimits = Map<String, dynamic>.from(box.get('limits', defaultValue: {}));

    state = AsyncValue.data(ResponseBody(
      wallet: WalletResponse(
        balance: savedBalance.toString(),
        currency: savedCurrency,
        limits: savedLimits,
      ),
    ));
    
    // 🔥 NO automatic loadWalletBalance() networking here.
    // Fresh data only comes through manual pull-to-refresh or explicit actions.
  }


  Future<ResponseModel?> sendMoney(BuildContext context,String account,String amount,String narration,String pin,{required bool save}) async {

    if (account.isEmpty || amount.isEmpty || narration.isEmpty || pin.isEmpty ) {
      // Note: 'save' is a bool, so it cannot be empty, no need to check it here.
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      // Show loading indicator
      LoadingHelper.show('');

      Map<String, dynamic> body = {
        'account': account.trim(),
        'amount': num.tryParse(amount) ?? 0,
        'narration': narration.trim(),
        'pin': pin.trim(),
        // ⚠️ THE FIX: Convert the boolean 'save' to a string 'true' or 'false'
        'save': save.toString(),
      };

      // debugPrint("➡️ Sending funds: $body");

      // Call repository (assuming dashboardRepository is defined)
      final ResponseModel response = await dashboardRepository.sendMoney(body);

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );
      return response;

    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.error,
        iconColor: errorColor,
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
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');
      Map<String, dynamic> body = {'pin': pin, 'confirmPin': confirmPin};
      // debugPrint("➡️ Setting PIN: $body");

      final ResponseModel response = await dashboardRepository.setPin(body);
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );
      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: 'Error: $e',
        icon: Icons.error,
        iconColor: errorColor,
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
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');
      final Map<String, dynamic> body = {"account": account.trim()};
      // debugPrint("➡️ Verifying account: $body");
      final ResponseModel response = await dashboardRepository.verifyAccount(body);

      LoadingHelper.dismiss();
      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<QrCodeResponse?> getUserQrCode(BuildContext context, {double? amount, String? narration}) async {
    try {
      LoadingHelper.show('');

      final qrResponse = await dashboardRepository.getUserQrCode(amount: amount, narration: narration);
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: qrResponse.responseMessage,
        icon: qrResponse.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: qrResponse.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return qrResponse;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
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
          iconColor: errorColor,
          position: ToastPosition.top,
        );
        return [];
      }
    } catch (e) {
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return [];
    }
  }


  Future<List<RecentBeneficiaryItem>> getRecentBeneficiary(BuildContext context) async {
    try {
      final box = await _getRecentBeneficiariesBox();
      final authBox = await _getAuthBox();
      final userId = authBox.get('userId', defaultValue: '');

      if (userId.isEmpty) {
        debugPrint("⚠️ No userId found, cannot load beneficiaries");
        return [];
      }

      // Load saved beneficiaries for this user first
      final savedData = box.get('beneficiaries_$userId', defaultValue: []);
      if (savedData.isNotEmpty) {
        final savedBeneficiaries = (savedData as List)
            .map((e) => RecentBeneficiaryItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Return saved list immediately
        Future.delayed(Duration.zero, () async {
          // Load fresh list in the background
          final freshList = await _fetchAndSaveRecentBeneficiaries(box, userId);
          debugPrint("🔄 Updated recentBeneficiaries for user $userId: ${freshList.length}");
        });

        return savedBeneficiaries;
      } else {
        // No saved data, fetch fresh immediately
        return await _fetchAndSaveRecentBeneficiaries(box, userId);
      }
    } catch (e) {
      debugPrint("❌ Error getting recent beneficiaries: $e");
      return [];
    }
  }

  Future<List<FavouriteBeneficiaryItem>> getFavouriteBeneficiary(
      BuildContext context) async {
    try {
      final response =
      await dashboardRepository.getFavouriteBeneficiary();

      if (response.responseSuccessful) {
        return response.beneficiaries;
      }

      return [];
    } catch (e) {
      debugPrint("❌ Error fetching favourites: $e");
      return [];
    }
  }

// Helper method to fetch from API and save
  Future<List<RecentBeneficiaryItem>> _fetchAndSaveRecentBeneficiaries(Box box, String userId) async {
    try {
      final response = await dashboardRepository.getRecentBeneficiary();

      if (response.responseSuccessful && response.beneficiaries.isNotEmpty) {
        // Save to Hive with userId key
        final jsonList = response.beneficiaries.map((e) => e.toJson()).toList();
        await box.put('beneficiaries_$userId', jsonList);
        debugPrint("💾 Saved ${response.beneficiaries.length} beneficiaries for user $userId");
        return response.beneficiaries;
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching recent beneficiaries from API: $e");
      return [];
    }
  }
// Helper method to fetch from API and save
//

  Future<void> loadWalletBalance() async {
    // Load saved balance immediately from Hive first
    final box = Hive.box('authBox');
    final savedBalance = box.get('balance', defaultValue: '0');
    final savedCurrency = box.get('currency', defaultValue: 'NGN');
    final savedLimits = Map<String, dynamic>.from(box.get('limits', defaultValue: {}));

    state = AsyncValue.data(ResponseBody(
      wallet: WalletResponse(
        balance: savedBalance.toString(),
        currency: savedCurrency,
        limits: savedLimits,
      ),
    ));

    // Fetch fresh balance in the background
    try {
      final freshBalance = await dashboardRepository.getWalletBalance();
      if (freshBalance != null) {
        state = AsyncValue.data(ResponseBody(
          wallet: freshBalance,
        ));
      }
    } catch (e, st) {
      debugPrint('❌ Error loading wallet balance: $e');
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

      LoadingHelper.dismiss();
      return user;
    } catch (e) {
      LoadingHelper.dismiss();
      return null;
    }
  }

  Future<ResponseModel?> updateUserProfile(
    BuildContext context,
    String fullname,
  ) async {
    if (fullname.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Full name is required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');
      final body = {"fullname": fullname};
      final response = await dashboardRepository.updateUserProfile(body);
      LoadingHelper.dismiss();

      if (response.responseSuccessful) {
        // Refresh local user profile to sync Hive and State
        await fetchUserProfile(context);

        ToastHelper.showToast(
          context: context,
          message: "Profile updated successfully",
          icon: Icons.check_circle,
          iconColor: successColor,
          position: ToastPosition.top,
        );
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.error,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }
      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error updating profile: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
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
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response = await dashboardRepository.depositMoney({
        "amount": amount.toInt().toString(),
      });      LoadingHelper.dismiss();

      if (response.responseSuccessful && response.data != null) {
        print(response.data);
        return response;
      } else {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.error,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
        return null;
      }
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Deposit failed: $e",
        icon: Icons.error,
        iconColor: errorColor,
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
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    if (newPin != confirmNewPin) {
      ToastHelper.showToast(
        context: context,
        message: "New PIN and Confirm PIN do not match.",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');
      final body = {
        "currentPin": oldPin,
        "newPin": newPin,
        "confirmNewPin": confirmNewPin,
      };
      // debugPrint("➡️ Updating PIN: $body");
      final response = await dashboardRepository.changePin(body);
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful ? Icons.check_circle : Icons.error,
        iconColor: response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );
      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<ResponseModel?> uploadProfileImage(
      BuildContext context,
      String imagePath,
      ) async {
    try {
      LoadingHelper.show('');

      final response =
      await dashboardRepository.uploadProfileImage(imagePath);

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Upload failed: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }


  List<BankModel> _cachedBanks = [];

  Future<List<BankModel>> getBanks(BuildContext context) async {
    try {
      // Return cached banks if available
      if (_cachedBanks.isNotEmpty) return _cachedBanks;

      final banks = await dashboardRepository.getBanks();
      _cachedBanks = banks;
      return banks;
    } catch (e) {
      ToastHelper.showToast(
        context: context,
        message: "Error loading banks: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return [];
    }
  }

  // Verify Bank Account
// ✅ VERIFY BANK ACCOUNT (Before Transfer) - UPDATED
  Future<BankAccountVerifyResponse?> verifyBankAccount(
      BuildContext context, {
        required String accountNumber,
        required String bankCode,
        required String bankName, // ✅ ADDED
      }) async {
    if (accountNumber.isEmpty || accountNumber.length != 10) {
      ToastHelper.showToast(
        context: context,
        message: "Enter a valid 10-digit account number",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    if (bankCode.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Please select a bank",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response = await dashboardRepository.verifyBankAccount(
        accountNumber: accountNumber,
        bankCode: bankCode,
        bankName: bankName, // ✅ ADDED
      );

      LoadingHelper.dismiss();
      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }

  Future<BankTransferResponse?> sendMoneyToBank(
      BuildContext context, {
        required String accountNumber,
        required String bankCode,
        required String bankName, // ✅ ADD
        required String amount,
        required String narration,
        required String pin,
        required bool saveBeneficiary,
      }) async {
    if (accountNumber.isEmpty ||
        bankCode.isEmpty ||
        amount.isEmpty ||
        narration.isEmpty ||
        pin.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response = await dashboardRepository.sendMoneyToBank(
        accountNumber: accountNumber,
        bankCode: bankCode,
        bankName: bankName, // ✅ ADD
        amount: amount,
        narration: narration,
        pin: pin,
        saveBeneficiary: saveBeneficiary,
      );

      LoadingHelper.dismiss();

      if (response.responseSuccessful &&
          response.responseBody != null) {

        final paymentRef = response.responseBody!.txnRef;

        print("🧾 Payment Reference: $paymentRef");

        await verifyBankTransfer(context, paymentRef);
      }

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return response;
    } catch (e) {
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }
  Future<Map<String, dynamic>?> getTransactionCharges(
      BuildContext context, {
        required double amount,
        String transactionType = "DEBIT",
        String serviceType = "TRANSFER",
      }) async {
    try {
      final charges = await dashboardRepository.getTransactionCharges(
        amount: amount,
        transactionType: transactionType,
        serviceType: serviceType,
      );

      return charges;
    } catch (e) {
      debugPrint("❌ Error fetching charges: $e");
      return null;
    }
  }

  Future<ResponseModel?> verifyBankTransfer(
      BuildContext context,
      String reference,
      ) async {

    if (reference.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Invalid transaction reference",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response =
      await dashboardRepository.verifyBankTransfer(reference);

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return response;

    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "Verification failed: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> getRecentBankTransfers(
      BuildContext context) async {
    return await dashboardRepository.getRecentBankTransfers();
  }

  Future<List<Map<String, dynamic>>> getBankBeneficiaries(
      BuildContext context) async {
    return await dashboardRepository.getBankBeneficiaries();
  }
  Future<ResponseModel?> forgotPaymentPin(BuildContext context) async {
    try {
      LoadingHelper.show('');

      final response =
      await dashboardRepository.forgotPaymentPin();

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return response;
    } catch (e) {
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }
  Future<ResponseModel?> verifyForgotPin(
      BuildContext context,
      String otp,
      ) async {
    if (otp.isEmpty || otp.length != 6) {
      ToastHelper.showToast(
        context: context,
        message: "Enter a valid 6-digit OTP",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response =
      await dashboardRepository.verifyForgotPin(otp);

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return response;
    } catch (e) {
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }

  Future<ResponseModel?> resetForgotPin(
      BuildContext context,
      String newPin,
      String confirmNewPin,
      ) async {
    if (newPin.length != 4 || confirmNewPin.length != 4) {
      ToastHelper.showToast(
        context: context,
        message: "PIN must be 4 digits",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response =
      await dashboardRepository.resetForgotPin(
        newPin: newPin,
        confirmNewPin: confirmNewPin,
      );

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
        position: ToastPosition.top,
      );

      return response;
    } catch (e) {
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }

  Future<ResponseModel?> verifyPhone(
      BuildContext context,
      String phone,
      ) async {

    if (phone.length != 11) {
      ToastHelper.showToast(
        context: context,
        message: "Enter a valid phone number",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {

      LoadingHelper.show('');

      final response =
      await dashboardRepository.verifyPhone(phone);

      LoadingHelper.dismiss();

      if (response.responseSuccessful == false) {
        ToastHelper.showToast(
          context: context,
          message: response.responseMessage,
          icon: Icons.error,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }

      return response;


    } catch (e) {

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Error: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }

  Future<ResponseModel?> buyAirtime(
      BuildContext context, {
        required String phone,
        required int amount,
        required String network,
        required String pin,
      }) async {
    if (phone.isEmpty || amount <= 0 || pin.isEmpty || network.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response = await dashboardRepository.purchaseAirtime(
        phone: phone,
        amount: amount,
        network: network.toLowerCase().trim(), // ✅ CRITICAL FIX
        pin: pin,
      );

      LoadingHelper.dismiss();

      debugPrint("📡 Airtime Controller Response: ${response.responseMessage}");

      return response;
    } catch (e) {
      LoadingHelper.dismiss();

      debugPrint("🔥 Airtime Controller Error: $e");

      ToastHelper.showToast(
        context: context,
        message: "Airtime failed: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }

  Future<List<DataPlanModel>> fetchDataPlans(
      BuildContext context, String serviceId) async {
    try {
      LoadingHelper.show('');

      final plans = await dashboardRepository.getDataPlans(serviceId);

      LoadingHelper.dismiss();

      return plans;
    } catch (e) {
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Failed to load data plans",
        icon: Icons.error,
        iconColor: errorColor,
      );

      return [];
    }
  }
  Future<ResponseModel?> buyData(
      BuildContext context, {
        required String phone,
        required String serviceId,
        required String variationCode,
        required int amount,
        required String pin,
      }) async {
    if (phone.isEmpty ||
        serviceId.isEmpty ||
        variationCode.isEmpty ||
        amount <= 0 ||
        pin.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields are required",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    try {
      LoadingHelper.show('');

      final response = await dashboardRepository.purchaseData(
        serviceId: serviceId.trim(),
        phone: phone.trim(),
        billersCode: phone.trim(), // ✅ CRITICAL FIX
        variationCode: variationCode.trim(),
        amount: amount,
        pin: pin.trim(),
      );

      LoadingHelper.dismiss();

      debugPrint("📡 Data Controller Response: ${response.responseMessage}");

      return response;
    } catch (e) {
      LoadingHelper.dismiss();

      debugPrint("🔥 Data Controller Error: $e");

      ToastHelper.showToast(
        context: context,
        message: "Data purchase failed: $e",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );

      return null;
    }
  }



  Future<List<DataPlanModel>> fetchSmePlans(BuildContext context) async {
    try {
      final plans = await dashboardRepository.getSmeDataPlans();
      return plans;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCableProviders(
      BuildContext context) async {
    try {
      LoadingHelper.show('');

      final providers = await dashboardRepository.getCableProviders();

      LoadingHelper.dismiss();

      return providers;
    } catch (e) {
      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: "Failed to load providers",
        icon: Icons.error,
        iconColor: errorColor,
      );

      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCablePlans(
      BuildContext context,
      String serviceId,
      ) async {
    try {
      final result =
      await dashboardRepository.getCableVariations(serviceId);

      return result;
    } catch (e) {
      return [];
    }
  }



  Future<Map<String, dynamic>?> verifyCable(
      BuildContext context, {
        required String serviceId,
        required String smartcard,
      }) async {
    if (smartcard.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Enter smartcard number",
        icon: Icons.error,
        iconColor: errorColor,
      );
      return null;
    }

    try {
      LoadingHelper.show(

      );

      final result = await dashboardRepository.verifyCableCard(
        serviceId: serviceId,
        billersCode: smartcard,
      );

      // LoadingHelper.dismiss();

      if (result != null) {
        ToastHelper.showToast(
          context: context,
          message: "Verified: ${result['Customer_Name']}",
          icon: Icons.check_circle,
          iconColor: successColor,
        );
      }

      return result;
    } catch (e) {
      LoadingHelper.dismiss();
      return null;
    }
  }

  Future<ResponseModel?> buyCable(
      BuildContext context, {
        required String serviceId,
        required String smartcard,
        required String packageName,
        required String variationCode,
        required int amount,
        required String phone,
        required String pin,
      }) async {
    if (smartcard.isEmpty || variationCode.isEmpty || pin.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "All fields required",
        icon: Icons.error,
        iconColor: errorColor,
      );
      return null;
    }

    try {
      LoadingHelper.show(

      );

      final response = await dashboardRepository.purchaseCable(
        serviceId: serviceId,
        billersCode: smartcard,
        packageName: packageName,
        variationCode: variationCode,
        amount: amount,
        phone: phone,
        pin: pin,
      );

      LoadingHelper.dismiss();

      ToastHelper.showToast(
        context: context,
        message: response.responseMessage,
        icon: response.responseSuccessful
            ? Icons.check_circle
            : Icons.error,
        iconColor:
        response.responseSuccessful ? successColor : errorColor,
      );

      return response;
    } catch (e) {
      LoadingHelper.dismiss();
      return null;
    }
  }
  Future<ResponseModel> buyElectricity(
      BuildContext context, {
        required String serviceId,
        required String meterNumber,
        required String variationCode,
        required int amount,
        required String phone,
        required String pin,
      }) async {
    final repo = dashboardRepository;
    return await repo.purchaseElectricity(
      serviceId: serviceId,
      meterNumber: meterNumber,
      variationCode: variationCode,
      amount: amount,
      phone: phone,
      pin: pin,
    );
  }

// Future<List<DataPlanModel>> fetchDataPlans(
//     BuildContext context, String serviceId) async {
//   try {
//     LoadingHelper.show(
//       indicator: const CustomLoader(),
//       maskType: LoadingHelperMaskType.black,
//       dismissOnTap: false,
//     );
//
//     final plans = await dashboardRepository.getDataPlans(serviceId);
//
//     LoadingHelper.dismiss();
//
//     return plans;
//   } catch (e) {
//     LoadingHelper.dismiss();
//
//     ToastHelper.showToast(
//       context: context,
//       message: "Failed to load data plans",
//       icon: Icons.error,
//       iconColor: errorColor,
//     );
//
//     return [];
//   }
// }
}