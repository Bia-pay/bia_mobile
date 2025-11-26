import '../../../dashboard/model/dashboard_model.dart';

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

  ResponseBody({
    this.user,
    this.wallet,
    this.accessToken,
    this.refreshToken,
  });

  factory ResponseBody.fromJson(Map<String, dynamic> json) {
    return ResponseBody(
      user: json['user'] != null ? UserResponse.fromJson(json['user']) : null,
      wallet: json['wallet'] != null ? WalletResponse.fromJson(json['wallet']) : null,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
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
      isVerified: json['isVerified'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
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