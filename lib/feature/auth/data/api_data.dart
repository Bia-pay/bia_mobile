import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../../../app/socket/socket_provider.dart';
import '../interceptor/interceptor.dart';
import 'api_constant.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final apiHelper = ref.read(apiHelperProvider);
  return ApiClient(apiHelper: apiHelper, ref: ref);
});

class ApiClient {
  String? appBASE_URL = ApiConstant.BASE_URL;
  late Map<String, String> _mainHeaders;
  String token = '';
  String _userId = '';

  final ApiHelper apiHelper;
  final Ref ref;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Mutex: ensures only ONE refresh call runs at a time ──────────────────
  Completer<bool>? _refreshCompleter;

  // ── Per-user secure storage key helpers ──────────────────────────────────
  String _tokenKey(String userId) => 'access_token_$userId';
  String _refreshTokenKey(String userId) => 'refresh_token_$userId';

  ApiClient({required this.apiHelper, required this.ref}) {
    final box = Hive.box('authBox');
    token = box.get('token', defaultValue: '') ?? '';
    _userId = box.get('userId', defaultValue: '') ?? '';

    _mainHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Called after a successful login to prime the client ──────────────────
  Future<void> initForUser(
    String userId,
    String accessToken,
    String refreshToken,
  ) async {
    _userId = userId;
    token = accessToken;
    _mainHeaders['Authorization'] = 'Bearer $token';

    // Store tokens securely per user
    await _storage.write(key: _tokenKey(userId), value: accessToken);
    await _storage.write(key: _refreshTokenKey(userId), value: refreshToken);

    debugPrint('🔐 ApiClient primed for user: $userId');
  }

  void dispose() {
    // No-op: timer removed. Refresh is now purely reactive (on 401).
  }

  void updateHeaders(String newToken) {
    token = newToken;
    _mainHeaders['Authorization'] = 'Bearer $token';
  }

  // ── Force logout: clears tokens + navigates to login ─────────────────────
  Future<void> _forceLogout() async {
    debugPrint('🚪 Force logout triggered — clearing tokens');

    try {
      // Clear per-user secure tokens
      if (_userId.isNotEmpty) {
        await _storage.delete(key: _tokenKey(_userId));
        await _storage.delete(key: _refreshTokenKey(_userId));
      }

      // Clear Hive tokens (keep userId, phone, fullname for WelcomeBack screen)
      final box = await Hive.openBox('authBox');
      await box.delete('token');
      await box.delete('refreshToken');

      token = '';
      _mainHeaders['Authorization'] = 'Bearer ';
    } catch (e) {
      debugPrint('❌ Error during force logout: $e');
    }

    // Navigate using GoRouter — compatible with MaterialApp.router
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentContext?.go('/login');
    });
  }

  // ── Mutex-protected token refresh ─────────────────────────────────────────
  Future<bool> _refreshToken() async {
    // If a refresh is already in-flight, wait for it instead of starting another
    if (_refreshCompleter != null) {
      debugPrint('⏳ Token refresh already in-flight — waiting...');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    debugPrint('🔄 Starting token refresh...');

    try {
      // Read refresh token from SecureStorage (preferring user-scoped key)
      String refreshToken = '';
      if (_userId.isNotEmpty) {
        refreshToken =
            await _storage.read(key: _refreshTokenKey(_userId)) ?? '';
      }

      // Fallback to Hive if SecureStorage doesn't have it yet
      if (refreshToken.isEmpty) {
        final box = await Hive.openBox('authBox');
        refreshToken = box.get('refreshToken', defaultValue: '') ?? '';
      }

      if (refreshToken.isEmpty) {
        debugPrint('❌ No refresh token available — forcing logout');
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        await _forceLogout();
        return false;
      }

      final fullRefreshUrl =
          Uri.parse('${ApiConstant.BASE_URL}${ApiConstant.REFRESH_TOKEN}');

      final response = await http.post(
        fullRefreshUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['responseBody'] ?? {};
        final newAccessToken = data['accessToken'] ?? '';
        final newRefreshToken = data['refreshToken'] ?? refreshToken;

        if (newAccessToken.isEmpty) {
          debugPrint('❌ Refresh response missing accessToken');
          _refreshCompleter!.complete(false);
          _refreshCompleter = null;
          await _forceLogout();
          return false;
        }

        // Persist updated tokens
        final box = await Hive.openBox('authBox');
        await box.put('token', newAccessToken);
        await box.put('refreshToken', newRefreshToken);

        if (_userId.isNotEmpty) {
          await _storage.write(
              key: _tokenKey(_userId), value: newAccessToken);
          await _storage.write(
              key: _refreshTokenKey(_userId), value: newRefreshToken);
        }

        updateHeaders(newAccessToken);
        
        // 🔥 Trigger socket reconnection to sync new token with FCM on backend
        ref.read(socketNotifierProvider.notifier).reconnect();

        debugPrint('✅ Token refreshed successfully and socket resynced for user: $_userId');
        _refreshCompleter!.complete(true);
        _refreshCompleter = null;
        return true;
      } else {
        debugPrint(
            '❌ Refresh request failed (${response.statusCode}) — forcing logout');
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        await _forceLogout();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception during token refresh: $e');
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      await _forceLogout();
      return false;
    }
  }

  // ── Central authorized request wrapper ────────────────────────────────────
  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function() apiCall,
  ) async {
    http.Response response = await apiCall();

    if (response.statusCode == 401) {
      // 💡 Optimization: If the 401 is actually a wrong PIN error, don't refresh.
      // This prevents the app from logging the user out when they just entered
      // a wrong PIN (as the server might invalidate refresh tokens on PIN failure).
      final body = response.body.toLowerCase();
      if (body.contains('pin') || body.contains('incorrect') || body.contains('invalid')) {
        debugPrint('⚠️ 401 received but appears to be a PIN error — skipping refresh.');
        return response;
      }

      debugPrint('⚠️ 401 received — attempting token refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        debugPrint('🔁 Retrying request after successful token refresh...');
        response = await apiCall();
      }
      // If refresh failed, _forceLogout() was already called inside _refreshToken()
    }

    return response;
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<http.Response> postData(
      String url, Map<String, dynamic> body) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      debugPrint('📤 POST $fullUrl');
      final response = await http.post(
        fullUrl,
        headers: _mainHeaders,
        body: jsonEncode(body),
      );
      return apiHelper.handleResponse(response);
    });
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────
  Future<http.Response> patchData(
      String url, Map<String, dynamic> body) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      debugPrint('📤 PATCH $fullUrl');
      final response = await http.patch(
        fullUrl,
        headers: _mainHeaders,
        body: jsonEncode(body),
      );
      return apiHelper.handleResponse(response);
    });
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<http.Response> putData(
      String url, Map<String, dynamic> body) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      debugPrint('📤 PUT $fullUrl');
      final response = await http.put(
        fullUrl,
        headers: _mainHeaders,
        body: jsonEncode(body),
      );
      return apiHelper.handleResponse(response);
    });
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<http.Response> getData(String url) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      debugPrint('📥 GET $fullUrl');
      final response = await http.get(
        fullUrl,
        headers: _mainHeaders,
      );
      return apiHelper.handleResponse(response);
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<http.Response> deleteData(String url) async {
    return _authorizedRequest(() async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      debugPrint('🗑️ DELETE $fullUrl');
      final response = await http.delete(
        fullUrl,
        headers: _mainHeaders,
      );
      return apiHelper.handleResponse(response);
    });
  }

  // ── POST PHOTO / Multipart ────────────────────────────────────────────────
  Future<http.StreamedResponse> postPhoto(
      String url, String imagePath) async {
    var headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'text/plain',
      'Authorization': 'Bearer $token',
    };

    final request =
        http.MultipartRequest('POST', Uri.parse(ApiConstant.BASE_URL + url));
    request.fields.addAll({'URL': url});
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        request.headers['Authorization'] = 'Bearer $token';
        response = await request.send();
      }
    }

    return response;
  }

  // ── MULTIPART (generic) ───────────────────────────────────────────────────
  Future<http.Response> multipartRequest({
    required String url,
    required String method,
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
  }) async {
    final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

    final request = http.MultipartRequest(method, fullUrl);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);
    request.files.add(
      await http.MultipartFile.fromPath(fileField, filePath),
    );

    debugPrint('📤 MULTIPART $method $fullUrl');

    http.StreamedResponse streamedResponse = await request.send();

    if (streamedResponse.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        request.headers['Authorization'] = 'Bearer $token';
        streamedResponse = await request.send();
      }
    }

    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('🟢 STATUS: ${response.statusCode}');
    return response;
  }
}