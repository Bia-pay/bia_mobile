import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:bia/core/constants.dart';

class HausaTtsService {
  // 🤖 VPS FASTAPI ENDPOINT
  final String _modelUrl = '${AppConstants.aiBaseUrl}/tts';

  Future<List<int>?> generateSpeech(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      debugPrint('🔊 TTS → Requesting: "$text"');

      final response = await http
          .post(
            Uri.parse(_modelUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        debugPrint('✅ TTS → Received ${bytes.length} bytes');
        // Sanity check: must be a valid WAV (starts with RIFF header)
        if (bytes.length > 4 &&
            bytes[0] == 0x52 && // R
            bytes[1] == 0x49 && // I
            bytes[2] == 0x46 && // F
            bytes[3] == 0x46) { // F
          return bytes;
        } else {
          debugPrint('❌ TTS → Invalid WAV header. Raw: ${response.body.substring(0, response.body.length.clamp(0, 100))}');
          return null;
        }
      } else {
        debugPrint('❌ TTS Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('❌ TTS → Server unreachable: $e');
      return null;
    } on TimeoutException {
      debugPrint('❌ TTS → Request timed out (>20s)');
      return null;
    } catch (e) {
      debugPrint('❌ TTS Exception: $e');
      return null;
    }
  }
}
