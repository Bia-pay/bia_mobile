import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> post(
      String url, {
        required Map<String, dynamic> body,
      }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.body.isEmpty) {
      return {'responseSuccessful': false, 'responseMessage': 'No response body'};
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['responseMessage'] ?? 'Request failed');
    }
  }
}