import 'dart:convert';
import 'package:bia/feature/auth/data/api_constant.dart';
import 'package:bia/feature/auth/data/api_data.dart';

class LlmParsedResponse {
  final String intent;
  final String? recipient;
  final double? amount;
  final String? destinationBank;
  final String chatResponse;
  final String language;
  final String? transcribedText;
  final String? audioResponseBase64;
  final Map<String, dynamic> details;

  LlmParsedResponse({
    required this.intent,
    this.recipient,
    this.amount,
    this.destinationBank,
    required this.chatResponse,
    required this.language,
    this.transcribedText,
    this.audioResponseBase64,
    required this.details,
  });

  factory LlmParsedResponse.fromJson(Map<String, dynamic> json) {
    final intentObj = json['intent'] ?? {};
    final action = intentObj['action'] ?? 'NONE';
    final details = intentObj['details'] ?? {};
    
    // Map details properties to the legacy fields for backward compatibility
    final String? recipient = details['accountNumber']?.toString() ?? details['recipient']?.toString() ?? details['phoneNumber']?.toString();
    final double? amount = details['amount'] != null ? double.tryParse(details['amount'].toString()) : null;
    final String? destinationBank = details['bankName']?.toString();

    return LlmParsedResponse(
      intent: action,
      recipient: recipient,
      amount: amount,
      destinationBank: destinationBank,
      chatResponse: json['message'] ?? '...',
      language: json['language'] ?? 'en',
      transcribedText: json['transcribedText']?.toString(),
      audioResponseBase64: json['audioResponseBase64']?.toString(),
      details: Map<String, dynamic>.from(details),
    );
  }
}

class LlmService {
  final ApiClient _apiClient;
  String _language = 'en'; // default 'en', 'ha' or 'auto'

  LlmService({required ApiClient apiClient}) : _apiClient = apiClient;

  void updateLanguage(String language) {
    if (language.toLowerCase() == 'hausa') {
      _language = 'ha';
    } else if (language.toLowerCase() == 'english') {
      _language = 'en';
    } else {
      _language = 'auto';
    }
  }

  String _getFallbackErrorResponse(String lang) {
    switch (lang) {
      case 'ha':
        return 'Ina samun ɗan matsalar sadarwa. Da fatan za a sake gwadawa nan gaba.';
      case 'pidgin':
        return 'Ah! Small network wahala. I no fit process am right now. Abeg try again.';
      default:
        return 'I am experiencing a slight network issue. Please try again shortly.';
    }
  }

  Future<LlmParsedResponse> sendContextualMessage(String context) async {
    return sendMessage("[SYSTEM_CONTEXT]: $context");
  }

  Future<LlmParsedResponse> sendMessage(String text) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.AI_CHAT,
        {
          'prompt': text,
          'language': _language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['responseSuccessful'] == true && body['responseBody'] != null) {
          return LlmParsedResponse.fromJson(body['responseBody']);
        }
      } else {
        print("❌ AI Chat HTTP Error: ${response.statusCode} - ${response.body}");
      }

      return LlmParsedResponse(
        intent: 'NONE',
        chatResponse: _getFallbackErrorResponse(_language),
        language: _language,
        details: {},
      );
    } catch (e) {
      print("LLM Service Error: $e");
      return LlmParsedResponse(
        intent: 'NONE',
        chatResponse: _getFallbackErrorResponse(_language),
        language: _language,
        details: {},
      );
    }
  }

  Future<LlmParsedResponse> sendVoiceMessage(String filePath, {String? prompt}) async {
    try {
      final response = await _apiClient.multipartRequest(
        url: ApiConstant.AI_CHAT,
        method: 'POST',
        fields: {
          'language': _language,
          if (prompt != null) 'prompt': prompt,
        },
        fileField: 'file',
        filePath: filePath,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['responseSuccessful'] == true && body['responseBody'] != null) {
          return LlmParsedResponse.fromJson(body['responseBody']);
        }
      } else {
        print("❌ AI Voice Chat HTTP Error: ${response.statusCode} - ${response.body}");
      }

      return LlmParsedResponse(
        intent: 'NONE',
        chatResponse: _getFallbackErrorResponse(_language),
        language: _language,
        details: {},
      );
    } catch (e) {
      print("LLM Voice Service Error: $e");
      return LlmParsedResponse(
        intent: 'NONE',
        chatResponse: _getFallbackErrorResponse(_language),
        language: _language,
        details: {},
      );
    }
  }

  void resetHistory() {
    // History is now managed backend-side
  }
}
