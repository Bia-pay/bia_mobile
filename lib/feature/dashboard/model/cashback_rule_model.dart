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

  factory CashbackRule.fromJson(Map<String, dynamic> json) {
    return CashbackRule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      serviceType: json['serviceType']?.toString() ?? '',
      type: json['type']?.toString() ?? 'FIXED',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      maxAmount: double.tryParse(json['maxAmount']?.toString() ?? '') ?? 0.0,
      minTransaction:
          double.tryParse(json['minTransaction']?.toString() ?? '') ?? 0.0,
      isActive: json['isActive'] == true,
    );
  }

  /// Compute the cashback a user earns for a given [transactionAmount].
  /// Returns 0 if the rule is inactive or the amount is below [minTransaction].
  double computeEarned(double transactionAmount) {
    if (!isActive || transactionAmount < minTransaction) return 0.0;
    if (type == 'PERCENTAGE') {
      final earned = transactionAmount * (amount / 100);
      return maxAmount > 0 ? earned.clamp(0, maxAmount) : earned;
    }
    // FIXED
    return amount;
  }

  /// Returns a display string like "+₦1.00 Cashback" or "+1% Cashback".
  String displayLabel({double? transactionAmount}) {
    if (!isActive) return '';
    if (transactionAmount != null) {
      final earned = computeEarned(transactionAmount);
      if (earned <= 0) return '';
      return '+₦${earned.toStringAsFixed(2)} Cashback';
    }
    // Generic label when amount not known yet
    if (type == 'PERCENTAGE') {
      return '+${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}% Cashback';
    }
    return '+₦${amount.toStringAsFixed(2)} Cashback';
  }
}
