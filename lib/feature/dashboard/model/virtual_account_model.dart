class VirtualAccountModel {
  final int id;
  final int userId;
  final String virtualAccountName;
  final String virtualAccountNo;
  final String status;
  final String identityType;
  final String email;
  final String customerName;
  final String accountReference;
  final String provider;
  final String createdAt;
  final String updatedAt;

  const VirtualAccountModel({
    required this.id,
    required this.userId,
    required this.virtualAccountName,
    required this.virtualAccountNo,
    required this.status,
    required this.identityType,
    required this.email,
    required this.customerName,
    required this.accountReference,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VirtualAccountModel.fromJson(Map<String, dynamic> json) {
    return VirtualAccountModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      virtualAccountName: json['virtualAccountName']?.toString() ?? '',
      virtualAccountNo: json['virtualAccountNo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      identityType: json['identityType']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      accountReference: json['accountReference']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'virtualAccountName': virtualAccountName,
        'virtualAccountNo': virtualAccountNo,
        'status': status,
        'identityType': identityType,
        'email': email,
        'customerName': customerName,
        'accountReference': accountReference,
        'provider': provider,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
