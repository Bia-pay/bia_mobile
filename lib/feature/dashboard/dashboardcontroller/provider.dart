import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/local/transaction_cache.dart';
import '../dashboard_repo/repo.dart';
import '../model/deposit.dart';
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

class AllTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final DashboardRepository repository;
  final String userId;
  bool _isFetching = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  final int _pageSize = 20;

  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _currentPage > 1;

  AllTransactionsNotifier(this.repository, this.userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    // 🔥 ALWAYS LOAD USER-SPECIFIC HISTORY CACHE (All Bucket)
    final cached = await TransactionCache.getTransactions(userId, suffix: 'all');

    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    _currentPage = 1;
    _hasNextPage = true;
    _fetchFresh(silent: cached.isNotEmpty, page: 1); // Background fetch
  }

  Future<void> _fetchFresh({bool silent = false, int page = 1}) async {
    if (_isFetching) return;
    if (!silent) state = const AsyncValue.loading();
    _isFetching = true;

    try {
      final response = await repository.
      getTransactions(page: page, limit: _pageSize);

      if (response.responseSuccessful) {
        final fresh = response.transactions;
        _hasNextPage = fresh.length == _pageSize;
        _currentPage = page;

        final sorted = fresh
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        state = AsyncValue.data(sorted);
        
        // ✅ Save to ALL HISTORY bucket (merges automatically)
        await TransactionCache.saveTransactions(userId, sorted, suffix: 'all');
      } else {
        if (!silent || state.value == null) {
          state = AsyncValue.error('Failed to load transactions', StackTrace.current);
        }
      }
    } catch (e, st) {
      if (!silent || (state.value == null || state.value!.isEmpty)) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> nextPage() async {
    if (_isFetching || !_hasNextPage) return;
    await _fetchFresh(silent: false, page: _currentPage + 1);
  }

  Future<void> previousPage() async {
    if (_isFetching || _currentPage <= 1) return;
    await _fetchFresh(silent: false, page: _currentPage - 1);
  }

  Future<void> refresh() async {
    print('🔄 Manual refresh all transactions');
    _currentPage = 1;
    _hasNextPage = true;
    await _fetchFresh(silent: false, page: 1);
  }
}

final allTransactionsProvider =
StateNotifierProvider.autoDispose.family<
    AllTransactionsNotifier,
    AsyncValue<List<TransactionItem>>,
    String>((ref, userId) {

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