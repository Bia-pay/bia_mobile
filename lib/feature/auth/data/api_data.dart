import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

import '../interceptor/interceptor.dart';
import 'api_constant.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final apiHelper = ref.read(apiHelperProvider); // inject ApiHelper
  return ApiClient(apiHelper: apiHelper);
});

class ApiClient {
  String? appBASE_URL = ApiConstant.BASE_URL;
  late Map<String, String> _mainHeaders;
  String token = "";
  final ApiHelper apiHelper;

  ApiClient({required this.apiHelper}) {
    final box = Hive.box('authBox');

    token = box.get('token', defaultValue: '') ?? '';

    _mainHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  void updateHeaders(String newToken) {
    token = newToken;
    _mainHeaders['Authorization'] = 'Bearer $token';
  }

  // ---------------- Refresh Token ----------------
  Future<bool> _refreshToken() async {
    final box = await Hive.openBox('authBox');
    final refreshToken = box.get('refreshToken') ?? '';

    if (refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConstant.REFRESH_TOKEN),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['responseBody'] ?? {};
        final newAccessToken = data['accessToken'] ?? '';
        final newRefreshToken = data['refreshToken'] ?? refreshToken;

        await box.put('token', newAccessToken);
        await box.put('refreshToken', newRefreshToken);

        updateHeaders(newAccessToken);

        print('🔄 Token refreshed successfully');
        return true;
      } else {
        print('❌ Failed to refresh token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('🔥 Exception refreshing token: $e');
      return false;
    }
  }

  // ---------------- Authorized Request Wrapper ----------------
  Future<http.Response> _authorizedRequest(
      Future<http.Response> Function() apiCall) async {
    http.Response response = await apiCall();

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        response = await apiCall();
      }
    }

    return response;
  }

  // ---------------- POST ----------------
  Future<http.Response> postData(String url, Map<String, dynamic> body) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

      print("➡️ POST $fullUrl");
      print("➡️ Headers: $_mainHeaders");
      print("➡️ Body: $body");

      final response = await http.post(
        fullUrl,
        headers: _mainHeaders,
        body: jsonEncode(body),
      );

      return apiHelper.handleResponse(response);
    });
  }

  // ---------------- PATCH ----------------
  Future<http.Response> patchData(String url, Map<String, dynamic> body) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

      print("➡️ PATCH $fullUrl");
      print("➡️ Headers: $_mainHeaders");
      print("➡️ Body: $body");

      final response = await http.patch(
        fullUrl,
        headers: _mainHeaders,
        body: jsonEncode(body),
      );

      return apiHelper.handleResponse(response);
    });
  }

  // ---------------- PUT ----------------
  Future<http.Response> putData(String url, Map<String, dynamic> body) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

      print("➡️ PUT $fullUrl");
      print("➡️ Headers: $_mainHeaders");
      print("➡️ Body: $body");

      final response = await http.put(
        fullUrl,
        headers: _mainHeaders,
        body: jsonEncode(body),
      );

      return apiHelper.handleResponse(response);
    });
  }

  // ---------------- GET ----------------
  Future<http.Response> getData(String url) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

      print("➡️ GET $fullUrl");
      print("➡️ Headers: $_mainHeaders");

      final response = await http.get(
        fullUrl,
        headers: _mainHeaders,
      );

      return apiHelper.handleResponse(response);
    });
  }

  // ---------------- POST PHOTO / Multipart ----------------
  Future<http.StreamedResponse> postPhoto(String url, String imagePath) async {
    var headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'text/plain',
      'Authorization': 'Bearer $token'
    };

    var request =
    http.MultipartRequest('POST', Uri.parse(ApiConstant.BASE_URL + url));
    request.fields.addAll({'URL': url});
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry multipart request
        request.headers['Authorization'] = 'Bearer $token';
        response = await request.send();
      }
    }

    return response;
  }
}