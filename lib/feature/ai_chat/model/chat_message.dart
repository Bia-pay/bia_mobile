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
}
