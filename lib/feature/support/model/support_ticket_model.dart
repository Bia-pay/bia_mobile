class SupportTicket {
  final int id;
  final int userId;
  final String subject;
  final String description;
  final String status;
  final bool aiEscalated;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SupportMessage> messages;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.aiEscalated,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    var rawMessages = json['messages'] as List?;
    List<SupportMessage> messageList = rawMessages != null
        ? rawMessages.map((e) => SupportMessage.fromJson(e)).toList()
        : const [];

    return SupportTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      aiEscalated: json['aiEscalated'] as bool? ?? false,
      resolution: json['resolution']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      messages: messageList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'subject': subject,
        'description': description,
        'status': status,
        'aiEscalated': aiEscalated,
        'resolution': resolution,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((e) => e.toJson()).toList(),
      };
}

class SupportMessage {
  final int id;
  final int ticketId;
  final int senderId;
  final String senderType; // USER or AGENT/AI
  final String senderName;
  final String message;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticketId: (json['ticketId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      senderType: json['senderType']?.toString() ?? 'USER',
      senderName: json['senderName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketId': ticketId,
        'senderId': senderId,
        'senderType': senderType,
        'senderName': senderName,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };
}
