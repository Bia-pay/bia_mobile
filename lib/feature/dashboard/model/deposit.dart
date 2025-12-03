class DepositResponseModel {
  final bool responseSuccessful;
  final String responseMessage;
  final DepositData? data;

  DepositResponseModel({
    required this.responseSuccessful,
    required this.responseMessage,
    this.data,
  });

  factory DepositResponseModel.fromJson(Map<String, dynamic> json) {
    return DepositResponseModel(
      responseSuccessful: json["responseSuccessful"] ?? false,
      responseMessage: json["responseMessage"] ?? "",
      data: json["responseBody"] != null
          ? DepositData.fromJson(json["responseBody"])
          : null,
    );
  }
}

class DepositData {
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  DepositData({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory DepositData.fromJson(Map<String, dynamic> json) {
    return DepositData(
      authorizationUrl: json["authorization_url"] ?? "",
      accessCode: json["access_code"] ?? "",
      reference: json["reference"] ?? "",
    );
  }
}