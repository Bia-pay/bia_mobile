class ReferralStats {
  final String referralCode;
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final double totalEarnings;

  ReferralStats({
    required this.referralCode,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.totalEarnings,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referralCode'] ?? '',
      totalReferrals: json['totalReferrals'] ?? 0,
      completedReferrals: json['completedReferrals'] ?? 0,
      pendingReferrals: json['pendingReferrals'] ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referralCode': referralCode,
      'totalReferrals': totalReferrals,
      'completedReferrals': completedReferrals,
      'pendingReferrals': pendingReferrals,
      'totalEarnings': totalEarnings,
    };
  }
}

class ReferredUser {
  final int id;
  final String fullname;
  final String phone;
  final String createdAt;

  ReferredUser({
    required this.id,
    required this.fullname,
    required this.phone,
    required this.createdAt,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id'] ?? 0,
      fullname: json['fullname'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'phone': phone,
      'createdAt': createdAt,
    };
  }
}

class ReferralHistoryItem {
  final int id;
  final int referrerId;
  final int referredUserId;
  final double bonusAmount;
  final String status;
  final String createdAt;
  final String updatedAt;
  final ReferredUser? referredUser;

  ReferralHistoryItem({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    required this.bonusAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.referredUser,
  });

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItem(
      id: json['id'] ?? 0,
      referrerId: json['referrerId'] ?? 0,
      referredUserId: json['referredUserId'] ?? 0,
      bonusAmount: double.tryParse(json['bonusAmount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      referredUser: json['referredUser'] != null
          ? ReferredUser.fromJson(json['referredUser'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrerId': referrerId,
      'referredUserId': referredUserId,
      'bonusAmount': bonusAmount.toString(),
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'referredUser': referredUser?.toJson(),
    };
  }
}
