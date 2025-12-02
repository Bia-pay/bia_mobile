class TransactionItem {
  final int id;
  final double amount;
  final bool isCredit;
  final String? senderName;
  final String? receiverName;
  final String? provider;       // NEW
  final String? serviceType;    // NEW
  final DateTime? createdAt;

  TransactionItem({
    required this.id,
    required this.amount,
    required this.isCredit,
    this.senderName,
    this.receiverName,
    this.provider,
    this.serviceType,
    this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final createdAtRaw = json['createdAt'];

    if (createdAtRaw != null) {
      if (createdAtRaw is String) {
        parsedDate = DateTime.tryParse(createdAtRaw);
      } else if (createdAtRaw is DateTime) {
        parsedDate = createdAtRaw;
      }
    }

    return TransactionItem(
      id: json['id'] ?? 0,
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0
          : (json['amount']?.toDouble() ?? 0),
      isCredit: json['isCredit'] ?? false,

      senderName:
      json['sender'] != null ? json['sender']['fullname'] : null,

      receiverName:
      json['receiver'] != null ? json['receiver']['fullname'] : null,

      provider: json['provider'],              // ✅ now parsed
      serviceType: json['serviceType'],        // ✅ now parsed

      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'isCredit': isCredit,
      'senderName': senderName,
      'receiverName': receiverName,
      'provider': provider,              // ✅ include
      'serviceType': serviceType,        // ✅ include
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
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

  Map<String, dynamic> toJson() => {
    'responseSuccessful': responseSuccessful,
    'responseMessage': responseMessage,
    'transactions': transactions.map((e) => e.toJson()).toList(),
  };
}