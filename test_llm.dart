import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  String apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    try {
      final file = File('secrets.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        apiKey = json['GEMINI_API_KEY'] ?? '';
      }
    } catch (_) {}
  }
  if (apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY environment variable or secrets.json is not set.');
    return;
  }
  final model = GenerativeModel(
    model: 'gemini-flash-latest',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
    systemInstruction: Content.system('You are BIA AI. Return JSON only.'),
  );

  try {
    final chat = model.startChat();
    final response = await chat.sendMessage(Content.text('send 100 to farex'));
    print('Response text: ${response.text}');
  } catch (e, stack) {
    print('Exception: $e');
    print('Stack: $stack');
  }
}
