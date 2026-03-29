import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import '../../../core/local/transaction_cache.dart';
import '../dashboard_repo/repo.dart';
import '../model/deposit.dart';
import '../model/recent_transaction.dart';

final recentTransactionsProvider =
StateNotifierProvider<RecentTransactionsNotifier, AsyncValue<List<TransactionItem>>>(
      (ref) {
    final repo = ref.watch(dashboardRepositoryProvider);
    final userId = Hive.box('authBox').get('userId', defaultValue: '');
    return RecentTransactionsNotifier(repo, userId);
  },
);

class RecentTransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final DashboardRepository repository;
  final String userId;
  bool _isFetching = false;

  RecentTransactionsNotifier(this.repository, this.userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    print('🔄 Initializing recent transactions for user: $userId');
    
    // 1️⃣ Load cached transactions immediately (instant UI)
    final cached = await TransactionCache.getTransactions(userId);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
      print('✅ Showing ${cached.length} cached transactions');
    }

    // 2️⃣ Check if cache is still valid
    final isCacheValid = await TransactionCache.isCacheValid(userId);
    
    if (!isCacheValid) {
      print('🔄 Cache expired or invalid, fetching fresh data...');
      await _fetchFresh(silent: cached.isNotEmpty);
    } else {
      print('✅ Cache is valid, fetching in background...');
      // Fetch in background without blocking UI
      _fetchFresh(silent: true);
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

        // Update UI
        state = AsyncValue.data(limited);
        
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

  AllTransactionsNotifier(this.repository, this.userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    print('🔄 Initializing all transactions for user: $userId');
    
    // Load from cache immediately
    final cached = await TransactionCache.getTransactions(userId);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
      print('✅ Showing ${cached.length} cached transactions');
    }

    // Check cache validity
    final isCacheValid = await TransactionCache.isCacheValid(userId);
    
    if (!isCacheValid) {
      await _fetchFresh(silent: cached.isNotEmpty);
    } else {
      _fetchFresh(silent: true);
    }
  }

  Future<void> _fetchFresh({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      print('📡 Fetching all transactions from API...');
      final response = await repository.getTransactions();

      if (response.responseSuccessful) {
        final fresh = response.transactions;
        print('✅ Received ${fresh.length} transactions from API');

        // Merge with existing
        final Map<int, TransactionItem> map = {};
        for (var tx in state.value ?? []) map[tx.id] = tx;
        for (var tx in fresh) map[tx.id] = tx;

        // Sort by date
        final merged = map.values.toList()
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });

        // Limit to 1000 transactions
        final limited = merged.take(1000).toList();

        state = AsyncValue.data(limited);
        await TransactionCache.saveTransactions(userId, limited);
        print('💾 Saved ${limited.length} transactions to cache');
      } else {
        if (!silent && state.value == null) {
          state = AsyncValue.error(
            'Failed to load transactions',
            StackTrace.current,
          );
        }
      }
    } catch (e, st) {
      print('❌ Error fetching all transactions: $e');
      if (!silent && (state.value == null || state.value!.isEmpty)) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    print('🔄 Manual refresh all transactions');
    await _fetchFresh(silent: false);
  }
}
final allTransactionsProvider =
StateNotifierProvider<AllTransactionsNotifier, AsyncValue<List<TransactionItem>>>(
      (ref) {
    final repo = ref.watch(dashboardRepositoryProvider);
    final userId = Hive.box('authBox').get('userId', defaultValue: '');
    return AllTransactionsNotifier(repo, userId);
  },
);
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