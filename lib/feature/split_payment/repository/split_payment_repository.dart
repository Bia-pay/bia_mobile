import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/api_constant.dart';
import '../../auth/data/api_data.dart';
import '../model/split_models.dart';

final splitPaymentRepositoryProvider = Provider<SplitPaymentRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SplitPaymentRepository(apiClient);
});

class SplitPaymentRepository {
  final ApiClient _apiClient;

  SplitPaymentRepository(this._apiClient);

  Future<CreateSplitResponse?> createSplit(CreateSplitRequest request) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.CREATE_SPLIT,
        request.toJson(),
      );
      final jsonResponse = jsonDecode(response.body);
      debugPrint('=== CREATE SPLIT RESPONSE ===');
      debugPrint(jsonEncode(jsonResponse));

      if (jsonResponse['responseSuccessful'] == true &&
          jsonResponse['responseBody'] != null) {
        return CreateSplitResponse.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ScanSplitResponse?> scanSplit(String splitId, String token) async {
    try {
      final response = await _apiClient.postData(ApiConstant.SCAN_SPLIT, {
        'splitId': splitId,
        'token': token,
      });
      final jsonResponse = jsonDecode(response.body);
      debugPrint('=== SCAN SPLIT RESPONSE ===');
      debugPrint(jsonEncode(jsonResponse));

      if (jsonResponse['responseSuccessful'] == true &&
          jsonResponse['responseBody'] != null) {
        return ScanSplitResponse.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaySplitResponse?> paySplit(String splitId, String pin) async {
    try {
      final response = await _apiClient.postData(ApiConstant.PAY_SPLIT, {
        'splitId': splitId,
        'pin': pin,
      });
      final jsonResponse = jsonDecode(response.body);
      debugPrint('=== PAY SPLIT RESPONSE ===');
      debugPrint(jsonEncode(jsonResponse));

      if (jsonResponse['responseSuccessful'] == true &&
          jsonResponse['responseBody'] != null) {
        return PaySplitResponse.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SplitDetailsResponse?> getSplitDetails(String splitId) async {
    try {
      final response = await _apiClient.getData(
        ApiConstant.GET_SPLIT_DETAILS(splitId),
      );
      final jsonResponse = jsonDecode(response.body);
      debugPrint('=== GET SPLIT DETAILS RESPONSE ===');
      debugPrint(jsonEncode(jsonResponse));

      if (jsonResponse['responseSuccessful'] == true &&
          jsonResponse['responseBody'] != null) {
        return SplitDetailsResponse.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendReminders(String splitId) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.REMIND_SPLIT(splitId),
        {},
      );
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['responseSuccessful'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelSplit(String splitId) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.CANCEL_SPLIT(splitId),
        {},
      );
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['responseSuccessful'] == true;
    } catch (e) {
      return false;
    }
  }
}
