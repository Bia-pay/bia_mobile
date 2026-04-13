import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class LlmParsedResponse {
  final String intent;
  final String? recipient;
  final double? amount;
  final String? destinationBank;
  final String chatResponse;

  LlmParsedResponse({
    required this.intent,
    this.recipient,
    this.amount,
    this.destinationBank,
    required this.chatResponse,
  });

  factory LlmParsedResponse.fromJson(Map<String, dynamic> json) {
    return LlmParsedResponse(
      intent: json['intent'] ?? 'unknown',
      recipient: json['recipient']?.toString(),
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      destinationBank: json['destination_bank']?.toString(),
      chatResponse: json['chat_response'] ?? '...',
    );
  }
}

class LlmService {
  late GenerativeModel _model;
  final List<Content> _history = [];
  final String _apiKey;
  String _language = 'english';

  LlmService({required String apiKey}) : _apiKey = apiKey {
    _buildModel();
  }

  void updateLanguage(String language) {
    _language = language;
    _history.clear(); // Reset history when language changes
    _buildModel();
  }

  void _buildModel() {
    final langInstruction = _buildLangInstruction(_language);
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system('''
You are BIA AI, a helpful digital banking assistant for the BIA mobile app in Nigeria.
You MUST ALWAYS respond in valid JSON format ONLY. Do not output anything outside the JSON block.
You can understand and process user input in standard English, Nigerian Pidgin, or Hausa.

$langInstruction

INTENTS YOU SUPPORT:
1. "sendMoney" (user wants to transfer money to someone's name or account number inside the BIA app)
2. "sendToBank" (user explicitly wants to transfer money to another bank like GTB, UBA, Zenith, Opay, etc.)
3. "checkBalance" (user wants to see their wallet balance)
4. "unknown" (small talk, greetings, or unsupported requests)

JSON OUTPUT STRUCTURE:
{
  "intent": "sendMoney" | "sendToBank" | "checkBalance" | "unknown",
  "recipient": "name of the person or 10-digit account number" (null if not available),
  "amount": 500 (number, null if not available),
  "destination_bank": "the name of the external bank e.g., GTBank, UBA, Zenith" (null if BIA to BIA),
  "chat_response": "The actual text you want to reply to the user. Always speak in the chosen language!"
}

GUIDELINES:
- If the user asks to send money but doesn't mention the amount, ask for it in the `chat_response`.
- If the intent is `sendToBank` but they didn't provide the 10-digit account number, explicitly ask for it.
- If you receive a hidden [SYSTEM_CONTEXT], ignore previous intents and focus ONLY on generating a natural `chat_response` based on that context while keeping the `intent` as "unknown".
- Do not make up fake balances or fake transfer confirmations. The app handles the actual transfer UI.
- If the user asks "what ai model are you using", you can say you are powered by Gemini for BIA.
'''),
    );
  }

  static String _buildLangInstruction(String lang) {
    switch (lang) {
      case 'hausa':
        return '''
YOUR PERSONALITY (HAUSA):
- Always respond primarily in Hausa language.
- Be polite, warm, and helpful as is customary in Hausa culture (use "Sannu", "Marhaba", "Na gode", "Yaya zan iya taimaka maka?").
- Even for system messages like "Verifying...", say it naturally in Hausa (e.g. "Ina duba asusun...").
- Mix Hausa naturally throughout your responses. Keep banking terms in English.
''';
      case 'pidgin':
        return '''
YOUR PERSONALITY (PIDGIN):
- Always respond in Nigerian Pidgin English.
- Use natural Pidgin expressions like "Oya", "Abeg", "No wahala", "How far?", "Wetin you wan do?", "I don hear you".
- Be friendly, energetic and casual like a helpful Nigerian friend.
- For system actions like verifying, say it in Pidgin (e.g. "Oya I dey check the account sharp sharp").
''';
      default:
        return '''
YOUR PERSONALITY (ENGLISH):
- Use standard Nigerian English with occasional warm Pidgin flair (e.g., "No wahala", "Oya").
- Be friendly, professional, and clear.
''';
    }
  }

  Future<LlmParsedResponse> sendContextualMessage(String context) async {
    return sendMessage("[SYSTEM_CONTEXT]: $context");
  }

  Future<LlmParsedResponse> sendMessage(String text) async {
    // Add user message to history
    _history.add(Content.text(text));
    
    try {
      final chat = _model.startChat(history: _history.sublist(0, _history.length - 1));
      final response = await chat.sendMessage(Content.text(text));
      
      var textResponse = response.text ?? '{}';
      
      // Save model response to history
      _history.add(Content.model([TextPart(textResponse)]));
      
      // Clean potential markdown wrap
      textResponse = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();

      final data = jsonDecode(textResponse);
      return LlmParsedResponse.fromJson(data);
    } catch (e) {
      print("LLM Error: $e");
      return LlmParsedResponse(
        intent: 'unknown',
        chatResponse: 'Ah! Small network wahala. I no fit process am right now. Abeg try again.',
      );
    }
  }
  
  void resetHistory() {
    _history.clear();
  }
}
