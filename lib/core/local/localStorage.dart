import 'package:hive/hive.dart';
import '../../feature/dashboard/model/recent_transaction.dart';
import 'dart:convert';

import '../../feature/dashboard/model/recent_transfer.dart';

class TransactionStorage {
  static const _boxName = 'transactionsBox';

  /// Save transactions for a specific user
  static Future<void> saveTransactions(String userId, List<TransactionItem> transactions) async {
    final box = await Hive.openBox(_boxName);
    final txJson = transactions.map((tx) => jsonEncode({
      'id': tx.id,
      'type': tx.type,
      'serviceType': tx.serviceType,
      'amount': tx.amount,
      'isCredit': tx.isCredit,
      'description': tx.description,
      'createdAt': tx.createdAt,
      'senderName': tx.senderName,
      'receiverName': tx.receiverName,
    })).toList();

    await box.put(userId, txJson);
  }

  /// Get saved transactions for a specific user
  static Future<List<TransactionItem>> getTransactions(String userId) async {
    final box = await Hive.openBox(_boxName);
    final txJson = box.get(userId, defaultValue: <String>[]);
    return (txJson as List).map((e) {
      final map = jsonDecode(e);
      return TransactionItem.fromJson(map);
    }).toList();
  }
  static Future<void> saveBeneficiaries(String userId, List<RecentBeneficiaryItem> beneficiaries) async {
    final box = await Hive.openBox(_boxName);
    final jsonList = beneficiaries.map((b) => jsonEncode(b.toJson())).toList();
    await box.put(userId, jsonList);
  }

  /// Get saved beneficiaries for a specific user
  static Future<List<RecentBeneficiaryItem>> getBeneficiaries(String userId) async {
    final box = await Hive.openBox(_boxName);
    final savedJson = box.get(userId, defaultValue: <String>[]);
    return (savedJson as List)
        .map((e) => RecentBeneficiaryItem.fromJson(jsonDecode(e)))
        .toList();
  }

  /// Clear beneficiaries for a specific user
  static Future<void> clearBeneficiaries(String userId) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(userId);
  }
}