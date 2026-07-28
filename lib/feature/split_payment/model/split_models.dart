class ParticipantPayload {
  final String identifier;
  final double amount;

  ParticipantPayload({required this.identifier, required this.amount});

  Map<String, dynamic> toJson() => {'identifier': identifier, 'amount': amount};
}

class CreateSplitRequest {
  final String? title;
  final String? description;
  final String? expiresAt;
  final List<ParticipantPayload> participants;

  CreateSplitRequest({
    this.title,
    this.description,
    this.expiresAt,
    required this.participants,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (expiresAt != null) 'expiresAt': expiresAt,
    'participants': participants.map((p) => p.toJson()).toList(),
  };
}

class CreateSplitResponse {
  final String splitId;
  final String token;
  final double totalAmount;
  final String? expiresAt;
  final Map<String, dynamic>? qrPayload;

  CreateSplitResponse({
    required this.splitId,
    required this.token,
    required this.totalAmount,
    this.expiresAt,
    this.qrPayload,
  });

  factory CreateSplitResponse.fromJson(Map<String, dynamic> json) {
    return CreateSplitResponse(
      splitId: json['splitId'] ?? '',
      token: json['token'] ?? '',
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0.0,
      expiresAt: json['expiresAt'],
      qrPayload: json['qrPayload'],
    );
  }
}

class ScanSplitResponse {
  final String splitId;
  final String? title;
  final String? description;
  final String creatorName;
  final double assignedAmount;
  final double amountPaid;
  final String paymentStatus;

  ScanSplitResponse({
    required this.splitId,
    this.title,
    this.description,
    required this.creatorName,
    required this.assignedAmount,
    required this.amountPaid,
    required this.paymentStatus,
  });

  factory ScanSplitResponse.fromJson(Map<String, dynamic> json) {
    return ScanSplitResponse(
      splitId: json['splitId'] ?? '',
      title: json['title'],
      description: json['description'],
      creatorName: json['creatorName'] ?? 'Bia User',
      assignedAmount: double.tryParse(json['assignedAmount']?.toString() ?? '') ?? 0.0,
      amountPaid: double.tryParse(json['amountPaid']?.toString() ?? '') ?? 0.0,
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
    );
  }
}

class PaySplitResponse {
  final String transactionReference;
  final double amountPaid;
  final double remainingBalance;
  final String status;

  PaySplitResponse({
    required this.transactionReference,
    required this.amountPaid,
    required this.remainingBalance,
    required this.status,
  });

  factory PaySplitResponse.fromJson(Map<String, dynamic> json) {
    return PaySplitResponse(
      transactionReference: json['transactionReference'] ?? '',
      amountPaid: double.tryParse(json['amountPaid']?.toString() ?? '') ?? 0.0,
      remainingBalance: double.tryParse(json['remainingBalance']?.toString() ?? '') ?? 0.0,
      status: json['status'] ?? 'PENDING',
    );
  }
}

class SplitCreatorInfo {
  final int id;
  final String fullname;
  final String tag;

  SplitCreatorInfo({
    required this.id,
    required this.fullname,
    required this.tag,
  });

  factory SplitCreatorInfo.fromJson(Map<String, dynamic> json) {
    return SplitCreatorInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullname: json['fullname'] ?? '',
      tag: json['tag'] ?? '',
    );
  }
}

class SplitParticipant {
  final int? userId;
  final String fullname;
  final String tag;
  final String phone;
  final double amountAssigned;
  final double amountPaid;
  final String paymentStatus;
  final String? paidAt;

  SplitParticipant({
    this.userId,
    required this.fullname,
    required this.tag,
    required this.phone,
    required this.amountAssigned,
    required this.amountPaid,
    required this.paymentStatus,
    this.paidAt,
  });

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      userId: (json['userId'] as num?)?.toInt(),
      fullname: json['fullname'] ?? '',
      tag: json['tag'] ?? '',
      phone: json['phone'] ?? '',
      amountAssigned: double.tryParse(json['amountAssigned']?.toString() ?? '') ?? 0.0,
      amountPaid: double.tryParse(json['amountPaid']?.toString() ?? '') ?? 0.0,
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      paidAt: json['paidAt'],
    );
  }
}

class SplitDetailsResponse {
  final String splitId;
  final String? title;
  final String? description;
  final SplitCreatorInfo creator;
  final double totalAmount;
  final double collectedAmount;
  final double remainingAmount;
  final String status;
  final String createdAt;
  final String? expiresAt;
  final double completionPercentage;
  final List<SplitParticipant> participants;

  SplitDetailsResponse({
    required this.splitId,
    this.title,
    this.description,
    required this.creator,
    required this.totalAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    required this.completionPercentage,
    required this.participants,
  });

  factory SplitDetailsResponse.fromJson(Map<String, dynamic> json) {
    var list = json['participants'] as List? ?? [];
    List<SplitParticipant> participantList = list
        .map((e) => SplitParticipant.fromJson(e))
        .toList();

    return SplitDetailsResponse(
      splitId: json['splitId'] ?? '',
      title: json['title'],
      description: json['description'],
      creator: SplitCreatorInfo.fromJson(json['creator'] ?? {}),
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0.0,
      collectedAmount: double.tryParse(json['collectedAmount']?.toString() ?? '') ?? 0.0,
      remainingAmount: double.tryParse(json['remainingAmount']?.toString() ?? '') ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
      expiresAt: json['expiresAt'],
      completionPercentage:
          double.tryParse(json['completionPercentage']?.toString() ?? '') ?? 0.0,
      participants: participantList,
    );
  }
}
