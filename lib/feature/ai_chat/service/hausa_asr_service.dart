import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:bia/core/constants.dart';

class HausaAsrService {
  // 🤖 VPS FASTAPI ENDPOINT
  final String _apiUrl = '${AppConstants.aiBaseUrl}/transcribe';

  Future<String?> transcribe(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // 🟢 MULTIPART REQUEST FOR FASTAPI
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Must match FastAPI's parameter name
          filePath,
        ),
      );

      // 🟢 SEND WITH INCREASED TIMEOUT (15s for local MacBook inference)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      // 🟢 LOG RAW RESPONSE BODY FOR DEBUGGING
      debugPrint('🎙️ ASR Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['text']?.toString() ?? '';
      } else {
        debugPrint('❌ Local ASR Error: ${response.statusCode} - ${response.body}');
        return null; // Return null for generic errors
      }
    } on SocketException {
       // 🟢 HUB OFFLINE (No connection to host)
       return 'HUB_OFFLINE';
    } on TimeoutException {
       debugPrint('❌ ASR Timeout: Inference took too long');
       return null; // Triggers "I could not hear you" instead of "Hub Offline"
    } catch (e) {
      debugPrint('❌ ASR Exception: $e');
      return null;
    }
  }

}