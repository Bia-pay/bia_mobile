import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../auth/data/api_constant.dart';
import '../../auth/data/api_data.dart';
import '../../auth/modal/reponse/response_modal.dart';
import '../../settings/model/qr_code.dart';
import '../model/deposit.dart';
import '../model/recent_transaction.dart';
import '../model/recent_transfer.dart';
import '../model/verify_transactions.dart';

final dashboardRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return DashboardRepository(apiClient);
});

class DashboardRepository {
  final ApiClient _apiClient;
  DashboardRepository(this._apiClient);

  //  Transfer money
  Future<ResponseModel> sendMoney(Map<String, dynamic> body) async {
    print('📡 Attempting transfer...');
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");
      print("🔑 Using token: $token");

      if (token.isEmpty) {
        return ResponseModel(
          responseMessage: "No token found. Please log in again.",
          responseSuccessful: false,
          statusCode: 401,
        );
      }

      // ✅ Make sure token is sent by ApiClient
      _apiClient.updateHeaders(token);

      final response = await _apiClient.postData(ApiConstant.TRANSER, body);
      final jsonResponse = jsonDecode(response.body);
      print("✅ API Response: $jsonResponse");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseModel(
          responseMessage:
          jsonResponse['responseMessage'] ?? 'Transfer successful',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
        );
      } else {
        return ResponseModel(
          responseMessage:
          jsonResponse["responseMessage"] ?? "Transfer failed",
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('🔥 Exception during transfer: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Set payment PIN
  Future<ResponseModel> setPin(Map<String, dynamic> body) async {
    print('📡 Setting PIN...');
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");
      print("🔑 Using token: $token");

      if (token.isEmpty) {
        return ResponseModel(
          responseMessage: "No token found. Please log in again.",
          responseSuccessful: false,
          statusCode: 401,
        );
      }

      _apiClient.updateHeaders(token);

      final response = await _apiClient.postData(ApiConstant.SET_PIN, body);
      final jsonResponse = jsonDecode(response.body);
      print("✅ Response: $jsonResponse");

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ?? 'PIN set successfully',
        responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('🔥 Exception during setPin: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Verify account
  Future<ResponseModel> verifyAccount(Map<String, dynamic> body) async {
    print('📡 Verifying account...');
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");
      print("🔑 Using token: $token");

      _apiClient.updateHeaders(token);
      final response = await _apiClient.postData(ApiConstant.VERIFY_ACCOUNT, body);
      final jsonResponse = jsonDecode(response.body);
      print("✅ Verify response: $jsonResponse");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // The API returns: { responseSuccessful: true, responseMessage: "...", responseBody: { fullname: "..." } }
        final Map<String, dynamic> verifyBody = (jsonResponse['responseBody'] ?? {}) as Map<String, dynamic>;
        final String fullname = (verifyBody['fullname'] ?? '').toString();

        // Wrap fullname into your existing ResponseBody.user so rest of app can read result.responseBody?.user?.fullname
        final wrappedResponseBody = ResponseBody(
          user: UserResponse(fullname: fullname.isEmpty ? null : fullname),
        );

        return ResponseModel(
          responseMessage: jsonResponse['responseMessage'] ?? 'Account verified successfully',
          responseSuccessful: jsonResponse['responseSuccessful'] ?? true,
          statusCode: response.statusCode,
          responseBody: wrappedResponseBody,
        );
      } else {
        return ResponseModel(
          responseMessage: jsonResponse['responseMessage'] ?? 'Verification failed',
          responseSuccessful: false,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('🔥 Exception verifying account: $e');
      return ResponseModel(
        responseMessage: 'Something went wrong. Please try again.',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  //  Fetch user QR code
  Future<QrCodeResponse> getUserQrCode() async {
    print('📡 Fetching user QR code...');
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");
      print("🔑 Using token: $token");

      if (token.isEmpty) {
        return QrCodeResponse(
          responseMessage: "No token found. Please log in again.",
          responseSuccessful: false,
          responseBody: null,
        );
      }

      _apiClient.updateHeaders(token);

      // ✅ Call endpoint
      final response = await _apiClient.getData(ApiConstant.GENERATE_QR_CODE);
      final jsonResponse = jsonDecode(response.body);
      print("✅ QR Response: $jsonResponse");

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
      print('🔥 Exception fetching QR code: $e');
      return QrCodeResponse(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        responseBody: null,
      );
    }
  }

  //  Fetch Wallet Balance
  Future<WalletResponse?> getWalletBalance() async {
    try {
      final response = await _apiClient.getData(ApiConstant.WALLET_BALANCE);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['responseSuccessful'] == true) {
          final balanceJson = Map<String, dynamic>.from(jsonResponse['responseBody'] ?? {});

          // Save locally to Hive
          final box = await Hive.openBox('authBox');
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
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) {
        return TransactionResponse(
          responseSuccessful: false,
          responseMessage: "No token found",
          transactions: [],
        );
      }

      _apiClient.updateHeaders(token);

      final response = await _apiClient.getData("${ApiConstant.TRANSACTION}?page=1&limit=3");
      final jsonResponse = jsonDecode(response.body);

      // 🔹 Print out the raw responseBody for debugging
      debugPrint('📦 Transaction API responseBody: ${jsonResponse['responseBody']}');

      final body = jsonResponse['responseBody'] ?? {};
      final list = body['transactions'] ?? [];

      final parsedTransactions = list
          .map<TransactionItem>((e) => TransactionItem.fromJson(e))
          .toList();

      return TransactionResponse(
        responseSuccessful: jsonResponse['responseSuccessful'] ?? false,
        responseMessage: jsonResponse['responseMessage'] ?? '',
        transactions: parsedTransactions,
      );
    } catch (e) {
      debugPrint('⚠️ Transaction API error: $e');
      return TransactionResponse(
        responseSuccessful: false,
        responseMessage: "Error: $e",
        transactions: [],
      );
    }
  }
  Future<TransactionResponse> getTransactions() async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) {
        return TransactionResponse(
          responseSuccessful: false,
          responseMessage: "No token found",
          transactions: [],
        );
      }

      _apiClient.updateHeaders(token);

      final response = await _apiClient.getData("${ApiConstant.TRANSACTION}?page=1&limit=3000");
      final jsonResponse = jsonDecode(response.body);

      // 🔹 Print out the raw responseBody for debugging
      debugPrint('📦 Transaction API responseBody: ${jsonResponse['responseBody']}');

      final body = jsonResponse['responseBody'] ?? {};
      final list = body['transactions'] ?? [];

      final parsedTransactions = list
          .map<TransactionItem>((e) => TransactionItem.fromJson(e))
          .toList();

      return TransactionResponse(
        responseSuccessful: jsonResponse['responseSuccessful'] ?? false,
        responseMessage: jsonResponse['responseMessage'] ?? '',
        transactions: parsedTransactions,
      );
    } catch (e) {
      debugPrint('⚠️ Transaction API error: $e');
      return TransactionResponse(
        responseSuccessful: false,
        responseMessage: "Error: $e",
        transactions: [],
      );
    }
  }

  Future<RecentBeneficiaryResponse> getRecentBeneficiary() async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");
      if (token.isEmpty) return RecentBeneficiaryResponse(
        responseSuccessful: false,
        responseMessage: "No token found",
        beneficiaries: [],
      );

      _apiClient.updateHeaders(token);
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
  Future<UserResponse?> getUserProfile() async {
    try {
      final box = await Hive.openBox('authBox');
      final token = box.get('token', defaultValue: '');
      if (token.isEmpty) return null;

      _apiClient.updateHeaders(token);
      final response = await _apiClient.getData(ApiConstant.PROFILE_UPDATE);

      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = UserResponse.fromJson(jsonResponse['responseBody']['user']);
        print(response.body);
        // Save locally
        await box.put('saved_user_profile', user.toJson());
        return user;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      return null;
    }
  }
// 💰 Deposit Money
  Future<DepositResponseModel> depositMoney(Map<String, dynamic> body) async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");
      print("🔑 Using token: $token");

      _apiClient.updateHeaders(token);
      final response = await _apiClient.postData(ApiConstant.DEPOSIT, body);
      // 🔹 Print raw API response
      print("➡️ Status code: ${response.statusCode}");
      print("➡️ Raw response body: ${response.body}");

      final jsonData = jsonDecode(response.body);

      // 🔹 Print decoded JSON
      print("➡️ Decoded JSON: $jsonData");

      return DepositResponseModel.fromJson(jsonData);
    } catch (e) {
      print('❌ Deposit API error: $e');
      return DepositResponseModel(
        responseMessage: 'Unable to initialize deposit',
        responseSuccessful: false,
      );
    }
  }
  Future<VerifyTransactionResponse?> verifyPayment(String reference) async {
    final url = "${ApiConstant.VERIFY_PAYMENT}/$reference";
    print('📡 Verifying payment... $reference');
    try {
      final response = await _apiClient.getData(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("🔍 Verify Payment Response: $jsonResponse");

        // ✅ Only pass the JSON map
        return VerifyTransactionResponse.fromJson(jsonResponse);
      }

      return null;
    } catch (e) {
      print("🔥 Error verifying payment: $e");
      return null;
    }
  }
  Future<ResponseModel> changePin(Map<String, dynamic> body) async {
    print('📡 Updating PIN...');
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) {
        return ResponseModel(
          responseMessage: "No token found. Please log in again.",
          responseSuccessful: false,
          statusCode: 401,
        );
      }

      // Attach token
      _apiClient.updateHeaders(token);

      final response = await _apiClient.putData(ApiConstant.UPDATE_PIN, body);
      final jsonResponse = jsonDecode(response.body);
      print("🔁 Update PIN response: $jsonResponse");

      return ResponseModel(
        responseMessage:
        jsonResponse['responseMessage'] ?? "Failed to update PIN",
        responseSuccessful: jsonResponse['responseSuccessful'] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print("🔥 Error updating PIN: $e");
      return ResponseModel(
        responseMessage: "Something went wrong. Please try again.",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }
}