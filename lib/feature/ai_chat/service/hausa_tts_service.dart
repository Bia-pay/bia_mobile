import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HausaTtsService {
  final String _token = String.fromEnvironment('HF_TOKEN');
  // 🟢 ROUTER ENDPOINT (Supports standard Hugging Face routing)
  final String _modelUrl = 'https://router.huggingface.co/hf-inference/models/facebook/mms-tts-hau';



  Future<List<int>?> generateSpeech(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'x-wait-for-model': 'true', // 🟢 Forces router to wait for model to wake up
        },
        body: jsonEncode({
          'inputs': text,
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
