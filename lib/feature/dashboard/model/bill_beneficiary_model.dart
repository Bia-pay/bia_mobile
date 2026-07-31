class BillBeneficiaryItem {
  final int id;
  final int? userId;
  final String serviceType;
  final String destination;
  final String name;
  final String? provider;
  final String createdAt;
  final String? updatedAt;

  BillBeneficiaryItem({
    required this.id,
    this.userId,
    required this.serviceType,
    required this.destination,
    required this.name,
    this.provider,
    required this.createdAt,
    this.updatedAt,
  });

  factory BillBeneficiaryItem.fromJson(Map<String, dynamic> json) {
    return BillBeneficiaryItem(
      id: json['id'] ?? 0,
      userId: json['userId'],
      serviceType: json['serviceType'] ?? '',
      destination: json['destination'] ?? '',
      name: json['name'] ?? '',
      provider: json['provider'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }
}

class RecentBillPaymentItem {
  final int id;
  final String serviceType;
  final String destination;
  final double amount;
  final String? provider;
  final String createdAt;

  RecentBillPaymentItem({
    required this.id,
    required this.serviceType,
    required this.destination,
    required this.amount,
    this.provider,
    required this.createdAt,
  });

  factory RecentBillPaymentItem.fromJson(Map<String, dynamic> json) {
    return RecentBillPaymentItem(
      id: json['id'] ?? 0,
      serviceType: json['serviceType'] ?? '',
      destination: json['destination'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      provider: json['provider'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class RecentAndSavedBillBeneficiaries {
  final List<BillBeneficiaryItem> saved;
  final List<RecentBillPaymentItem> recent;

  RecentAndSavedBillBeneficiaries({
    required this.saved,
    required this.recent,
  });

  factory RecentAndSavedBillBeneficiaries.fromJson(Map<String, dynamic> json) {
    final savedList = json['saved'] as List? ?? [];
    final recentList = json['recent'] as List? ?? [];

    return RecentAndSavedBillBeneficiaries(
      saved: savedList.map((e) => BillBeneficiaryItem.fromJson(e)).toList(),
      recent: recentList.map((e) => RecentBillPaymentItem.fromJson(e)).toList(),
    );
  }
}
