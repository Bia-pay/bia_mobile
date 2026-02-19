class FavouriteBeneficiaryResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final List<FavouriteBeneficiaryItem> beneficiaries;

  FavouriteBeneficiaryResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    required this.beneficiaries,
  });

  factory FavouriteBeneficiaryResponse.fromJson(
      Map<String, dynamic> json) {
    final body = json['responseBody'] ?? {};
    final data = body['data'] as List<dynamic>? ?? [];

    return FavouriteBeneficiaryResponse(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      beneficiaries:
      data.map((e) => FavouriteBeneficiaryItem.fromJson(e)).toList(),
    );
  }
}

class FavouriteBeneficiaryItem {
  final int id;
  final String type;
  final String name;
  final String createdAt;
  final InAppUser? inAppUser;

  FavouriteBeneficiaryItem({
    required this.id,
    required this.type,
    required this.name,
    required this.createdAt,
    this.inAppUser,
  });

  factory FavouriteBeneficiaryItem.fromJson(
      Map<String, dynamic> json) {
    return FavouriteBeneficiaryItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] ?? '',
      inAppUser: json['inAppUser'] != null
          ? InAppUser.fromJson(json['inAppUser'])
          : null,
    );
  }

  /// 🔥 This gives you phone directly
  String get phone => inAppUser?.phone ?? '';
}

class InAppUser {
  final int id;
  final String fullname;
  final String phone;
  final String email;

  InAppUser({
    required this.id,
    required this.fullname,
    required this.phone,
    required this.email,
  });

  factory InAppUser.fromJson(Map<String, dynamic> json) {
    return InAppUser(
      id: json['id'] ?? 0,
      fullname: json['fullname'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }
}