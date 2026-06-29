import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/local/transaction_cache.dart';
import '../dashboard_repo/repo.dart';
import '../model/deposit.dart';
import '../model/recent_transaction.dart';
import '../model/virtual_account_model.dart';
import '../model/services_status_model.dart';
import '../../auth/modal/reponse/response_modal.dart';

final userIdProvider = StateProvider<String>((ref) {
  final box = Hive.box('authBox');
  final userId = box.get('userId')?.toString() ?? '';
  final phone = box.get('phone')?.toString() ?? '';
  return userId.isNotEmpty ? userId : phone;
});

class UserProfileNotifier extends StateNotifier<UserResponse?> {
  UserProfileNotifier() : super(null) {
    _init();
  }

  void _init() {
    final box = Hive.box('authBox');
    final savedUserJson = box.get('saved_user_profile');
    if (savedUserJson != null) {
      try {
        state = UserResponse.fromJson(Map<String, dynamic>.from(savedUserJson));
      } catch (_) {}
    }
  }

  void updateProfile(UserResponse? user) {
    state = user;
    if (user != null) {
      final box = Hive.box('authBox');
      box.put('saved_user_profile', user.toJson());
      if (user.picture != null) box.put('picture', user.picture);
      if (user.fullname != null) box.put('fullname', user.fullname);
    }
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserResponse?>((ref) {
  return UserProfileNotifier();
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
      
      // ✅ Check if cached data is still fresh/valid before fetching over the network
      final isValid = await TransactionCache.isCacheValid(userId, suffix: 'recent');
      if (!isValid) {
        print('🔄 Cache expired, fetching fresh recent transactions in background.');
        _fetchFresh(silent: true);
      } else {
        print('⚡ Cache is valid, skipping redundant background fetch.');
      }
    } else {
      print('ℹ️ No recent transactions in cache, triggering initial fetch.');
      state = const AsyncValue.loading();
      await _fetchFresh(silent: false);
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

        if (!mounted) return;
        if (!silent || limited.length != (state.value?.length ?? 0)) {
          state = AsyncValue.data(limited);
        }

        // Save to RECENT bucket
        await TransactionCache.saveTransactions(userId, limited, suffix: 'recent');
      }
    } catch (e) {
      print('❌ Error fetching recent transactions: $e');
    } finally {
      if (mounted) _isFetching = false;
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
      
      // ✅ Check cache validity to prevent redundant network fetches
      final isValid = await TransactionCache.isCacheValid(userId, suffix: 'all');
      if (!isValid) {
        _currentPage = 1;
        _hasNextPage = true;
        _fetchFresh(silent: true, page: 1); // Background fetch
      } else {
        print('⚡ Cache is valid, skipping redundant background fetch for history.');
      }
    } else {
      state = const AsyncValue.loading();
      _currentPage = 1;
      _hasNextPage = true;
      await _fetchFresh(silent: false, page: 1);
    }
  }

  Future<void> _fetchFresh({bool silent = false, int page = 1}) async {
    if (_isFetching) return;
    if (!silent) {
      if (mounted) state = const AsyncValue.loading();
    }
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

        if (mounted) state = AsyncValue.data(sorted);
        
        // ✅ Save to ALL HISTORY bucket (merges automatically)
        await TransactionCache.saveTransactions(userId, sorted, suffix: 'all');
      } else {
        if (!silent || state.value == null) {
          if (mounted) state = AsyncValue.error('Failed to load transactions', StackTrace.current);
        }
      }
    } catch (e, st) {
      if (!silent || (state.value == null || state.value!.isEmpty)) {
        if (mounted) state = AsyncValue.error(e, st);
      }
    } finally {
      if (mounted) _isFetching = false;
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

// ──────────────────────────────────────────────────────────────────────────────
// VIRTUAL ACCOUNT PROVIDER
// ──────────────────────────────────────────────────────────────────────────────

class VirtualAccountNotifier extends StateNotifier<AsyncValue<VirtualAccountModel?>> {
  final DashboardRepository _repo;
  bool _isFetching = false;

  VirtualAccountNotifier(this._repo) : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    // ── 1. Show cached data instantly (zero loading) ──────────────────────────
    try {
      final box = Hive.box('authBox');
      final savedJson = box.get('virtual_account');
      if (savedJson != null) {
        final account = VirtualAccountModel.fromJson(
          Map<String, dynamic>.from(savedJson as Map),
        );
        state = AsyncValue.data(account);
        print('⚡ Virtual account loaded from cache: ${account.virtualAccountNo}');

        // ── 2. Silently refresh in background ────────────────────────────────
        Future.delayed(Duration.zero, _fetchOrGenerate);
        return;
      }
    } catch (e) {
      print('⚠️ Could not read virtual account cache: $e');
    }

    // ── 3. No cache — fetch/generate immediately ──────────────────────────────
    _fetchOrGenerate();
  }

  Future<void> _fetchOrGenerate() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      // Try fetching existing account first
      final existing = await _repo.getVirtualAccount();

      if (existing != null) {
        if (mounted) state = AsyncValue.data(existing);
        print('✅ Virtual account fetched from API: ${existing.virtualAccountNo}');
        return;
      }

      // No account found — auto-generate one
      print('⚙️ No virtual account found, generating one…');
      final generated = await _repo.generateVirtualAccount();

      if (mounted) state = AsyncValue.data(generated);
      if (generated != null) {
        print('🎉 Virtual account generated: ${generated.virtualAccountNo}');
      }
    } catch (e, st) {
      print('❌ VirtualAccountNotifier error: $e');
      // Keep existing cached data if any, don't override with error
      if (state.value == null && mounted) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }

  /// Manual refresh (e.g. from pull-to-refresh)
  Future<void> refresh() async {
    _isFetching = false;
    await _fetchOrGenerate();
  }
}

final virtualAccountProvider =
    StateNotifierProvider<VirtualAccountNotifier, AsyncValue<VirtualAccountModel?>>(
  (ref) {
    final repo = ref.watch(dashboardRepositoryProvider);
    return VirtualAccountNotifier(repo);
  },
);

// ──────────────────────────────────────────────────────────────────────────────
// SERVICES STATUS PROVIDER
// ──────────────────────────────────────────────────────────────────────────────

class ServicesStatusNotifier extends StateNotifier<ServicesStatus> {
  final DashboardRepository _repo;

  ServicesStatusNotifier(this._repo)
      : super(const ServicesStatus(
          airtime: true,
          data: true,
          utility: true,
          qr: true,
        )) {
    loadStatus();
  }

  Future<void> loadStatus() async {
    final status = await _repo.getServicesStatus();
    state = status;
  }

  void updateStatus(ServicesStatus status) {
    state = status;
  }
}

final servicesStatusProvider =
    StateNotifierProvider<ServicesStatusNotifier, ServicesStatus>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return ServicesStatusNotifier(repo);
});