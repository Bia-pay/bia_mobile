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
  final String? token;
  final String? status;
  final List<dynamic>? recentTransactions;

  // ✅ ADD THESE
  final String? reference;
  final String? debitReference;
  final String? requestId;
  final int? transactionId;
  final dynamic amount;
  final dynamic fee;
  final dynamic senderBalance;
  final String? receiverName;
  final bool? isCompleteRegistration;

  ResponseBody({
    this.user,
    this.wallet,
    this.accessToken,
    this.refreshToken,
    this.token,
    this.reference,
    this.debitReference,
    this.requestId,
    this.transactionId,
    this.amount,
    this.fee,
    this.senderBalance,
    this.receiverName,
    this.status,
    this.recentTransactions,
    this.isCompleteRegistration,
  });

  factory ResponseBody.fromJson(Map<String, dynamic> json) {
    return ResponseBody(
      user: json['user'] != null ? UserResponse.fromJson(json['user']) : null,
      wallet: json['wallet'] != null ? WalletResponse.fromJson(json['wallet']) : null,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      token: json['token']?.toString() ?? 
             json['mainToken']?.toString() ?? 
             json['purchasedToken']?.toString() ?? 
             json['purchased_token']?.toString() ?? 
             json['purchased_code']?.toString() ?? 
             json['purchasedCode']?.toString() ?? 
             json['token_code']?.toString() ?? 
             json['tokenCode']?.toString() ?? 
             json['main_token']?.toString() ?? 
             json['pin']?.toString(),
      reference: json['reference'],
      debitReference: json['debitReference'],
      requestId: json['requestId'],
      status: json['status'],
      transactionId: json['transactionId'],
      amount: json['amount'],
      fee: json['fee'],
      senderBalance: json['senderBalance'],
      receiverName: json['receiverName'],
      recentTransactions: json['recentTransactions'],
      isCompleteRegistration: json['isCompleteRegistration'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user?.toJson(),
    'wallet': wallet?.toJson(),
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'reference': reference,
    'debitReference': debitReference,
    'requestId': requestId,
    'status': status,
    'transactionId': transactionId,
    'amount': amount,
    'fee': fee,
    'senderBalance': senderBalance,
    'receiverName': receiverName,
    'recentTransactions': recentTransactions,
    'isCompleteRegistration': isCompleteRegistration,
  };
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
  final String? tag;
  final bool? isVerified;
  final bool? isCompleteRegistration;
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
    this.tag,
    this.isVerified,
    this.isCompleteRegistration,
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
      tag: json['tag'],
      isVerified: json['isVerified'],
      isCompleteRegistration: json['isCompleteRegistration'],
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
    'tag': tag,
    'isVerified': isVerified,
    'isCompleteRegistration': isCompleteRegistration,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
  UserResponse copyWith({
    String? fullname,
    String? email,
    String? phone,
    String? picture,
    String? tag,
    bool? isCompleteRegistration,
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
      tag: tag ?? this.tag,
      isVerified: isVerified,
      isCompleteRegistration: isCompleteRegistration ?? this.isCompleteRegistration,
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
  final Map<String, dynamic>? limits;

  WalletResponse({
    this.id,
    this.userId,
    this.balance,
    this.currency,
    this.createdAt,
    this.updatedAt,
    this.limits,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      id: json['id'],
      userId: json['userId'],
      balance: json['balance'],
      currency: json['currency'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      limits: json['limits'] != null ? Map<String, dynamic>.from(json['limits']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'balance': balance,
    'currency': currency,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'limits': limits,
  };
}