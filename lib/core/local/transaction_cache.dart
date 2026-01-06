import 'package:hive/hive.dart';
import '../../feature/dashboard/model/recent_transaction.dart';

/// Improved transaction caching with timestamp and expiration
class TransactionCache {
  static const _boxName = 'transactionsCache';
  static const _cacheExpirationMinutes = 30; // Cache expires after 30 minutes

  /// Save transactions with timestamp
  static Future<void> saveTransactions(
    String userId,
    List<TransactionItem> transactions,
  ) async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = {
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': transactions.length,
      };
      await box.put('tx_$userId', data);
      print('💾 Cached ${transactions.length} transactions for user $userId');
    } catch (e) {
      print('❌ Error saving transactions to cache: $e');
    }
  }

  /// Load transactions from cache
  static Future<List<TransactionItem>> getTransactions(String userId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('tx_$userId');

      if (data == null) {
        print('📭 No cached transactions for user $userId');
        return [];
      }

      if (data is! Map) {
        print('⚠️ Invalid cache format, clearing...');
        await clearTransactions(userId);
        return [];
      }

      final transactions = data['transactions'] as List?;
      if (transactions == null || transactions.isEmpty) {
        return [];
      }

      final cached = transactions
          .map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      print('📦 Loaded ${cached.length} cached transactions for user $userId');
      return cached;
    } catch (e) {
      print('❌ Error loading transactions from cache: $e');
      return [];
    }
  }

  /// Check if cache is still valid (not expired)
  static Future<bool> isCacheValid(String userId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('tx_$userId');

      if (data == null || data is! Map) return false;

      final timestamp = data['timestamp'] as int?;
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      final isValid = difference.inMinutes < _cacheExpirationMinutes;
      
      if (!isValid) {
        print('⏰ Cache expired (${difference.inMinutes} minutes old)');
      }

      return isValid;
    } catch (e) {
      print('❌ Error checking cache validity: $e');
      return false;
    }
  }

  /// Get cache age in minutes
  static Future<int?> getCacheAge(String userId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('tx_$userId');

      if (data == null || data is! Map) return null;

      final timestamp = data['timestamp'] as int?;
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      return now.difference(cacheTime).inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Clear transactions for specific user
  static Future<void> clearTransactions(String userId) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete('tx_$userId');
      print('🗑️ Cleared transaction cache for user $userId');
    } catch (e) {
      print('❌ Error clearing transactions: $e');
    }
  }

  /// Clear all transaction caches
  static Future<void> clearAllCaches() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.clear();
      print('🗑️ Cleared all transaction caches');
    } catch (e) {
      print('❌ Error clearing all caches: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats(String userId) async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('tx_$userId');

      if (data == null || data is! Map) {
        return {
          'hasCa': false,
          'count': 0,
          'ageMinutes': null,
          'isValid': false,
        };
      }

      final timestamp = data['timestamp'] as int?;
      final count = data['count'] as int? ?? 0;
      final ageMinutes = timestamp != null
          ? DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
              .inMinutes
          : null;

      return {
        'hasCache': true,
        'count': count,
        'ageMinutes': ageMinutes,
        'isValid': await isCacheValid(userId),
      };
    } catch (e) {
      return {
        'hasCache': false,
        'count': 0,
        'ageMinutes': null,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
}
