import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/referral_repository.dart';
import '../model/referral_models.dart';

final referralStatsProvider = FutureProvider.autoDispose<ReferralStats?>((ref) async {
  final repository = ref.watch(referralRepositoryProvider);
  return repository.getReferralStats();
});

final referralHistoryProvider = FutureProvider.autoDispose<List<ReferralHistoryItem>>((ref) async {
  final repository = ref.watch(referralRepositoryProvider);
  return repository.getReferralHistory();
});
