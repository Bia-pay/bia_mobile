import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../model/chat_message.dart';

class AiChatPersistenceService {
  static const String _encryptionKeyName = 'ai_chat_encryption_key';
  static final Map<String, List<int>> _inMemoryKeys = {};

  /// Get or create a 256-bit encryption key for Hive boxes, scoped to userId
  Future<List<int>> _getOrCreateEncryptionKey(String userId) async {
    final keyName = '${_encryptionKeyName}_$userId';
    try {
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final containsKey = await secureStorage.containsKey(key: keyName);
      if (!containsKey) {
        final key = Hive.generateSecureKey();
        await secureStorage.write(
          key: keyName,
          value: base64UrlEncode(key),
        );
      }
      final keyString = await secureStorage.read(key: keyName);
      if (keyString == null) throw Exception("Key is null");
      return base64Url.decode(keyString);
    } catch (e) {
      debugPrint("⚠️ Secure storage key error for $userId: $e. Falling back to persistent appBox...");
      // Fall back to standard unencrypted appBox if secure storage fails (common on simulators)
      try {
        final appBox = await Hive.openBox('appBox');
        final savedKeyString = appBox.get(keyName) as String?;
        if (savedKeyString != null) {
          return base64Url.decode(savedKeyString);
        } else {
          final key = Hive.generateSecureKey();
          await appBox.put(keyName, base64UrlEncode(key));
          return key;
        }
      } catch (e2) {
        debugPrint("❌ Absolute persistent fallback failed: $e2. Returning temporary in-memory key.");
        // Last resort: in-memory key if absolute catastrophe (survives active session but not restarts)
        return _inMemoryKeys[userId] ??= Hive.generateSecureKey();
      }
    }
  }

  /// Open an encrypted box scoped to a specific userId with recovery fallbacks
  Future<Box> _getBox(String userId) async {
    final boxName = 'chat_history_$userId';
    try {
      final encryptionKey = await _getOrCreateEncryptionKey(userId);
      return await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint("⚠️ Encrypted Hive box corrupted or key mismatch, recreating: $e");
      try {
        await Hive.deleteBoxFromDisk(boxName);
        final encryptionKey = await _getOrCreateEncryptionKey(userId);
        return await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      } catch (e2) {
        debugPrint("❌ Failed to open box even after deleting: $e2");
        // Fallback to unencrypted box if absolute catastrophic failure
        return await Hive.openBox(boxName);
      }
    }
  }

  /// Save the entire message list for a specific user
  Future<void> saveMessages(String userId, List<ChatMessage> messages) async {
    if (userId.isEmpty) return;
    try {
      final box = await _getBox(userId);
      final jsonList = messages.map((m) => m.toJson()).toList();
      await box.put('messages', jsonList);
    } catch (e) {
      debugPrint("❌ Failed to save messages to local storage: $e");
    }
  }

  /// Load existing messages for a specific user
  Future<List<ChatMessage>> loadMessages(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final box = await _getBox(userId);
      final List<dynamic>? jsonList = box.get('messages');
      if (jsonList == null) return [];
      
      return jsonList
          .map((j) => ChatMessage.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (e) {
      debugPrint("❌ Failed to load messages from local storage: $e");
      return [];
    }
  }

  /// Save language preference scoped to user
  Future<void> saveUserLanguage(String userId, String language) async {
    if (userId.isEmpty) return;
    try {
      final box = await Hive.openBox('appPrefs');
      await box.put('biaAiLanguage_$userId', language);
    } catch (e) {
      debugPrint("❌ Failed to save user language: $e");
    }
  }

  /// Load language preference scoped to user
  Future<String?> loadUserLanguage(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final box = await Hive.openBox('appPrefs');
      return box.get('biaAiLanguage_$userId');
    } catch (e) {
      debugPrint("❌ Failed to load user language: $e");
      return null;
    }
  }
}
