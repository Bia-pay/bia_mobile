import 'dart:math';

String _generateId() =>
    '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

enum MessageRole { user, assistant }

enum MessageStatus { sending, delivered, failed }

enum MessageType {
  text,
  confirmCard, // inline confirmation card  
  suggestionChips, // multiple beneficiary matches
  balanceReply, // wallet balance
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  // Structured payload for rich cards
  final Map<String, dynamic>? payload;

  ChatMessage({
    String? id,
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.status = MessageStatus.delivered,
    this.type = MessageType.text,
    this.payload,
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({MessageStatus? status, Map<String, dynamic>? payload}) {
    return ChatMessage(
      id: id,
      role: role,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
      type: type,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'payload': payload,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      role: MessageRole.values.byName(json['role'] as String),
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.byName(json['status'] as String),
      type: MessageType.values.byName(json['type'] as String),
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
    );
  }
}
