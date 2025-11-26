class TransactionResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final List<TransactionItem> transactions;

  TransactionResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    required this.transactions,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['responseBody']?['transactions'] as List?) ?? [];
    return TransactionResponse(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      transactions: list.map((e) => TransactionItem.fromJson(e)).toList(),
    );
  }
}

class TransactionItem {
  final int id;
  final String? type;
  final String? serviceType;
  final String? amount;
  final bool? isCredit;
  final String? description;
  final String? createdAt;
  final String? senderName;
  final String? receiverName;

  TransactionItem({
    required this.id,
    this.type,
    this.serviceType,
    this.amount,
    this.isCredit,
    this.description,
    this.createdAt,
    this.senderName,
    this.receiverName,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};
    final sender = json['sender'] ?? {};
    final receiver = json['receiver'] ?? {};

    return TransactionItem(
      id: json['id'],
      type: json['type'] ?? '',
      serviceType: json['serviceType'] ?? '',
      amount: json['amount'] ?? '0',
      isCredit: json['isCredit'] ?? false,
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? '',
      senderName: metadata['senderName'] ?? sender['fullname'] ?? '',
      receiverName: metadata['receiverName'] ?? receiver['fullname'] ?? '',
    );
  }
}