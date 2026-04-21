import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../model/chat_message.dart';

class AiChatPersistenceService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyName = 'ai_chat_encryption_key';

  /// Get or create a 256-bit encryption key for Hive boxes
  Future<List<int>> _getOrCreateEncryptionKey() async {
    final containsKey = await _secureStorage.containsKey(key: _encryptionKeyName);
    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(key),
      );
    }
    final keyString = await _secureStorage.read(key: _encryptionKeyName);
    return base64Url.decode(keyString!);
  }

  /// Open an encrypted box scoped to a specific userId
  Future<Box> _getBox(String userId) async {
    final encryptionKey = await _getOrCreateEncryptionKey();
    return await Hive.openBox(
      'chat_history_$userId',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  /// Save the entire message list for a specific user
  Future<void> saveMessages(String userId, List<ChatMessage> messages) async {
    if (userId.isEmpty) return;
    final box = await _getBox(userId);
    final jsonList = messages.map((m) => m.toJson()).toList();
    await box.put('messages', jsonList);
  }

  /// Load existing messages for a specific user
  Future<List<ChatMessage>> loadMessages(String userId) async {
    if (userId.isEmpty) return [];
    final box = await _getBox(userId);
    final List<dynamic>? jsonList = box.get('messages');
    if (jsonList == null) return [];
    
    return jsonList
        .map((j) => ChatMessage.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  /// Save language preference scoped to user
  Future<void> saveUserLanguage(String userId, String language) async {
    if (userId.isEmpty) return;
    final box = await Hive.openBox('appPrefs');
    await box.put('biaAiLanguage_$userId', language);
  }

  /// Load language preference scoped to user
  Future<String?> loadUserLanguage(String userId) async {
    if (userId.isEmpty) return null;
    final box = await Hive.openBox('appPrefs');
    return box.get('biaAiLanguage_$userId');
  }
}
