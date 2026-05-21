import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyAT_U_85y4BE7y8yacTF2fFpZNZPdDxu74';
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
