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
import '../model/deposit.dart';
import '../model/favourite_beneficiary.dart';
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
// sendMoney in dashboardRepository
  Future<ResponseModel> sendMoney(Map<String, dynamic> body) async {
    print('📡 Attempting transfer: $body');
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
          responseMessage: jsonResponse["responseMessage"] ?? "Transfer failed",
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

      final response = await _apiClient.getData("${ApiConstant.TRANSACTION}?page=1&limit=2");
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

  // Future<FavouriteBeneficiaryResponse>
  // getFavouriteBeneficiary() async {
  //   try {
  //     final box = await Hive.openBox("authBox");
  //     final token = box.get("token", defaultValue: "");
  //
  //     if (token.isEmpty) {
  //       return FavouriteBeneficiaryResponse(
  //         responseSuccessful: false,
  //         responseMessage: "No token found",
  //         beneficiaries: [],
  //       );
  //     }
  //
  //     _apiClient.updateHeaders(token);
  //
  //     final response =
  //     await _apiClient.getData(ApiConstant.FAVOURITE_TRANSFER);
  //
  //     final jsonResponse = jsonDecode(response.body);
  //
  //     return FavouriteBeneficiaryResponse.fromJson(jsonResponse);
  //   } catch (e) {
  //     return FavouriteBeneficiaryResponse(
  //       responseSuccessful: false,
  //       responseMessage: "Error: $e",
  //       beneficiaries: [],
  //     );
  //   }
  // }

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

  Future<FavouriteBeneficiaryResponse> getFavouriteBeneficiary() async {
    try {
      debugPrint("🔥 CALLING FAVOURITE ENDPOINT");

      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) {
        return FavouriteBeneficiaryResponse(
          responseSuccessful: false,
          responseMessage: "No token found",
          beneficiaries: [],
        );
      }

      _apiClient.updateHeaders(token);

      final response =
      await _apiClient.getData(ApiConstant.FAVOURITE_TRANSFER);

      debugPrint("🔥 FAV RAW RESPONSE: ${response.body}");

      final jsonResponse = jsonDecode(response.body);

      return FavouriteBeneficiaryResponse.fromJson(jsonResponse);
    } catch (e) {
      debugPrint("❌ Favourite API error: $e");

      return FavouriteBeneficiaryResponse(
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
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      _apiClient.updateHeaders(token);

      final url = "${ApiConstant.VERIFY_PAYMENT}/$reference";

      print('📡 Verifying payment... $url');

      final response = await _apiClient.getData(url);

      print("➡️ Status: ${response.statusCode}");
      print("➡️ Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
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

  // Future<ResponseModel> uploadProfileImage(String imagePath) async {
  //   try {
  //     final box = await Hive.openBox('authBox');
  //     final token = box.get('token') as String?;
  //
  //     debugPrint('🔐 UPLOAD TOKEN FROM HIVE: $token');
  //
  //     if (token == null || token.isEmpty) {
  //       return ResponseModel(
  //         responseMessage: "No token found",
  //         responseSuccessful: false,
  //         statusCode: 401,
  //       );
  //     }
  //
  //     final uri = Uri.parse(
  //       '${ApiConstant.BASE_URL}${ApiConstant.UPDATE_AVATAR}',
  //     );
  //
  //     final request = http.MultipartRequest('PATCH', uri);
  //     request.headers['Authorization'] = 'Bearer $token';
  //     request.headers['Accept'] = 'application/json';
  //
  //     request.files.add(
  //       await http.MultipartFile.fromPath(
  //         'image',
  //         imagePath,
  //         contentType: MediaType('image', 'jpeg'), // 🔥 IMPORTANT
  //       ),
  //     );
  //
  //     debugPrint('📤 Uploading image: $imagePath');
  //
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);
  //
  //     debugPrint("🟢 UPLOAD STATUS: ${response.statusCode}");
  //     debugPrint("🟢 UPLOAD BODY: ${response.body}");
  //
  //     final json = jsonDecode(response.body);
  //     if (json['responseSuccessful'] == true) {
  //       final pictureUrl = json['responseBody']?['picture'];
  //
  //       if (pictureUrl != null) {
  //         final box = Hive.box('authBox');
  //         await box.put('picture', pictureUrl);
  //       }
  //     }
  //     return ResponseModel(
  //       responseMessage:
  //       json['responseMessage'] ?? json['error'] ?? 'Upload failed',
  //       responseSuccessful: json['responseSuccessful'] ?? false,
  //       statusCode: response.statusCode,
  //     );
  //   } catch (e) {
  //     debugPrint("🔥 Upload exception: $e");
  //     return ResponseModel(
  //       responseMessage: 'Image upload failed',
  //       responseSuccessful: false,
  //       statusCode: 500,
  //     );
  //   }
  // }

  Future<ResponseModel> uploadProfileImage(String imagePath) async {
    try {
      final box = await Hive.openBox('authBox');
      final token = box.get('token') as String?;

      if (token == null || token.isEmpty) {
        return ResponseModel(
          responseMessage: "No token found",
          responseSuccessful: false,
          statusCode: 401,
        );
      }

      final uri = Uri.parse(
        '${ApiConstant.BASE_URL}${ApiConstant.UPDATE_AVATAR}',
      );

      final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');

      debugPrint("📤 Uploading image: $imagePath");
      debugPrint("📤 MIME TYPE: $mimeType");

      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("🟢 STATUS: ${response.statusCode}");
      debugPrint("🟢 BODY: ${response.body}");

      final json = jsonDecode(response.body);

      return ResponseModel(
        responseMessage:
        json['responseMessage'] ?? json['error'] ?? 'Upload failed',
        responseSuccessful: json['responseSuccessful'] ?? false,
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint("🔥 Upload exception: $e");
      return ResponseModel(
        responseMessage: 'Image upload failed',
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<List<BankModel>> getBanks() async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) return [];

      _apiClient.updateHeaders(token);
      final response = await _apiClient.getData(ApiConstant.GET_BANKS);
      final jsonResponse = jsonDecode(response.body);

      print("🏦 Banks Response: $jsonResponse");

      if (response.statusCode == 200 && jsonResponse['responseSuccessful'] == true) {
        // FIX: Access the nested 'data' array inside 'responseBody'
        final responseBody = jsonResponse['responseBody'] ?? {};
        final List<dynamic> banksJson = responseBody['data'] ?? [];

        return banksJson.map((e) => BankModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 Error fetching banks: $e');
      return [];
    }
  }

  // Verify Bank Account
  Future<BankAccountVerifyResponse> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) {
        return BankAccountVerifyResponse(
          responseSuccessful: false,
          responseMessage: "No token found. Please log in again.",
        );
      }

      _apiClient.updateHeaders(token);

      final body = {
        "account": accountNumber.trim(),
        "bankCode": bankCode.trim(),
      };

      print("🔍 Verifying bank account: $body");

      final response = await _apiClient.postData(ApiConstant.VERIFY_BANK_ACCOUNT, body);
      final jsonResponse = jsonDecode(response.body);

      print("✅ Verify Response: $jsonResponse");

      return BankAccountVerifyResponse.fromJson(jsonResponse);
    } catch (e) {
      print('🔥 Error verifying account: $e');
      return BankAccountVerifyResponse(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
      );
    }
  }

  // Send Money to Bank
  Future<BankTransferResponse> sendMoneyToBank({
    required String accountNumber,
    required String bankCode,
    required String bankName, // ✅ ADD THIS
    required String amount,
    required String narration,
    required String pin,
    required bool saveBeneficiary,
  }) async {
    print('📡 Initiating bank transfer...');

    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) {
        return BankTransferResponse(
          responseSuccessful: false,
          responseMessage: "No token found. Please log in again.",
          statusCode: 401,
        );
      }

      _apiClient.updateHeaders(token);

      final body = {
        "account": accountNumber.trim(),
        "bankCode": bankCode.trim(),
        "bankName": bankName.trim(), // ✅ ADDED
        "amount": amount.trim(),
        "narration": narration.trim(),
        "pin": pin.trim(),
        "save": saveBeneficiary,
      };

      print("➡️ Bank transfer payload: $body");

      final response =
      await _apiClient.postData(ApiConstant.BANK_TRANSFER, body);

      final jsonResponse = jsonDecode(response.body);

      print("✅ Transfer Response: $jsonResponse");

      return BankTransferResponse.fromJson(
        jsonResponse,
        response.statusCode,
      );
    } catch (e) {
      print('🔥 Exception during bank transfer: $e');

      return BankTransferResponse(
        responseSuccessful: false,
        responseMessage: "Something went wrong. Please try again.",
        statusCode: 500,
      );
    }
  }

  Future<ResponseModel> verifyBankTransfer(String reference) async {
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

      _apiClient.updateHeaders(token);

      final url =
          "${ApiConstant.VERIFY_BANK_TRANSFER}/$reference";

      print("🔎 Verifying bank transfer: $url");

      final response = await _apiClient.getData(url);

      print("➡️ Status: ${response.statusCode}");
      print("➡️ Body: ${response.body}");

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
      print("🔥 Verify bank transfer error: $e");
      return ResponseModel(
        responseMessage: "Something went wrong",
        responseSuccessful: false,
        statusCode: 500,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRecentBankTransfers() async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) return [];

      _apiClient.updateHeaders(token);

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
      print("🔥 Bank recent error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBankBeneficiaries() async {
    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token", defaultValue: "");

      if (token.isEmpty) return [];

      _apiClient.updateHeaders(token);

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
      print("🔥 Bank beneficiaries error: $e");
      return [];
    }
  }
}