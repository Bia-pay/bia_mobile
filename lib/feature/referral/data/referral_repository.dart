import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/api_constant.dart';
import '../../auth/data/api_data.dart';
import '../model/referral_models.dart';

final referralRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ReferralRepository(apiClient);
});

class ReferralRepository {
  final ApiClient _apiClient;

  ReferralRepository(this._apiClient);

  Future<ReferralStats?> getReferralStats() async {
    try {
      final response = await _apiClient.getData(ApiConstant.REFERRAL_STATS);
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['responseSuccessful'] == true && jsonResponse['responseBody'] != null) {
        return ReferralStats.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<ReferralHistoryItem>> getReferralHistory() async {
    try {
      final response = await _apiClient.getData(ApiConstant.REFERRAL_HISTORY);
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['responseSuccessful'] == true && jsonResponse['responseBody'] != null) {
        final List<dynamic> list = jsonResponse['responseBody'];
        return list.map((e) => ReferralHistoryItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
