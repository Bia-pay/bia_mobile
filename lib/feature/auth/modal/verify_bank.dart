class BankTransferResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final int statusCode;
  final BankTransferResponseBody? responseBody;

  BankTransferResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    required this.statusCode,
    this.responseBody,
  });

  factory BankTransferResponse.fromJson(
      Map<String, dynamic> json,
      int statusCode,
      ) {
    return BankTransferResponse(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      statusCode: statusCode,
      responseBody: json['responseBody'] != null
          ? BankTransferResponseBody.fromJson(json['responseBody'])
          : null,
    );
  }
}

class BankTransferResponseBody {
  final int amount;
  final String paymentRef;
  final String txnRef;
  final int txnFee;
  final int totalTxnAmount;
  final String status;
  final String destinationAccountName;
  final String destinationAccountNumber;
  final String destinationBankCode;
  final String narration;
  final String txnDate;

  BankTransferResponseBody({
    required this.amount,
    required this.paymentRef,
    required this.txnRef,
    required this.txnFee,
    required this.totalTxnAmount,
    required this.status,
    required this.destinationAccountName,
    required this.destinationAccountNumber,
    required this.destinationBankCode,
    required this.narration,
    required this.txnDate,
  });

  factory BankTransferResponseBody.fromJson(Map<String, dynamic> json) {
    return BankTransferResponseBody(
      amount: json['amount'] ?? 0,
      paymentRef: json['paymentRef'] ?? '',
      txnRef: json['txnRef'] ?? '',
      txnFee: json['txnFee'] ?? 0,
      totalTxnAmount: json['totalTxnAmount'] ?? 0,
      status: json['status'] ?? '',
      destinationAccountName: json['destinationAccountName'] ?? '',
      destinationAccountNumber: json['destinationAccountNumber'] ?? '',
      destinationBankCode: json['destinationBankCode'] ?? '',
      narration: json['narration'] ?? '',
      txnDate: json['txnDate'] ?? '',
    );
  }
}