class BankModel {
  final String bankCode;
  final String bankName;

  BankModel({
    required this.bankCode,
    required this.bankName,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      bankCode: json['code']?.toString() ?? '',  // API uses 'code'
      bankName: json['name'] ?? '',              // API uses 'name'
    );
  }

  Map<String, dynamic> toJson() => {
    'code': bankCode,
    'name': bankName,
  };
}
class BankAccountVerifyResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final BankAccountData? responseBody;

  BankAccountVerifyResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    this.responseBody,
  });

  factory BankAccountVerifyResponse.fromJson(Map<String, dynamic> json) {
    return BankAccountVerifyResponse(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      responseBody: json['responseBody'] != null
          ? BankAccountData.fromJson(json['responseBody'])
          : null,
    );
  }
}

class BankAccountData {
  final String? accountName;
  final String? accountNumber;
  final String? bankCode;
  final String? bankName;

  BankAccountData({
    this.accountName,
    this.accountNumber,
    this.bankCode,
    this.bankName,
  });

  factory BankAccountData.fromJson(Map<String, dynamic> json) {
    return BankAccountData(
      accountName: json['accountName'] ?? json['account_name'],
      accountNumber: json['accountNumber'] ?? json['account_number'],
      bankCode: json['bankCode'] ?? json['bank_code'],
      bankName: json['bankName'] ?? json['bank_name'],
    );
  }
}