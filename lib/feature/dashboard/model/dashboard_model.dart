class WalletModel {
  final int id;
  final String balance;
  final String currency;

  WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'],
      balance: json['balance'],
      currency: json['currency'],
    );
  }
}

class UserModel {
  final int id;
  final String fullname;
  final String email;
  final String phone;
  final String status;
  final String tier;

  UserModel({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.status,
    required this.tier,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullname: json['fullname'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      tier: json['tier'],
    );
  }
}

class WalletResponse {
  final UserModel user;
  final WalletModel wallet;

  WalletResponse({required this.user, required this.wallet});

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      user: UserModel.fromJson(json['user']),
      wallet: WalletModel.fromJson(json['wallet']),
    );
  }
}