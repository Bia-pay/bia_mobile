import 'dart:convert';
import 'package:hive/hive.dart';
import '../../feature/dashboard/model/recent_transaction.dart';

class TransactionCache {
  static const String _boxName = 'transactionCacheBox';
  static const String _lastUserKey = '_last_cached_user_id';

  static String _transactionsKey(String userId, [String suffix = 'all']) => 'transactions_${suffix}_$userId';
  static String _timestampKey(String userId, [String suffix = 'all']) => 'transactions_timestamp_${suffix}_$userId';

  static Future<Box> _box() async => await Hive.openBox(_boxName);

  /// CRITICAL: Call this immediately on login to ensure clean slate for new user
  static Future<void> prepareForNewUser(String newUserId) async {
    if (newUserId.isEmpty) return;

    final box = await _box();
    final lastUserId = box.get(_lastUserKey) as String?;

    // If different user is logging in, clear EVERYTHING immediately
    if (lastUserId != null && lastUserId != newUserId) {
      print('🔐 Different user detected. Clearing all old transaction caches...');
      await box.clear();
    }

    // Mark this user as the current cached user
    await box.put(_lastUserKey, newUserId);
  }

  static Future<void> saveTransactions(
      String userId,
      List<TransactionItem> transactions, {
      String suffix = 'all',
      }) async {
    if (userId.isEmpty) return;

    final box = await _box();

    // Double-check we're still caching for the same user
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != null && currentUser != userId) {
      print('⚠️ User mismatch detected during save. Clearing cache...');
      await box.clear();
      await box.put(_lastUserKey, userId);
    }

    // 1. Load existing transactions for this specific suffix
    final existingRaw = box.get(_transactionsKey(userId, suffix));
    List<TransactionItem> mergedList = [];
    
    if (existingRaw != null) {
      try {
        final decoded = jsonDecode(existingRaw) as List;
        mergedList = decoded
            .map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        print('❌ Previous cache ($suffix) read error: $e');
      }
    }

    // 2. Merge logic using a Map with a composite key to handle de-duplication
    // We prioritize 'reference' as it is more reliable across different API endpoints
    final Map<String, TransactionItem> map = {
      for (var tx in mergedList) 
        (tx.reference ?? tx.id.toString()): tx,
    };
    
    // Add/Update with new transactions
    for (var tx in transactions) {
      map[tx.reference ?? tx.id.toString()] = tx;
    }

    // 3. Sort by date (newest first)
    final finalSortedList = map.values.toList()
      ..sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    // 4. Limit based on suffix type
    final limit = suffix == 'recent' ? 2 : 200;
    final limitedList = finalSortedList.take(limit).toList();

    final jsonList = limitedList.map((e) => e.toJson()).toList();
    
    print('💾 SAVING TO DISK ($suffix): ${limitedList.length} total items.');

    await box.put(_transactionsKey(userId, suffix), jsonEncode(jsonList));
    await box.put(
      _timestampKey(userId, suffix),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<List<TransactionItem>> getTransactions(String userId, {String suffix = 'all'}) async {
    if (userId.isEmpty) return [];

    final box = await _box();

    // Verify we're reading for the correct user
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != null && currentUser != userId) {
      print('🚨 SECURITY: Attempted to read transactions for wrong user!');
      return [];
    }

    final raw = box.get(_transactionsKey(userId, suffix));
    
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      final cached = decoded
          .map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      
      print('📦 Loaded $suffix cache for user $userId: ${cached.length} items');
      return cached;
    } catch (e) {
      print('❌ Cache decode error ($suffix): $e');
      return [];
    }
  }

  /// Synchronous retrieval for zero-flicker UI initialization
  static List<TransactionItem> getTransactionsSync(String userId, {String suffix = 'all'}) {
    if (userId.isEmpty || !Hive.isBoxOpen(_boxName)) return [];

    final box = Hive.box(_boxName);

    // Verify user matches
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != null && currentUser != userId) return [];

    final raw = box.get(_transactionsKey(userId, suffix));
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ Sync cache decode error ($suffix): $e');
      return [];
    }
  }

  static Future<bool> isCacheValid(String userId, {String suffix = 'all'}) async {
    if (userId.isEmpty) return false;

    final box = await _box();

    // Verify user matches
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != userId) return false;

    final timestamp = box.get(_timestampKey(userId, suffix));
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    // Recent cache is valid for 5 mins, History for 15 mins
    final validDuration = suffix == 'recent' ? 5 : 15;
    return now.difference(cacheTime).inMinutes < validDuration;
  }

  static Future<void> clearTransactions(String userId, {String suffix = 'all'}) async {
    if (userId.isEmpty) return;

    final box = await _box();
    await box.delete(_transactionsKey(userId, suffix));
    await box.delete(_timestampKey(userId, suffix));
  }

  static Future<void> clearAllTransactions() async {
    final box = await _box();
    await box.clear();
    print('🗑️ All transaction caches cleared');
  }
}