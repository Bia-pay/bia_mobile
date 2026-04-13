import 'dart:convert';
import 'package:hive/hive.dart';
import '../../feature/dashboard/model/recent_transaction.dart';

class TransactionCache {
  static const String _boxName = 'transactionCacheBox';
  static const String _lastUserKey = '_last_cached_user_id';

  static String _transactionsKey(String userId) => 'transactions_$userId';
  static String _timestampKey(String userId) => 'transactions_timestamp_$userId';

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
      List<TransactionItem> transactions,
      ) async {
    if (userId.isEmpty) return;

    final box = await _box();

    // Double-check we're still caching for the same user
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != null && currentUser != userId) {
      print('⚠️ User mismatch detected during save. Clearing cache...');
      await box.clear();
      await box.put(_lastUserKey, userId);
    }

    final jsonList = transactions.map((e) => e.toJson()).toList();

    await box.put(_transactionsKey(userId), jsonEncode(jsonList));
    await box.put(
      _timestampKey(userId),
      DateTime.now().millisecondsSinceEpoch,
    );
    print('💾 Saved ${transactions.length} transactions for user: $userId');
  }

  static Future<List<TransactionItem>> getTransactions(String userId) async {
    if (userId.isEmpty) return [];

    final box = await _box();

    // Verify we're reading for the correct user
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != null && currentUser != userId) {
      print('🚨 SECURITY: Attempted to read transactions for wrong user!');
      return [];
    }

    final raw = box.get(_transactionsKey(userId));
    print("📦 Loading cache for user: $userId");

    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ Cache decode error: $e');
      return [];
    }
  }

  static Future<bool> isCacheValid(String userId) async {
    if (userId.isEmpty) return false;

    final box = await _box();

    // Verify user matches
    final currentUser = box.get(_lastUserKey) as String?;
    if (currentUser != userId) {
      print('⚠️ Cache invalid - user mismatch');
      return false;
    }

    final timestamp = box.get(_timestampKey(userId));
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheTime).inMinutes < 10;
  }

  static Future<void> clearTransactions(String userId) async {
    if (userId.isEmpty) return;

    final box = await _box();
    await box.delete(_transactionsKey(userId));
    await box.delete(_timestampKey(userId));
  }

  static Future<void> clearAllTransactions() async {
    final box = await _box();
    await box.clear();
    print('🗑️ All transaction caches cleared');
  }
}