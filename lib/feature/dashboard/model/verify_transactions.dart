class VerifyTransactionResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final VerifyDepositData? data;

  VerifyTransactionResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    this.data,
  });

  factory VerifyTransactionResponse.fromJson(Map<String, dynamic> json) {
    return VerifyTransactionResponse(
      responseSuccessful: json["responseSuccessful"] ?? false,
      responseMessage: json["responseMessage"] ?? "",
      data: json["responseBody"] != null
          ? VerifyDepositData.fromJson(json["responseBody"])
          : null,
    );
  }
}

class VerifyDepositData {
  final String status;
  final String description;
  final String txnType;
  final double amount;
  final String reference;
  final String senderName;
  final String currency;
  final String paidAt;
  final String channel;
  final String gatewayResponse;

  VerifyDepositData({
    required this.status,
    required this.description,
    required this.txnType,
    required this.amount,
    required this.reference,
    required this.senderName,
    required this.currency,
    required this.paidAt,
    required this.channel,
    required this.gatewayResponse,
  });

  factory VerifyDepositData.fromJson(Map<String, dynamic> json) {
    return VerifyDepositData(
      status: json["status"] ?? "",
      description: json["description"] ?? "",
      txnType: json["txnType"] ?? "",
      amount: double.tryParse(json["amount"].toString()) ?? 0.0,
      reference: json["reference"] ?? "",
      senderName: json["senderName"] ?? "",
      currency: json["currency"] ?? "",
      paidAt: json["paid_at"] ?? "",
      channel: json["channel"] ?? "",
      gatewayResponse: json["gateway_response"] ?? "",
    );
  }
}

class verifyTransactionResponseBody {
  final String? status;
  final int? amount;
  final String? currency;
  final String? paidAt;
  final String? channel;
  final String? reference;
  final String? gatewayResponse;

  verifyTransactionResponseBody({
    this.status,
    this.amount,
    this.currency,
    this.paidAt,
    this.channel,
    this.reference,
    this.gatewayResponse,
  });

  factory verifyTransactionResponseBody.fromJson(Map<String, dynamic> json) {
    return verifyTransactionResponseBody(
      status: json['status'] as String?,
      amount: json['amount'] as int?,
      currency: json['currency'] as String?,
      paidAt: json['paid_at'] as String?,
      channel: json['channel'] as String?,
      reference: json['reference'] as String?,
      gatewayResponse: json['gateway_response'] as String?,
    );
  }
}