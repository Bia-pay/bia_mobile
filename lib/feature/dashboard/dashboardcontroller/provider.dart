import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/local/localStorage.dart';
import '../dashboard_repo/repo.dart';
import '../model/recent_transaction.dart';
import 'package:hive/hive.dart';

final recentTransactionsProvider = StateNotifierProvider<RecentTransactionsNotifier, AsyncValue<List<TransactionItem>>>(
      (ref) {
    final repo = ref.watch(dashboardRepositoryProvider);
    // get current userId from Hive
    final userId = Hive.box('authBox').get('userId', defaultValue: '');
    return RecentTransactionsNotifier(repo, userId);
  },
);

class RecentTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final DashboardRepository repository;
  final String userId;

  RecentTransactionsNotifier(this.repository, this.userId) : super(const AsyncLoading()) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    // 1️⃣ Load cached transactions first
    final cached = await TransactionStorage.getTransactions(userId);
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    try {
      // 2️⃣ Load from API in background
      final response = await repository.getRecentTransactions();
      if (response.responseSuccessful) {
        final transactions = response.transactions;

        // 3️⃣ Merge with cached (optional: if you want to keep old ones not in API)
        final merged = {
          for (var tx in [...cached, ...transactions]) tx.id: tx
        }.values.toList();

        state = AsyncData(merged);

        // 4️⃣ Save fresh transactions to local storage
        await TransactionStorage.saveTransactions(userId, merged);
      }
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncError(e, st);
      }
    }
  }
  /// Optional: force refresh manually
  Future<void> refresh() async {
    state = const AsyncLoading();
    await _loadTransactions();
  }
}