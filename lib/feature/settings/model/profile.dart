class UserResponse {
  final int? id;
  final String? fullname;
  final String? email;
  final String? phone;
  final String? status;
  final String? tier;
  final String? roles;
  final String? refreshToken;
  final String? fcmToken;
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
    this.refreshToken,
    this.fcmToken,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'],
    fullname: json['fullname'],
    email: json['email'],
    phone: json['phone'],
    status: json['status'],
    tier: json['tier'],
    roles: json['roles'],
    refreshToken: json['refreshToken'],
    fcmToken: json['fcmToken'],
    isVerified: json['isVerified'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullname': fullname,
    'email': email,
    'phone': phone,
    'status': status,
    'tier': tier,
    'roles': roles,
    'refreshToken': refreshToken,
    'fcmToken': fcmToken,
    'isVerified': isVerified,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}