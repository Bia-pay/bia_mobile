class ResponseModel {
  final String responseMessage;
  final bool responseSuccessful;
  final int statusCode;
  final ResponseBody? responseBody;

  ResponseModel({
    required this.responseMessage,
    required this.responseSuccessful,
    required this.statusCode,
    this.responseBody,
  });

  factory ResponseModel.fromJson(Map<String, dynamic> json, int statusCode) {
    return ResponseModel(
      responseMessage: json['responseMessage'] ?? '',
      responseSuccessful: json['responseSuccessful'] ?? false,
      statusCode: statusCode,
      responseBody: json['responseBody'] != null
          ? ResponseBody.fromJson(json['responseBody'])
          : null,
    );
  }
}

class ResponseBody {
  final UserResponse? user;
  final WalletResponse? wallet;
  final String? accessToken;
  final String? refreshToken;
  final String? status;

  // ✅ ADD THESE
  final String? reference;
  final int? transactionId;
  final dynamic amount;
  final dynamic senderBalance;
  final String? receiverName;

  ResponseBody({
    this.user,
    this.wallet,
    this.accessToken,
    this.refreshToken,
    this.reference,
    this.transactionId,
    this.amount,
    this.senderBalance,
    this.receiverName,
    this.status,
  });

  factory ResponseBody.fromJson(Map<String, dynamic> json) {
    return ResponseBody(
      user: json['user'] != null ? UserResponse.fromJson(json['user']) : null,
      wallet: json['wallet'] != null ? WalletResponse.fromJson(json['wallet']) : null,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],

      // ✅ ADD THESE
      reference: json['reference'],
      status: json['status'],
      transactionId: json['transactionId'],
      amount: json['amount'],
      senderBalance: json['senderBalance'],
      receiverName: json['receiverName'],
    );
  }
}

class UserResponse {
  final int? id;
  final String? fullname;
  final String? email;
  final String? phone;
  final String? status;
  final String? tier;
  final String? roles;
  final String? pin;
  final String? picture;
  final bool? isVerified;
  final String? createdAt;
  final String? updatedAt;

  UserResponse({
    this.id,
    this.fullname,
    this.email,
    this.phone,
    this.status,
    this.tier,
    this.roles,
    this.pin,
    this.picture,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      fullname: json['fullname'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      tier: json['tier'],
      roles: json['roles'],
      pin: json['pin'],
      picture: json['picture'],
      isVerified: json['isVerified'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullname': fullname,
    'email': email,
    'phone': phone,
    'status': status,
    'tier': tier,
    'roles': roles,
    'pin': pin,
    'picture': picture,
    'isVerified': isVerified,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
  UserResponse copyWith({
    String? fullname,
    String? email,
    String? phone,
    String? picture,
  }) {
    return UserResponse(
      id: id,
      fullname: fullname ?? this.fullname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status,
      tier: tier,
      roles: roles,
      pin: pin,
      picture: picture ?? this.picture,
      isVerified: isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

}

class WalletResponse {
  final int? id;
  final int? userId;
  final dynamic balance;
  final String? currency;
  final String? createdAt;
  final String? updatedAt;

  WalletResponse({
    this.id,
    this.userId,
    this.balance,
    this.currency,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      id: json['id'],
      userId: json['userId'],
      balance: json['balance'],
      currency: json['currency'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}