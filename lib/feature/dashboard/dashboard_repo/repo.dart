import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../auth/data/api_constant.dart';
import '../../auth/data/api_data.dart';
import '../../auth/modal/reponse/response_modal.dart';
import '../../auth/modal/verify_bank.dart';
import '../../settings/model/qr_code.dart';
import '../model/bank_model.dart';
import '../model/data_model.dart';
import '../model/deposit.dart';
import '../model/favourite_beneficiary.dart';
import '../model/recent_transaction.dart';
import '../model/recent_transfer.dart';
import '../model/verify_transactions.dart';
import '../model/notification_model.dart';

final dashboardRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return DashboardRepository(apiClient);
});

class DashboardRepository {
  final ApiClient _apiClient;
  Box? _authBox;

  DashboardRepository(this._apiClient);

  Future<Box> _getAuthBox() async {
    if (_authBox == null || !_authBox!.isOpen) {
      _authBox = await Hive.openBox("authBox");
    }
    return _authBox!;
  }

  // ---------------- NOTIFICATIONS ----------------

  Future<NotificationResponse> fetchNotifications({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.getData('${ApiConstant.GET_NOTIFICATIONS}?page=$page&limit=$limit');
      final jsonResponse = jsonDecode(response.body);
      return NotificationResponse.fromJson(jsonResponse);
    } catch (e) {
      return NotificationResponse(
        responseSuccessful: false,
        responseMessage: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> fetchUnreadCount() async {
    try {
      final response = await _apiClient.getData(ApiConstant.UNREAD_NOTIFICATION_COUNT);
      return jsonDecode(response.body);
    } catch (e) {
      return {'responseSuccessful': false, 'responseMessage': e.toString()};
    }
  }

  Future<ResponseModel> markAllAsRead() async {
    try {
      final response = await _apiClient.patchData(ApiConstant.MARK_ALL_NOTIFICATIONS_READ, {});
      final jsonResponse = jsonDecode(response.body);
      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseMessage: e.toString(),
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> markAsRead(String id) async {
    try {
      final response = await _apiClient.patchData(ApiConstant.MARK_NOTIFICATION_READ(id), {});
      final jsonResponse = jsonDecode(response.body);
      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseMessage: e.toString(),
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Transfer money
// sendMoney in dashboardRepository
  Future<ResponseModel> sendMoney(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.postData(ApiConstant.TRANSER, body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseModel.fromJson(jsonResponse, response.statusCode);
      } else {
        return ResponseModel(
          responseMessage: jsonResponse["responseMessage"] ?? "Transfer failed",
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }
  //  Set payment PIN
  Future<ResponseModel> setPin(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.postData(ApiConstant.SET_PIN, body);
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true) {
        final box = await _getAuthBox();
        final userId = box.get("userId", defaultValue: "");
        if (userId.isNotEmpty) {
          final settingsBox = await Hive.openBox('settingsBox');
          await settingsBox.put('saved_pin_$userId', body['pin']);
        }
        await box.put('has_pin', true);
      }

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ?? 'PIN set successfully',
        responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Verify account
  Future<ResponseModel> verifyAccount(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.postData(ApiConstant.VERIFY_ACCOUNT, body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> verifyBody = (jsonResponse['responseBody'] ?? {}) as Map<String, dynamic>;
        final String fullname = (verifyBody['fullname'] ?? '').toString();

        final wrappedResponseBody = ResponseBody(
          user: UserResponse(fullname: fullname.isEmpty ? null : fullname),
        );

        return ResponseModel(
          responseSuccessful: true,
          responseMessage: jsonResponse["responseMessage"] ?? "Verification successful",
          statusCode: response.statusCode,
          responseBody: wrappedResponseBody,
        );
      } else {
        return ResponseModel(
          responseMessage: jsonResponse["responseMessage"] ?? "Verification failed",
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Verify Tag
  Future<ResponseModel> verifyTag(String tag) async {
    try {
      final response = await _apiClient.getData('/api/v1/user/resolve-tag/${tag.trim()}');
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> verifyBody = (jsonResponse['responseBody'] ?? {}) as Map<String, dynamic>;

        final wrappedResponseBody = ResponseBody(
          user: UserResponse.fromJson(verifyBody),
        );

        return ResponseModel(
          responseSuccessful: true,
          responseMessage: jsonResponse["responseMessage"] ?? "Tag resolved successfully",
          statusCode: response.statusCode,
          responseBody: wrappedResponseBody,
        );
      } else {
        return ResponseModel(
          responseMessage: jsonResponse["responseMessage"] ?? "Tag not found",
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Update user Tag
  Future<ResponseModel> updateTag(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.putData(ApiConstant.UPDATE_TAG, body);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseModel(
          responseSuccessful: true,
          responseMessage: jsonResponse["responseMessage"] ?? "Tag updated successfully",
          statusCode: response.statusCode,
        );
      } else {
        return ResponseModel(
          responseMessage: jsonResponse["responseMessage"] ?? "Failed to update tag",
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Fetch user QR code
  Future<QrCodeResponse> getUserQrCode({double? amount, String? narration}) async {
    try {
      String path = ApiConstant.GENERATE_QR_CODE;
      if (amount != null || narration != null) {
        final queryParams = <String, String>{};
        if (amount != null) queryParams['amount'] = amount.toString();
        if (narration != null) queryParams['narration'] = narration;
        path += "?${Uri(queryParameters: queryParams).query}";
      }
      final response = await _apiClient.getData(path);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return QrCodeResponse.fromJson(jsonResponse);
      } else {
        return QrCodeResponse(
          responseSuccessful: false,
          responseMessage:
          jsonResponse["responseMessage"] ?? "Failed to fetch QR code",
          responseBody: null,
        );
      }
    } catch (e) {
      return QrCodeResponse(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        responseBody: null,
      );
    }
  }

  // ---------------- QR PAYMENTS ----------------
  Future<ResponseModel> initiateQrPayment({
    required String receiverAccount,
    required double amount,
    String? narration,
  }) async {
    try {
      final body = {
        "receiverAccount": receiverAccount.trim(),
        "amount": amount,
        if (narration != null && narration.isNotEmpty) "narration": narration.trim(),
      };

      final response = await _apiClient.postData(ApiConstant.QR_INITIATE, body);
      final jsonResponse = jsonDecode(response.body);

      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> authorizeQrPayment({
    required String requestId,
    required String pin,
  }) async {
    try {
      final body = {
        "requestId": requestId.trim(),
        "pin": pin.trim(),
      };

      final response = await _apiClient.postData(ApiConstant.QR_AUTHORIZE, body);
      final jsonResponse = jsonDecode(response.body);

      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> payQrPayment({
    required String requestId,
    required String pin,
  }) async {
    try {
      final body = {
        "requestId": requestId.trim(),
        "pin": pin.trim(),
      };

      final response = await _apiClient.postData(ApiConstant.QR_PAY, body);
      final jsonResponse = jsonDecode(response.body);

      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> deductQrPayment({
    required String ownerAccount,
    required double amount,
    required String narration,
    required String pin,
  }) async {
    try {
      final body = {
        "ownerAccount": ownerAccount.trim(),
        "amount": amount,
        if (narration.isNotEmpty) "narration": narration.trim(),
        "pin": pin.trim(),
      };

      final response = await _apiClient.postData(ApiConstant.QR_DEDUCT, body);
      final jsonResponse = jsonDecode(response.body);

      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
        statusCode: 500,
      );
    }
  }

  //  Fetch Wallet Balance
  Future<WalletResponse?> getWalletBalance() async {
    try {
      debugPrint('🔑 Access Token: ${_apiClient.token}');
      final response = await _apiClient.getData(ApiConstant.WALLET_BALANCE);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['responseSuccessful'] == true) {
          final balanceJson = Map<String, dynamic>.from(jsonResponse['responseBody'] ?? {});

          // Save locally to Hive
          final box = await _getAuthBox();
          await box.put('balance', balanceJson['balance'] ?? 0);
          await box.put('currency', balanceJson['currency'] ?? 'NGN');
          await box.put('tier', balanceJson['tier'] ?? 'BASIC');
          await box.put('limits', balanceJson['limits'] ?? {});

          return WalletResponse.fromJson(balanceJson);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching wallet balance: $e');
      return null;
    }
  }

  //  Fetch Recent Transactions
  Future<TransactionResponse> getRecentTransactions() async {
    try {
      final response = await _apiClient.getData("${ApiConstant.TRANSACTION}?page=1&limit=2");
      debugPrint('RAW RECENT TRANSACTIONS RESPONSE: ${response.body}');
      final jsonResponse = jsonDecode(response.body);

      final dynamic body = jsonResponse['responseBody'];
      List<dynamic> list = [];
      
      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = body['transactions'] ?? body['recentTransactions'] ?? [];
      }

      final parsedTransactions = list
          .map<TransactionItem>((e) => TransactionItem.fromJson(e))
          .toList();

      for (var tx in parsedTransactions) {
        debugPrint('🆔 Recent Transaction: ${jsonEncode(tx.toJson())}');
      }

      debugPrint('✅ Recent transactions fetched: ${parsedTransactions.length} items');

      return TransactionResponse(
        responseSuccessful: jsonResponse['responseSuccessful'] ?? false,
        responseMessage: jsonResponse['responseMessage'] ?? '',
        transactions: parsedTransactions,
      );
    } catch (e) {
      debugPrint('❌ Error in getRecentTransactions: $e');
      return TransactionResponse(
        responseSuccessful: false,
        responseMessage: "Error: $e",
        transactions: [],
      );
    }
  }

  Future<TransactionResponse> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.getData("${ApiConstant.TRANSACTION}?page=$page&limit=$limit");
      debugPrint('RAW ALL TRANSACTIONS RESPONSE: ${response.body}');
      final jsonResponse = jsonDecode(response.body);

      final dynamic body = jsonResponse['responseBody'];
      List<dynamic> list = [];

      if (body is List) {
        list = body;
      } else if (body is Map) {
        list = body['transactions'] ?? body['recentTransactions'] ?? [];
      }

      final parsedTransactions = list
          .map<TransactionItem>((e) => TransactionItem.fromJson(e))
          .toList();

      for (var tx in parsedTransactions) {
        debugPrint('🆔 Transaction Item: ${jsonEncode(tx.toJson())}');
      }

      debugPrint('✅ All transactions fetched: ${parsedTransactions.length} items (Page: $page)');

      return TransactionResponse(
        responseSuccessful: jsonResponse['responseSuccessful'] ?? false,
        responseMessage: jsonResponse['responseMessage'] ?? '',
        transactions: parsedTransactions,
      );
    } catch (e) {
      debugPrint('❌ Error in getTransactions: $e');
      return TransactionResponse(
        responseSuccessful: false,
        responseMessage: "Error: $e",
        transactions: [],
      );
    }
  }

  Future<RecentBeneficiaryResponse> getRecentBeneficiary() async {
    try {
      final response = await _apiClient.getData(ApiConstant.RECENT_TRANSFER);
      final jsonResponse = jsonDecode(response.body);

      return RecentBeneficiaryResponse.fromJson(jsonResponse);
    } catch (e) {
      return RecentBeneficiaryResponse(
        responseSuccessful: false,
        responseMessage: "Error: $e",
        beneficiaries: [],
      );
    }
  }

  Future<FavouriteBeneficiaryResponse> getFavouriteBeneficiary() async {
    try {
      final response =
      await _apiClient.getData(ApiConstant.FAVOURITE_TRANSFER);

      final jsonResponse = jsonDecode(response.body);

      return FavouriteBeneficiaryResponse.fromJson(jsonResponse);
    } catch (e) {
      return FavouriteBeneficiaryResponse(
        responseSuccessful: false,
        responseMessage: "Error: $e",
        beneficiaries: [],
      );
    }
  }

  Future<UserResponse?> getUserProfile() async {
    try {
      final response = await _apiClient.getData(ApiConstant.PROFILE_UPDATE);

      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = UserResponse.fromJson(jsonResponse['responseBody']['user']);
        
        // 🔹 Save locally - Sync all relevant keys
        final box = await _getAuthBox();
        await box.put('saved_user_profile', user.toJson());
        
        // 🟢 Update individual keys used by Home and Welcome Screens
        if (user.picture != null) await box.put('picture', user.picture);
        if (user.fullname != null) await box.put('fullname', user.fullname);
        
        return user;

      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<DepositResponseModel> depositMoney(Map<String, dynamic> body) async {
    try {
      final normalizedBody = Map<String, dynamic>.from(body);
      if (normalizedBody.containsKey('amount')) {
        final amt = normalizedBody['amount'];
        if (amt is num) {
          normalizedBody['amount'] = amt.toInt().toString();
        } else {
          normalizedBody['amount'] = amt.toString();
        }
      }
      final response = await _apiClient.postData(ApiConstant.DEPOSIT, normalizedBody);
      final jsonData = jsonDecode(response.body);

      return DepositResponseModel.fromJson(jsonData);
    } catch (e) {
      return DepositResponseModel(
        responseMessage: 'Unable to initialize deposit',
        responseSuccessful: false,
      );
    }
  }

  Future<VerifyTransactionResponse?> verifyPayment(String reference) async {
    try {
      final url = "${ApiConstant.VERIFY_PAYMENT}/$reference";
      final response = await _apiClient.getData(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return VerifyTransactionResponse.fromJson(jsonResponse);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ResponseModel> changePin(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.postData(ApiConstant.UPDATE_PIN, body);
      final jsonResponse = jsonDecode(response.body);

      // Update saved PIN locally with user-specific key
      if (jsonResponse['responseSuccessful'] == true) {
        final box = await _getAuthBox();
        final userId = box.get("userId", defaultValue: "");
        if (userId.isNotEmpty) {
          final settingsBox = await Hive.openBox('settingsBox');
          await settingsBox.put('saved_pin_$userId', body['newPin']?.trim());
        }
      }

      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "PIN updated",
        responseSuccessful: jsonResponse["responseSuccessful"] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> uploadProfileImage(String imagePath) async {
    try {
      final uri = Uri.parse(
        '${ApiConstant.BASE_URL}${ApiConstant.UPDATE_AVATAR}',
      );

      final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';

      final request = http.MultipartRequest('PATCH', uri);
      // Use the token from ApiClient securely
      request.headers['Authorization'] = 'Bearer ${_apiClient.token}';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final json = jsonDecode(response.body);

      return ResponseModel(
        responseMessage:
        json['responseMessage'] ?? json['error'] ?? 'Upload failed',
        responseSuccessful: json['responseSuccessful'] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Image upload failed',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> updateUserProfile(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.patchData(ApiConstant.PROFILE_UPDATE, body);
      final jsonResponse = jsonDecode(response.body);

      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseMessage: 'Profile update failed',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<List<BankModel>> getBanks() async {
    try {
      final response = await _apiClient.getData(ApiConstant.GET_BANKS);
      debugPrint("🏦 getBanks API Response [${response.statusCode}]: ${response.body}");
      final jsonResponse = jsonDecode(response.body);

      List<dynamic> banksJson = [];
      if (jsonResponse is List) {
        banksJson = jsonResponse;
      } else if (jsonResponse is Map<String, dynamic>) {
        // Support standard wrapped response
        if (jsonResponse['responseSuccessful'] == true) {
          final responseBody = jsonResponse['responseBody'];
          if (responseBody is List) {
            banksJson = responseBody;
          } else if (responseBody is Map<String, dynamic>) {
            banksJson = responseBody['data'] ?? responseBody['banks'] ?? [];
          }
        } else {
          // If responseSuccessful is false but body contains data directly
          final responseBody = jsonResponse['responseBody'];
          if (responseBody is List) {
            banksJson = responseBody;
          } else if (responseBody is Map<String, dynamic>) {
            banksJson = responseBody['data'] ?? [];
          }
        }
      }

      final bankList = banksJson.map((e) => BankModel.fromJson(e as Map<String, dynamic>)).toList();
      debugPrint("🏦 Parsed ${bankList.length} banks successfully.");
      return bankList;
    } catch (e, stack) {
      debugPrint("❌ Error in getBanks: $e\n$stack");
      return [];
    }
  }

  // Verify Bank Account
// Verify Bank Account - UPDATED
  Future<BankAccountVerifyResponse> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
    required String bankName,
  }) async {
    try {
      final body = {
        "account": accountNumber.trim(),
        "bankCode": bankCode.trim(),
        "bankName": bankName.trim(),
      };

      final response = await _apiClient.postData(ApiConstant.VERIFY_BANK_ACCOUNT, body);
      final jsonResponse = jsonDecode(response.body);

      return BankAccountVerifyResponse.fromJson(jsonResponse);
    } catch (e) {
      return BankAccountVerifyResponse(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
      );
    }
  }

  Future<Map<String, dynamic>?> getTransactionCharges({
    required double amount,
    required String transactionType,
    required String serviceType,
  }) async {
    try {
      final queryParams = {
        'amount': amount.toStringAsFixed(2),
        'transactionType': transactionType,
        'serviceType': serviceType,
      };

      final endpoint = "${ApiConstant.GET_CHARGES}?${Uri(queryParameters: queryParams).query}";

      final response = await _apiClient.getData(endpoint);
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {
        return jsonResponse['responseBody'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<ResponseModel> forgotPaymentPin() async {
    try {
      final response =
      await _apiClient.postData(ApiConstant.FORGOT_PIN, {});

      final jsonResponse = jsonDecode(response.body);

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ?? "Request failed",
        responseSuccessful:
        jsonResponse['responseSuccessful'] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }
  // Send Money to Bank
  Future<BankTransferResponse> sendMoneyToBank({
    required String accountNumber,
    required String bankCode,
    required String bankName,
    required String amount,
    required String narration,
    required String pin,
    required bool saveBeneficiary,
  }) async {
    try {
      final body = {
        "account": accountNumber.trim(),
        "bankCode": bankCode.trim(),
        "bankName": bankName.trim(),
        "amount": amount.trim(),
        "narration": narration.trim(),
        "pin": pin.trim(),
        "save": saveBeneficiary,
      };

      final response =
      await _apiClient.postData(ApiConstant.BANK_TRANSFER, body);

      final jsonResponse = jsonDecode(response.body);

      return BankTransferResponse.fromJson(
        jsonResponse,
        response.statusCode,
      );
    } catch (e) {
      return BankTransferResponse(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> verifyBankTransfer(String reference) async {
    try {
      final url =
          "${ApiConstant.VERIFY_BANK_TRANSFER}/$reference";

      final response = await _apiClient.getData(url);

      if (response.headers['content-type']
          ?.contains('application/json') ??
          false) {
        final jsonResponse = jsonDecode(response.body);

        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ?? '',
          responseSuccessful:
          jsonResponse['responseSuccessful'] ?? false,
          statusCode: response.statusCode,
        );
      } else {
        return ResponseModel(
          responseMessage: "Invalid server response",
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRecentBankTransfers() async {
    try {
      final response =
      await _apiClient.getData(ApiConstant.RECENT_BANK_TRANSFERS);

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true) {
        final List<dynamic> data = jsonResponse['responseBody'] ?? [];

        return data.map<Map<String, dynamic>>((e) => {
          "name": e['accountName'],
          "account": e['accountNumber'],
          "bankCode": e['bankCode'],
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBankBeneficiaries() async {
    try {
      final response = await _apiClient.getData(
        "${ApiConstant.BENEFICIARIES}?page=1&limit=10",
      );

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true) {
        final List<dynamic> data =
            jsonResponse['responseBody']?['data'] ?? [];

        return data
            .where((e) => e['type'] == "BANK")
            .map<Map<String, dynamic>>((e) => {
          "name": e['bank']?['accountName'],
          "account": e['bank']?['accountNumber'],
          "bankCode": e['bank']?['bankCode'],
        })
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<ResponseModel> verifyForgotPin(String otp) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.VERIFY_FORGOT_PIN,
        {
          "otp": otp.trim(),
        },
      );

      final jsonResponse = jsonDecode(response.body);

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ?? "Verification failed",
        responseSuccessful:
        jsonResponse['responseSuccessful'] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> resetForgotPin({
    required String newPin,
    required String confirmNewPin,
  }) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.RESTORE_FORGOT_PIN,
        {
          "newPin": newPin.trim(),
          "confirmNewPin": confirmNewPin.trim(),
        },
      );

      final jsonResponse = jsonDecode(response.body);

      // Update saved PIN locally with user-specific key
      if (jsonResponse['responseSuccessful'] == true) {
        final box = await _getAuthBox();
        final userId = box.get("userId", defaultValue: "");
        if (userId.isNotEmpty) {
          final settingsBox = await Hive.openBox('settingsBox');
          await settingsBox.put('saved_pin_$userId', newPin.trim());
        }
      }

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ?? "Failed",
        responseSuccessful:
        jsonResponse['responseSuccessful'] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> verifyPhone(String phone) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.VERIFY_PHONE,
        {"phone": phone},
      );

      final jsonResponse = jsonDecode(response.body);
      debugPrint('📱 Phone Verify Response: ${response.body}');

      // Extract response body safely
      final responseBodyList = jsonResponse["responseBody"];
      ResponseBody? parsedBody;
      
      if (responseBodyList is List && responseBodyList.isNotEmpty) {
        parsedBody = ResponseBody.fromJson(responseBodyList[0]);
      }

      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"] ?? "Verification failed",
        responseSuccessful: jsonResponse["responseSuccessful"] ?? false,
        statusCode: response.statusCode,
        responseBody: parsedBody,
      );

    } catch (e) {
      return ResponseModel(
        responseMessage: "Something went wrong",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> purchaseAirtime({
    required String phone,
    required int amount,
    required String network,
    required String pin,
  }) async {
    try {
      final body = {
        "phone": phone,
        "amount": amount,
        "network": network,
        "pin": pin
      };

      final response =
      await _apiClient.postData(ApiConstant.BUY_AIRTIME, body);

      final jsonResponse = jsonDecode(response.body);

      return ResponseModel(
        responseMessage: jsonResponse["responseMessage"],
        responseSuccessful: jsonResponse["responseSuccessful"],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        responseMessage: "Airtime purchase failed",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<List<DataPlanModel>> getDataPlans(String serviceId) async {
    try {

      debugPrint("📤 GET PLANS URL: ${ApiConstant.DATA_PLANS}?serviceID=$serviceId");
      final response = await _apiClient.getData(
          "${ApiConstant.DATA_PLANS}?serviceID=$serviceId"
      );
      debugPrint("📥 GET PLANS RESPONSE STATUS: ${response.statusCode}");
      debugPrint("📥 GET PLANS RESPONSE BODY: ${response.body}");

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {
        final body = jsonResponse['responseBody'] ?? {};
        final List list = body['variations'] ?? [];

        return list.map((e) => DataPlanModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      debugPrint("🔥 Data plans error: $e");
      return [];
    }
  }
  Future<ResponseModel> purchaseData({
    required String serviceId,
    required String phone,
    required String billersCode,
    required String variationCode,
    required int amount,
    required String pin,
  }) async {
    final body = {
      "serviceID": serviceId,
      "billersCode": billersCode,
      "variation_code": variationCode,
      "amount": amount,
      "phone": phone,
      "pin": pin,
    };

    debugPrint("📤 DATA PURCHASE BODY: $body");

    final response = await _apiClient.postData(
      ApiConstant.DATA_PURCHASE,
      body,
    );

    debugPrint("📥 DATA PURCHASE RESPONSE STATUS: ${response.statusCode}");
    debugPrint("📥 DATA PURCHASE RESPONSE BODY: ${response.body}");

    // ✅ FIX: decode response.body
    final decoded = jsonDecode(response.body);

    return ResponseModel.fromJson(
      decoded,
      response.statusCode,
    );
  }

  Future<List<DataPlanModel>> getSmeDataPlans() async {
    try {
      final response = await _apiClient.getData(
          ApiConstant.GET_DATA_PLANS,
      );

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true) {
        final List list =
            jsonResponse['responseBody']?['variations'] ?? [];

        return list.map((e) => DataPlanModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCableProviders() async {
    try {
      final response = await _apiClient.getData(
        ApiConstant.GET_CABLE_PROVIDERS,
      );

      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {
        final List list = jsonResponse['responseBody'] ?? [];

        return list.map<Map<String, dynamic>>((e) {
          return {
            "name": e["name"],
            "serviceID": e["serviceID"],
          };
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCableVariations(
      String serviceId) async {
    try {
      final response = await _apiClient.getData(
        "${ApiConstant.GET_CABLE_VARIATION}$serviceId"
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {

        final body = jsonResponse['responseBody'] ?? {};

        // ✅ Handle both correct + wrong key
        final List variations =
            body['variations'] ?? body['varations'] ?? [];

        return variations.map<Map<String, dynamic>>((e) {
          return {
            "variation_code": e["variation_code"],
            "name": e["name"],
            "variation_amount": e["variation_amount"],
          };
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> verifyCableCard({
    required String serviceId,
    required String billersCode,
  }) async {
    try {
      final body = {
        "serviceID": serviceId,
        "billersCode": billersCode,
      };

      final response = await _apiClient.postData(
        ApiConstant.VERIFY_SMART_CARD,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {
        return jsonResponse['responseBody'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ResponseModel> purchaseCable({
    required String serviceId,
    required String billersCode,
    required String packageName,
    required String variationCode,
    required int amount,
    required String phone,
    required String pin,
  }) async {
    try {
      final body = {
        "serviceID": serviceId,
        "billersCode": billersCode,
        "packageName": packageName,
        "variation_code": variationCode,
        "amount": amount,
        "phone": phone,
        "pin": pin,
      };

      final response = await _apiClient.postData(
        ApiConstant.PURCHASE_CABLE,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      return ResponseModel.fromJson(jsonResponse, response.statusCode);
    } catch (e) {
      return ResponseModel(
        responseMessage: "Purchase failed",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getElectricityProviders() async {
    try {
      final response = await _apiClient.getData(
      ApiConstant.GET_ELECTRICITY_PROVIDERS,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {
        final List list = jsonResponse['responseBody'] ?? [];

        return list.map<Map<String, dynamic>>((e) {
          return {
            "name": e["name"],
            "serviceID": e["serviceID"],
          };
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
  Future<Map<String, dynamic>?> verifyElectricityMeter({
    required String serviceId,
    required String meterNumber,
    required String type, // prepaid | postpaid
  }) async {
    try {
      final body = {
        "serviceID": serviceId,
        "billersCode": meterNumber,
        "type": type,
      };

      final response = await _apiClient.postData(
        ApiConstant.VERIFY_ELECTRICITY_METER,
        body,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['responseSuccessful'] == true) {
        return jsonResponse['responseBody'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ResponseModel> purchaseElectricity({
    required String serviceId,
    required String meterNumber,
    required String variationCode, // prepaid/postpaid
    required int amount,
    required String phone,
    required String pin,
  }) async {
    try {
      final body = {
        "serviceID": serviceId,
        "billersCode": meterNumber,
        "biller_code": meterNumber, // Secondary key just in case
        "variation_code": variationCode,
        "amount": amount,
        "phone": phone,
        "pin": pin,
      };

      print("📤 ELECTRICITY REQUEST PAYLOAD: $body");

      final response = await _apiClient.postData(
        ApiConstant.PURCHASE_ELECTRICITY_UNIT,
        body,
      );

      final jsonResponse = jsonDecode(response.body);
      
      print("📥 ELECTRICITY API RESPONSE: $jsonResponse");

      return ResponseModel.fromJson(
        jsonResponse,
        response.statusCode,
      );
    } catch (e) {
      print("❌ ELECTRICITY PURCHASE EXCEPTION: $e");
      return ResponseModel(
        responseMessage: "Purchase failed: $e",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }



  // Future<List<DataPlanModel>> getDataPlans(String serviceId) async {
  //   try {
  //     final box = await Hive.openBox("authBox");
  //     final token = box.get("token", defaultValue: "");
  //
  //     if (token.isEmpty) return [];
  //
  //     _apiClient.updateHeaders(token);
  //
  //     final response = await _apiClient.getData(
  //       "/api/v1/billpayment/data/plans?serviceID=$serviceId",
  //     );
  //
  //     final jsonResponse = jsonDecode(response.body);
  //
  //     if (response.statusCode == 200 &&
  //         jsonResponse['responseSuccessful'] == true) {
  //       final body = jsonResponse['responseBody'] ?? {};
  //
  //       final List list = body['variations'] ?? [];
  //
  //       return list.map((e) => DataPlanModel.fromJson(e)).toList();
  //     }
  //
  //     return [];
  //   } catch (e) {
  //     debugPrint("🔥 Data plans error: $e");
  //     return [];
  //   }
  // }
}