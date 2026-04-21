import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class HausaAsrService {
  final String _token = String.fromEnvironment('HF_TOKEN');
  // 🟢 UPDATED ENDPOINT
  final String _modelUrl = 'https://router.huggingface.co/hf-inference/models/NCAIR1/Hausa-ASR';

  Future<String?> transcribe(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final audioBytes = await file.readAsBytes();

      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          // 🟢 CHANGE: Use octet-stream for raw audio
          'Content-Type': 'application/octet-stream',
          'x-wait-for-model': 'true', // 🟢 2026 Header style
        },
        body: audioBytes, // 🟢 SEND RAW BYTES, NOT JSON
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['text']?.toString() ?? '';
      } else {
        debugPrint('❌ ASR Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ASR Exception: $e');
      return null;
    }
  }
}