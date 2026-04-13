import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Global navigator key — register this in MaterialApp so that ApiClient
/// can forcibly navigate to the login screen when a token refresh fails.
///
/// Usage in MaterialApp:
///   navigatorKey: navigatorKey,
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiHelper {
  Future<http.Response> handleResponse(http.Response response) async {
    // 401 is handled centrally inside ApiClient._authorizedRequest().
    // Nothing to do here — just return the response as-is.
    return response;
  }
}

// ✅ Provider for ApiHelper
final apiHelperProvider = Provider<ApiHelper>((ref) {
  return ApiHelper();
});
