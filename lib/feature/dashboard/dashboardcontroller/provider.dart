import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/local/transaction_cache.dart';
import '../dashboard_repo/repo.dart';
import '../model/deposit.dart';
import '../model/pagination_model.dart';
import '../model/recent_transaction.dart';

final userIdProvider = StateProvider<String>((ref) {
  final box = Hive.box('authBox');
  final userId = box.get('userId')?.toString() ?? '';
  final phone = box.get('phone')?.toString() ?? '';
  return userId.isNotEmpty ? userId : phone;
});
class RecentTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final DashboardRepository repository;
  final String userId;
  bool _isFetching = false;
  bool _initialized = false;

  RecentTransactionsNotifier(this.repository, this.userId, {List<TransactionItem>? initialData})
      : super(AsyncValue.data(initialData ?? [])) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    print('🔄 Initializing transactions for user: $userId');

    if (userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    // 🔥 Check if we have pre-loaded cache first (Recent Bucket)
    final cached = await TransactionCache.getTransactions(userId, suffix: 'recent');

    if (cached.isNotEmpty) {
      print('✅ Using RECENT cache with ${cached.length} items');
      state = AsyncValue.data(cached);
    } else {
      // If empty, we stay at data([]) to avoid showing a spinner.
      // THE FIX: We NO LONGER trigger an automatic _fetchFresh here.
      // Data will appear when the user manual refreshes, 
      // or it should have been primed by login.
      print('ℹ️ No recent transactions in cache, waiting for manual refresh.');
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _fetchFresh({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final response = await repository.getRecentTransactions();

      if (response.responseSuccessful) {
        final fresh = response.transactions;

        final Map<String, TransactionItem> map = {};
        for (var tx in state.value ?? []) {
          map[tx.reference ?? tx.id.toString()] = tx;
        }
        for (var tx in fresh) {
          map[tx.reference ?? tx.id.toString()] = tx;
        }

        final merged = map.values.toList()
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        final limited = merged.take(2).toList();

        if (!silent || limited.length != (state.value?.length ?? 0)) {
          state = AsyncValue.data(limited);
        }

        // Save to RECENT bucket
        await TransactionCache.saveTransactions(userId, limited, suffix: 'recent');
      }
    } catch (e) {
      print('❌ Error fetching recent transactions: $e');
    } finally {
      _isFetching = false;
    }
  }

  /// Manual refresh (pull-to-refresh)
  Future<void> refresh() async {
    print('🔄 Manual refresh triggered');
    await _fetchFresh(silent: false);
  }

  /// Force refresh (clears cache and fetches)
  Future<void> forceRefresh() async {
    print('🔄 Force refresh triggered');
    await TransactionCache.clearTransactions(userId, suffix: 'recent');
    state = const AsyncValue.loading();
    await _fetchFresh(silent: false);
  }
}
final recentTransactionsProvider =
    StateNotifierProvider.family<RecentTransactionsNotifier,
        AsyncValue<List<TransactionItem>>, String>((ref, userId) {
  final repo = ref.watch(dashboardRepositoryProvider);
  
  // 🔥 Sync check: Grab data instantly before the first frame builds
  final cached = TransactionCache.getTransactionsSync(userId, suffix: 'recent');
  
  return RecentTransactionsNotifier(repo, userId, initialData: cached);
});


final depositProvider = FutureProvider.family<DepositResponseModel, double>(
      (ref, amount) {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.depositMoney({"amount": amount});
  },
);

class TransactionHistoryState {
  final List<TransactionItem> transactions;
  final bool isLoading;
  final bool isLoadMore;
  final String? error;
  final Pagination? pagination;

  TransactionHistoryState({
    required this.transactions,
    this.isLoading = false,
    this.isLoadMore = false,
    this.error,
    this.pagination,
  });

  TransactionHistoryState copyWith({
    List<TransactionItem>? transactions,
    bool? isLoading,
    bool? isLoadMore,
    String? error,
    Pagination? pagination,
  }) {
    return TransactionHistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }
}

class AllTransactionsNotifier extends StateNotifier<TransactionHistoryState> {
  final DashboardRepository repository;
  final String userId;
  final int _pageSize = 20;

  AllTransactionsNotifier(this.repository, this.userId)
      : super(TransactionHistoryState(transactions: [])) {
    _init();
  }

  Future<void> _init() async {
    if (userId.isEmpty) return;

    // 🔥 ALWAYS LOAD USER-SPECIFIC HISTORY CACHE (All Bucket)
    final cached = await TransactionCache.getTransactions(userId, suffix: 'all');

    if (cached.isNotEmpty) {
      state = state.copyWith(transactions: cached);
    } else {
      state = state.copyWith(isLoading: true);
    }

    refresh(); // Initial fetch
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await repository.getTransactions(page: 1, limit: _pageSize);

      if (response.responseSuccessful) {
        final sorted = response.transactions
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        state = state.copyWith(
          transactions: sorted,
          pagination: response.pagination,
          isLoading: false,
        );

        // ✅ Save to ALL HISTORY bucket
        await TransactionCache.saveTransactions(userId, sorted, suffix: 'all');
      } else {
        state = state.copyWith(isLoading: false, error: response.responseMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadMore || state.pagination == null) return;
    if (state.pagination!.page >= state.pagination!.totalPages) return;

    state = state.copyWith(isLoadMore: true);
    final nextPage = state.pagination!.page + 1;

    try {
      final response = await repository.getTransactions(page: nextPage, limit: _pageSize);

      if (response.responseSuccessful) {
        final fresh = response.transactions;
        final merged = [...state.transactions, ...fresh]..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        state = state.copyWith(
          transactions: merged,
          pagination: response.pagination,
          isLoadMore: false,
        );

        // ✅ Save to ALL HISTORY bucket
        await TransactionCache.saveTransactions(userId, merged, suffix: 'all');
      } else {
        state = state.copyWith(isLoadMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadMore: false);
    }
  }
}

final allTransactionsProvider = StateNotifierProvider.autoDispose
    .family<AllTransactionsNotifier, TransactionHistoryState, String>((ref, userId) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return AllTransactionsNotifier(repo, userId);
});


final balanceVisibilityProvider = StateProvider<bool>((ref) => true);

final electricityProviderListProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return repo.getElectricityProviders();
});

final verifyMeterProvider = FutureProvider.family<
    Map<String, dynamic>?, Map<String, String>>((ref, params) async {
  final repo = ref.read(dashboardRepositoryProvider);

  return repo.verifyElectricityMeter(
    serviceId: params['serviceId']!,
    meterNumber: params['meter']!,
    type: params['type']!,
  );
});