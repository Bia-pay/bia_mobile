import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import '../../../core/local/localStorage.dart';
import '../dashboard_repo/repo.dart';
import '../model/recent_transaction.dart';

final recentTransactionsProvider =
StateNotifierProvider<RecentTransactionsNotifier, AsyncValue<List<TransactionItem>>>(
      (ref) {
    final repo = ref.watch(dashboardRepositoryProvider);

    // Load actual logged-in user ID from Hive
    final userId = Hive.box('authBox').get('userId', defaultValue: '');

    return RecentTransactionsNotifier(repo, userId);
  },
);

class RecentTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final DashboardRepository repository;
  final String userId;

  RecentTransactionsNotifier(this.repository, this.userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // 1️⃣ Load cached transactions immediately
    final cached = await TransactionStorage.getTransactions(userId);
    state = AsyncValue.data(cached);

    // 2️⃣ Fetch fresh in the background
    _fetchFresh();
  }

  Future<void> _fetchFresh() async {
    try {
      final response = await repository.getRecentTransactions();

      if (response.responseSuccessful) {
        final fresh = response.transactions;

        // Merge with local cache
        final Map<int, TransactionItem> map = {};
        for (var tx in state.value ?? []) map[tx.id] = tx;
        for (var tx in fresh) map[tx.id] = tx;

        // Get all transactions, sorted by createdAt descending
        final merged = map.values.toList()
          ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

        // Limit to recent 3
        final limited = merged.take(3).toList();

        // Update UI and cache
        state = AsyncValue.data(limited);
        await TransactionStorage.saveTransactions(userId, limited);
      }
    } catch (e, st) {
      if (state is! AsyncData) state = AsyncValue.error(e, st);
    }
  }
  Future<void> refresh() async => _fetchFresh();
}