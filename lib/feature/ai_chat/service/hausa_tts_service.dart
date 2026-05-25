import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HausaTtsService {
  // 🟢 LOCAL FASTAPI ENDPOINT
  final String _modelUrl = 'http://192.168.1.136:8000/tts';

  Future<List<int>?> generateSpeech(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('❌ TTS Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ TTS Exception: $e');
      return null;
    }
  }
}
