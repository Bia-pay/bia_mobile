class TransactionItem {
  final int id;
  final double amount;
  final bool isCredit;
  final String? senderName;
  final String? receiverName;
  final String? provider;       // NEW
  final String? serviceType;    // NEW
  final String? status;         // NEW
  final String? transactionId;    // NEW
  final DateTime? createdAt;

  TransactionItem({
    required this.id,
    required this.amount,
    required this.isCredit,
    this.senderName,
    this.receiverName,
    this.provider,
    this.serviceType,
    this.status,
    this.transactionId,
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

    // Handle both API format (nested sender/receiver) and flat formats (bank transfers, VTU)
    String? senderName;
    if (json['sender'] != null && json['sender'] is Map) {
      senderName = json['sender']['fullname'];
    } else {
      senderName = json['senderName'] ?? 
                   json['sourceAccountName'] ?? 
                   json['sender_name'];
    }

    String? receiverName;
    if (json['receiver'] != null && json['receiver'] is Map) {
      receiverName = json['receiver']['fullname'];
    } else {
      receiverName = json['receiverName'] ?? 
                     json['destinationAccountName'] ?? 
                     json['accountName'] ?? 
                     json['account_name'] ?? 
                     json['beneficiaryName'] ?? 
                     json['beneficiary_name'];
    }


    // Smart classification for VTU/Bill transactions
    String? rawServiceType = json['serviceType'];
    String? rawProvider = json['provider'];
    
    // If we get "VT_PASS" or null, try to infer from aggregator fields or fallbacks
    if (rawServiceType == null || rawServiceType.toUpperCase().contains('VT')) {
      // Check if 'type' or 'txnType' contains the info
      final altType = json['type'] ?? json['txnType'] ?? json['category'];
      if (altType != null && altType is String) {
        rawServiceType = altType;
      } else if (rawProvider != null && 
                 !rawProvider.toUpperCase().contains('VT') && 
                 !rawProvider.toUpperCase().contains('BIA')) {
        // If provider looks like "MTN", "GLO" etc, and serviceType is generic,
        // it's likely an Airtime/Data purchase.
        rawServiceType = (rawProvider.toUpperCase() == 'MTN' || 
                          rawProvider.toUpperCase() == 'GLO' || 
                          rawProvider.toUpperCase() == 'AIRTEL' || 
                          rawProvider.toUpperCase() == '9MOBILE') 
                          ? 'AIRTIME' 
                          : rawProvider;
      }
    }

    return TransactionItem(
      id: json['id'] ?? 0,
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0
          : (json['amount']?.toDouble() ?? 0),
      isCredit: json['isCredit'] ?? false,

      senderName: senderName,
      receiverName: receiverName,

      provider: rawProvider,
      serviceType: rawServiceType,
      status: json['status'],
      transactionId: json['transactionId'],

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
      'status': status,                  // ✅ include
      'transactionId': transactionId,    // ✅ include
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