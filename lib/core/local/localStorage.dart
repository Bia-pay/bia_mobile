import 'package:hive/hive.dart';
import '../../feature/dashboard/model/recent_transaction.dart';
import 'dart:convert';

import '../../feature/dashboard/model/recent_transfer.dart';

class TransactionStorage {
  static const _boxName = 'transactionsBox';

  // 🔹 Save transactions per user
  static Future<void> saveTransactions(String userId, List<TransactionItem> transactions) async {
    final box = await Hive.openBox(_boxName);
    final data = transactions.map((e) => e.toJson()).toList();
    await box.put('transactions_$userId', data); // ✅ keyed by userId
  }

  // 🔹 Load transactions per user
  static Future<List<TransactionItem>> getTransactions(String userId) async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get('transactions_$userId', defaultValue: <dynamic>[]);
    if (saved is List) {
      return saved.map((e) => TransactionItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  // 🔹 Clear transactions per user
  static Future<void> clearTransactions(String userId) async {
    final box = await Hive.openBox(_boxName);
    await box.delete('transactions_$userId'); // ✅ use the correct key
  }

  // 🔹 Save beneficiaries per user
  static Future<void> saveBeneficiaries(String userId, List<RecentBeneficiaryItem> beneficiaries) async {
    final box = await Hive.openBox(_boxName);
    final jsonList = beneficiaries.map((b) => jsonEncode(b.toJson())).toList();
    await box.put('beneficiaries_$userId', jsonList); // ✅ keyed by userId
  }

  // 🔹 Load beneficiaries per user
  static Future<List<RecentBeneficiaryItem>> getBeneficiaries(String userId) async {
    final box = await Hive.openBox(_boxName);
    final savedJson = box.get('beneficiaries_$userId', defaultValue: <String>[]);
    return (savedJson as List)
        .map((e) => RecentBeneficiaryItem.fromJson(jsonDecode(e)))
        .toList();
  }

  // 🔹 Clear beneficiaries per user
  static Future<void> clearBeneficiaries(String userId) async {
    final box = await Hive.openBox(_boxName);
    await box.delete('beneficiaries_$userId'); // ✅ use correct key
  }
}