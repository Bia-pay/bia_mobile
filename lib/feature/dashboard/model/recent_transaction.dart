class TransactionItem {
  final int id;
  final double amount;
  final bool isCredit;
  final String? senderName;
  final String? receiverName;
  final String? provider;       // NEW
  final String? serviceType;    // NEW
  final String? status;         // NEW
  final String? transactionId;       // NEW
  final String? reference;    // NEW
  final double fee;             // NEW
  final bool isBankTransfer;    // NEW
  final Map<String, dynamic>? metadata; // NEW
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
    this.reference,
    this.fee = 0.0,
    this.isBankTransfer = false,
    this.metadata,
    this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final createdAtRaw = json['createdAt'];
    final reference = json['reference'];

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
                   json['fromAccountName'] ??
                   json['from_account_name'] ??
                   json['sender_name'];
    }

    String? receiverName;
    if (json['receiver'] != null && json['receiver'] is Map) {
      receiverName = json['receiver']['fullname'];
    } else {
      receiverName = json['receiverName'] ?? 
                     json['destinationAccountName'] ?? 
                     json['toAccountName'] ??
                     json['to_account_name'] ??
                     json['accountName'] ?? 
                     json['account_name'] ?? 
                     json['beneficiaryName'] ?? 
                     json['beneficiary_name'] ??
                     json['recipientName'] ??
                     json['recipient_name'];
    }

    // Deep extract from metadata if still null (common for external transfers)
    final metadata = json['metadata'];
    if (metadata != null && metadata is Map) {
      senderName ??= metadata['senderName'] ?? 
                     metadata['sender_name'] ??
                     metadata['fromAccountName'];

      receiverName ??= metadata['receiverName'] ?? 
                       metadata['recipientName'] ?? 
                       metadata['beneficiaryName'] ?? 
                       metadata['accountName'] ??
                       metadata['toAccountName'];
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
      reference: json['reference'],
      transactionId: json['reference'] ?? json['transactionId'],
      fee: (() {
        if (metadata != null && metadata is Map) {
          final rawFee = metadata['fee'];
          if (rawFee != null) {
            if (rawFee is num) return rawFee.toDouble();
            if (rawFee is String) return double.tryParse(rawFee) ?? 0.0;
          }
        }
        return 0.0;
      })(),
      isBankTransfer: (!json['isCredit'] && 
                      json['serviceType']?.toString().toUpperCase() == 'TRANSFER' && 
                      json['receiverId'] == null),
      metadata: metadata is Map ? Map<String, dynamic>.from(metadata) : null,
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
      'transactionId': transactionId,     // ✅ include
      'reference': reference,    // ✅ include
      'fee': fee,                        // ✅ include
      'isBankTransfer': isBankTransfer,  // ✅ include
      'metadata': metadata,              // ✅ include
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
    final dynamic body = json['responseBody'];
    List<dynamic> list = [];

    if (body is List) {
      list = body;
    } else if (body is Map) {
      list = (body['transactions'] as List?) ?? (body['recentTransactions'] as List?) ?? [];
    }

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