

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Use this global key in your MaterialApp
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiHelper {
  Future<http.Response> handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await onTokenExpired();
    }
    return response;
  }

  Future<void> onTokenExpired() async {
    debugPrint("⚠️ Token expired, redirecting to PasscodeLogin");

    // navigatorKey.currentState?.pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (_) => const PasscodeLogin()),
    //   (route) => false,
    // );
  }
}

// ✅ provider for ApiHelper
final apiHelperProvider = Provider<ApiHelper>((ref) {
  return ApiHelper();
});

