class WalletResponse {
  final int? id;
  final int? userId;
  final dynamic balance;
  final String? currency;
  final String? tier; // added
  final Map<String, dynamic>? limits; // added
  final String? createdAt;
  final String? updatedAt;

  WalletResponse({
    this.id,
    this.userId,
    this.balance,
    this.currency,
    this.tier,
    this.limits,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      id: json['id'],
      userId: json['userId'],
      balance: json['balance'],
      currency: json['currency'],
      tier: json['tier'], // added
      limits: json['limits'] != null ? Map<String, dynamic>.from(json['limits']) : null, // added
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}