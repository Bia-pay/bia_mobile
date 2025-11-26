class TransferResponseModel {
  final bool responseSuccessful;
  final String responseMessage;
  final TransferResponseBody responseBody;

  TransferResponseModel({
    required this.responseSuccessful,
    required this.responseMessage,
    required this.responseBody,
  });

  factory TransferResponseModel.fromJson(Map<String, dynamic> json) {
    return TransferResponseModel(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      responseBody: TransferResponseBody.fromJson(json['responseBody'] ?? {}),
    );
  }
}

class TransferResponseBody {
  final String reference;
  final double amount;
  final String senderBalance;
  final String receiverName;
  final int transactionId;

  TransferResponseBody({
    required this.reference,
    required this.amount,
    required this.senderBalance,
    required this.receiverName,
    required this.transactionId,
  });

  factory TransferResponseBody.fromJson(Map<String, dynamic> json) {
    return TransferResponseBody(
      reference: json['reference'] ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] ?? 0.0).toDouble(),
      senderBalance: json['senderBalance'] ?? '0',
      receiverName: json['receiverName'] ?? '',
      transactionId: json['transactionId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'amount': amount,
    'senderBalance': senderBalance,
    'receiverName': receiverName,
    'transactionId': transactionId,
  };
}