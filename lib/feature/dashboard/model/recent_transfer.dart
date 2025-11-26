class RecentBeneficiaryResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final List<RecentBeneficiaryItem> beneficiaries;

  RecentBeneficiaryResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    required this.beneficiaries,
  });

  factory RecentBeneficiaryResponse.fromJson(Map<String, dynamic> json) {
    return RecentBeneficiaryResponse(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      beneficiaries: (json['responseBody'] as List<dynamic>? ?? [])
          .map((e) => RecentBeneficiaryItem.fromJson(e))
          .toList(),
    );
  }
}

class RecentBeneficiaryItem {
  final int id;
  final String fullname;
  final String phone;
  final String email;
  final String lastTransferDate;

  RecentBeneficiaryItem({
    required this.id,
    required this.fullname,
    required this.phone,
    required this.email,
    required this.lastTransferDate,
  });

  factory RecentBeneficiaryItem.fromJson(Map<String, dynamic> json) {
    return RecentBeneficiaryItem(
      id: json['id'] ?? 0,
      fullname: json['fullname'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      lastTransferDate: json['lastTransferDate'] ?? '',
    );
  }

  /// 🔥 Needed for Hive/local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'phone': phone,
      'email': email,
      'lastTransferDate': lastTransferDate,
    };
  }
}