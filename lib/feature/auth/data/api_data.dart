
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
  final ApiHelper apiHelper; // 🔑 inject ApiHelper

  ApiClient({required this.apiHelper}) {
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

  // // ---------------- POST ----------------
  // Future<http.Response> postData(String url, body) async {
  //   print('got to api client');
  //   try {
  //     final response = await http.post(
  //       Uri.parse(ApiConstant.BASE_URL + url),
  //       headers: _mainHeaders,
  //       body: body,
  //     );

  //     print(ApiConstant.BASE_URL + url);

  //     // ✅ always pass through apiHelper
  //     return apiHelper.handleResponse(response);
  //   } on TimeoutException {
  //     return http.Response('Network Timeout', 500);
  //   } catch (e) {
  //     return http.Response('Error: $e', 504);
  //   }
  // }


Future<http.Response> postData(String url, Map<String, dynamic> body) async {
  print('got to api client');

  try {
    final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

    print("➡️ POST $fullUrl");
    print("➡️ Headers: $_mainHeaders");
    print("➡️ Body: $body");

    final response = await http.post(
      fullUrl,
      headers: _mainHeaders,
      body: jsonEncode(body), // ✅ encode map to JSON
    );

    return apiHelper.handleResponse(response);
  } on TimeoutException {
    return http.Response('Network Timeout', 500);
  } catch (e) {
    return http.Response('Error: $e', 504);
  }
}


  // ---------------- PATCH ----------------
  Future<http.Response> patchData(String url, body) async {
    print('got to api client');
    try {
      final response = await http.patch(
        Uri.parse(ApiConstant.BASE_URL + url),
        headers: _mainHeaders,
        body: body,
      );

      print(ApiConstant.BASE_URL + url);

      // ✅ always pass through apiHelper
      return apiHelper.handleResponse(response);
    } on TimeoutException {
      return http.Response('Network Timeout', 500);
    } catch (e) {
      return http.Response('Error: $e', 504);
    }
  }

  // ---------------- PUT ----------------
  Future<http.Response> putData(String url, body) async {
    print('This is token $token');
    try {
      final response = await http.put(
        Uri.parse(ApiConstant.BASE_URL + url),
        body: body,
        headers: _mainHeaders,
      );

      // ✅ always pass through apiHelper
      return apiHelper.handleResponse(response);
    } on TimeoutException {
      return http.Response("Network Timeout", 500);
    } catch (e) {
      return http.Response('Error: $e', 504);
    }
  }

  // ---------------- GET ----------------
  Future<http.Response> getData(String url) async {
    print('got to api client');
    try {
      final response = await http.get(
        Uri.parse(ApiConstant.BASE_URL + url),
        headers: _mainHeaders,
      );

      // ✅ always pass through apiHelper
      return apiHelper.handleResponse(response);
    } on TimeoutException {
      return http.Response('Network Timeout', 500);
    } catch (e) {
      return http.Response('Error: $e', 504);
    }
  }

  // ---------------- POST PHOTO ----------------
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

    final response = await request.send();

    // ⚠️ NOTE: `MultipartRequest` returns `StreamedResponse`,
    // you can’t run it through apiHelper directly.
    // Instead, listen to `response.statusCode` manually.
    if (response.statusCode == 401) {
      await apiHelper.onTokenExpired(); // 🔑 handle expired token
    }

    return response;
  }
}
