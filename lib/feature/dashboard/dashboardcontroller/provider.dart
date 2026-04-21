import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/local/transaction_cache.dart';
import '../dashboard_repo/repo.dart';
import '../model/deposit.dart';
import '../model/recent_transaction.dart';

final userIdProvider = StateProvider<String>((ref) => '');
class RecentTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final DashboardRepository repository;
  final String userId;
  bool _isFetching = false;
  bool _initialized = false;

  RecentTransactionsNotifier(this.repository, this.userId)
      : super(const AsyncValue.loading()) {
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

    // 🔥 Check if we have fresh pre-loaded cache first
    final hasValidCache = await TransactionCache.isCacheValid(userId);
    final cached = await TransactionCache.getTransactions(userId);

    if (cached.isNotEmpty && hasValidCache) {
      print('✅ Using pre-loaded cache with ${cached.length} transactions');
      state = AsyncValue.data(cached);
      // Still refresh in background but silently
      _fetchFresh(silent: true);
    } else if (cached.isNotEmpty) {
      // Cache exists but stale - show it while refreshing
      print('⏰ Stale cache found, showing while refreshing');
      state = AsyncValue.data(cached);
      await _fetchFresh(silent: false);
    } else {
      // No cache - must fetch
      print('📭 No cache found, fetching fresh data');
      state = const AsyncValue.loading();
      await _fetchFresh(silent: false);
    }
  }

  Future<void> _fetchFresh({bool silent = false}) async {
    if (_isFetching) {
      print('⚠️ Already fetching, skipping...');
      return;
    }

    _isFetching = true;

    try {
      print('📡 Fetching fresh transactions from API...');
      final response = await repository.getRecentTransactions();

      if (response.responseSuccessful) {
        final fresh = response.transactions;
        print('✅ Received ${fresh.length} transactions from API');

        // Merge with existing data to avoid duplicates
        final Map<int, TransactionItem> map = {};

        // Add existing transactions
        for (var tx in state.value ?? []) {
          map[tx.id] = tx;
        }

        // Add/update with fresh transactions
        for (var tx in fresh) {
          map[tx.id] = tx;
        }

        // Sort by date (newest first)
        final merged = map.values.toList()
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        // Limit to recent 50 transactions
        final limited = merged.take(50).toList();

        // Update UI only if not silent or if we have new data
        if (!silent || limited.length != (state.value?.length ?? 0)) {
          state = AsyncValue.data(limited);
        }

        // Save to cache
        await TransactionCache.saveTransactions(userId, limited);
        print('💾 Saved ${limited.length} transactions to cache');
      } else {
        print('⚠️ API returned unsuccessful response');
        if (!silent && state.value == null) {
          state = AsyncValue.error(
            'Failed to load transactions',
            StackTrace.current,
          );
        }
      }
    } catch (e, st) {
      print('❌ Error fetching transactions: $e');
      // Only show error if we don't have cached data
      if (!silent && (state.value == null || state.value!.isEmpty)) {
        state = AsyncValue.error(e, st);
      }
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
    await TransactionCache.clearTransactions(userId);
    state = const AsyncValue.loading();
    await _fetchFresh(silent: false);
  }
}
final recentTransactionsProvider =
StateNotifierProvider.family<RecentTransactionsNotifier,
    AsyncValue<List<TransactionItem>>, String>((ref, userId) {

  final repo = ref.watch(dashboardRepositoryProvider);
  return RecentTransactionsNotifier(repo, userId);
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
    print('🔄 Initializing transactions for user: $userId');

    if (userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    // 🔥 ALWAYS LOAD USER-SPECIFIC CACHE
    final cached = await TransactionCache.getTransactions(userId);

    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    // 🔥 ALWAYS FETCH FRESH DATA FOR NEW USER (Page 1)
    _currentPage = 1;
    _hasNextPage = true;
    await _fetchFresh(silent: cached.isNotEmpty, page: 1);
  }

  Future<void> _fetchFresh({bool silent = false, int page = 1}) async {
    if (_isFetching) return;
    
    if (!silent) {
      state = const AsyncValue.loading();
    }
    
    _isFetching = true;

    try {
      print('📡 Fetching transactions (Page $page) from API...');
      final response = await repository.getTransactions(page: page, limit: _pageSize);

      if (response.responseSuccessful) {
        final fresh = response.transactions;
        print('✅ Received ${fresh.length} transactions for page $page');

        _hasNextPage = fresh.length == _pageSize;
        _currentPage = page;

        // DISCRETE PAGINATION: Replace current list with fresh page data
        // Sort by date (usually the API should handle this, but for safety)
        final sorted = fresh
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        state = AsyncValue.data(sorted);
        
        // Cache only page 1 for the dashboard preview
        if (page == 1) {
          await TransactionCache.saveTransactions(userId, sorted.take(20).toList());
          print('💾 Cached top 20 transactions');
        }
      } else {
        if (!silent || state.value == null) {
          state = AsyncValue.error(
            'Failed to load transactions',
            StackTrace.current,
          );
        }
      }
    } catch (e, st) {
      print('❌ Error fetching transactions: $e');
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