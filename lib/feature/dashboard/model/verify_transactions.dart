class VerifyTransactionResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final verifyTransactionResponseBody? data;

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
          ? verifyTransactionResponseBody.fromJson(json["responseBody"])
          : null,
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