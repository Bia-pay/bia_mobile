/// Represents the cashback rule returned by:
/// GET /api/user/billpayment/cashback/:serviceType
class CashbackRule {
  final int id;
  final String serviceType;

  /// 'PERCENTAGE' or 'FIXED'
  final String type;

  /// The reward amount (percentage value or fixed naira amount)
  final double amount;

  /// Maximum cashback that can be earned (naira, relevant for PERCENTAGE type)
  final double maxAmount;

  /// Minimum transaction amount required to earn cashback
  final double minTransaction;

  final bool isActive;

  const CashbackRule({
    required this.id,
    required this.serviceType,
    required this.type,
    required this.amount,
    required this.maxAmount,
    required this.minTransaction,
    required this.isActive,
  });

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final s = val.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  factory CashbackRule.fromJson(Map<String, dynamic> json) {
    return CashbackRule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serviceType: json['serviceType']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'FIXED',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      maxAmount: double.tryParse(json['maxAmount']?.toString() ?? '') ?? 0.0,
      minTransaction:
          double.tryParse(json['minTransaction']?.toString() ?? '') ?? 0.0,
      isActive: _parseBool(json['isActive']),
    );
  }

  /// Compute the cashback a user earns for a given [transactionAmount] based on Admin API config.
  double computeEarned(double transactionAmount) {
    if (!isActive) return 0.0;
    if (minTransaction > 0 && transactionAmount < minTransaction) return 0.0;

    if (type == 'PERCENTAGE') {
      final earned = transactionAmount * (amount / 100);
      return maxAmount > 0 ? earned.clamp(0, maxAmount) : earned;
    }
    // FIXED
    return amount;
  }

  /// Returns display string dynamically based on live Admin API rule.
  String displayLabel({double? transactionAmount}) {
    if (!isActive) return '';

    if (transactionAmount != null && transactionAmount > 0) {
      final earned = computeEarned(transactionAmount);
      if (earned > 0) {
        return '+₦${earned.toStringAsFixed(2)} Cashback';
      }
      // If transaction is below minTransaction, show admin rule offer rate
      if (type == 'PERCENTAGE' && amount > 0) {
        return '+${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}% Cashback';
      }
      if (amount > 0) {
        return '+₦${amount.toStringAsFixed(2)} Cashback';
      }
    }

    // Generic label preview from admin rule
    if (type == 'PERCENTAGE') {
      return '+${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}% Cashback';
    }
    return '+₦${amount.toStringAsFixed(2)} Cashback';
  }
}
