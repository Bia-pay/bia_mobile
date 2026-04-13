import 'dart:convert';
import 'package:http/http.dart' as http;

class ElevenLabsService {
  final String _apiKey;
  final String _baseUrl = "https://api.elevenlabs.io/v1/text-to-speech";

  ElevenLabsService({required String apiKey}) : _apiKey = apiKey;

  /// Sends a text to ElevenLabs and returns the MP3 bytes to play.
  /// Uses the 'eleven_flash_v2_5' model for ultra-low latency.
  Future<List<int>?> generateSpeech({
    required String text,
    required String voiceId,
  }) async {
    try {
      final url = "$_baseUrl/$voiceId";
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "xi-api-key": _apiKey,
          "Content-Type": "application/json",
          "Accept": "audio/mpeg",
        },
        body: jsonEncode({
          "text": text,
          "model_id": "eleven_flash_v2_5",
          "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75,
            "style": 0.0,
            "use_speaker_boost": true,
          },
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("ElevenLabs Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("ElevenLabs Exception: $e");
      return null;
    }
  }
}
