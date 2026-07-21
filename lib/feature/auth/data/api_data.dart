import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import '../../../core/utils/app_logger.dart';
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

  Future<void>? _initFuture;

  // ── Server clock sync fields ─────────────────────────────────────────────
  int _clockOffset = 0;
  Future<void>? _timeSyncFuture;

  ApiClient({required this.apiHelper, required this.ref}) {
    // Initial sync load from Hive (legacy fallback)
    if (Hive.isBoxOpen('authBox')) {
      final box = Hive.box('authBox');
      token = box.get('token', defaultValue: '') ?? '';
      _userId = box.get('userId', defaultValue: '') ?? '';
    }

    _mainHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Immediately start async load from SecureStorage
    _initFuture = _ensureTokensLoaded();
  }

  Future<void> _ensureTokensLoaded() async {
    try {
      if (_userId.isEmpty) {
        final box = await Hive.openBox('authBox');
        _userId = box.get('userId', defaultValue: '') ?? '';
      }

      if (_userId.isNotEmpty) {
        final secureToken = await _storage.read(key: _tokenKey(_userId));
        if (secureToken != null && secureToken.isNotEmpty) {
          token = secureToken;
          _mainHeaders['Authorization'] = 'Bearer $token';
          debugPrint(
            '🔐 Tokens loaded securely from storage for user: $_userId',
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading secure tokens: $e');
    }
  }

  Future<void> _waitForInit() async {
    if (_initFuture != null) {
      await _initFuture;
      _initFuture = null;
    }
  }

  Future<void> initForUser(
    String userId,
    String accessToken,
    String refreshToken,
  ) async {
    _userId = userId;
    token = accessToken;
    _mainHeaders['Authorization'] = 'Bearer $token';

    // Store tokens securely per user and set session keys in parallel
    await Future.wait([
      _storage.write(key: _tokenKey(userId), value: accessToken),
      _storage.write(key: _refreshTokenKey(userId), value: refreshToken),
      _storage.write(key: 'is_logged_in', value: 'true'),
      _storage.write(key: 'access_token', value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
      _storage.write(key: 'user_id', value: userId),
    ]);

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

      // Clear centralized session secure storage keys (Requirement 8)
      await _storage.delete(key: 'is_logged_in');
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');

      // Hive tokens are no longer used for "Highly Secure" mode.
      // final box = await Hive.openBox('authBox');
      // await box.delete('token');
      // await box.delete('refreshToken');

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
      await _ensureTimeSynced();
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

      final fullRefreshUrl = Uri.parse(
        '${ApiConstant.BASE_URL}${ApiConstant.REFRESH_TOKEN}',
      );

      final payloadJson = jsonEncode({'refreshToken': refreshToken});
      final String timestamp = _getAdjustedTimestamp();
      final String dataToSign = "$timestamp.$payloadJson";
      final List<int> key = utf8.encode(
        'bia_hmac_secret_key_2026_07_10_console',
      );
      final List<int> bytes = utf8.encode(dataToSign);
      final Hmac hmacSha256 = Hmac(sha256, key);
      final Digest digest = hmacSha256.convert(bytes);

      final response = await http.post(
        fullRefreshUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-timestamp': timestamp,
          'x-signature': digest.toString(),
        },
        body: payloadJson,
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

        // Tokens are now stored exclusively in SecureStorage for "Highly Secure" mode.
        // We stop writing them to the unencrypted Hive box.
        // final box = await Hive.openBox('authBox');
        // await box.put('token', newAccessToken);
        // await box.put('refreshToken', newRefreshToken);

        if (_userId.isNotEmpty) {
          await _storage.write(key: _tokenKey(_userId), value: newAccessToken);
          await _storage.write(
            key: _refreshTokenKey(_userId),
            value: newRefreshToken,
          );
        }

        updateHeaders(newAccessToken);

        // 🔥 Trigger socket reconnection to sync new token with FCM on backend
        ref.read(socketNotifierProvider.notifier).reconnect();

        debugPrint(
          '✅ Token refreshed successfully and socket resynced for user: $_userId',
        );
        _refreshCompleter!.complete(true);
        _refreshCompleter = null;
        return true;
      } else {
        debugPrint(
          '❌ Refresh request failed (${response.statusCode}) — forcing logout',
        );
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

  // ── Server Time Sync Helpers ────────────────────────────────────────────────
  String _getAdjustedTimestamp() {
    final int localMillis = DateTime.now().millisecondsSinceEpoch;
    return (localMillis + _clockOffset).toString();
  }

  Future<void> _ensureTimeSynced() async {
    _timeSyncFuture ??= _syncTime();
    await _timeSyncFuture;
  }

  Future<void> _syncTime() async {
    try {
      debugPrint('⏰ Syncing time with server...');
      final response = await http.head(Uri.parse(ApiConstant.BASE_URL)).timeout(
        const Duration(seconds: 5),
      );
      final dateHeader = response.headers['date'];
      if (dateHeader != null) {
        final serverTime = HttpDate.parse(dateHeader);
        final clientTime = DateTime.now().toUtc();
        _clockOffset = serverTime.millisecondsSinceEpoch - clientTime.millisecondsSinceEpoch;
        debugPrint(
          '⏰ Time synced. Offset: $_clockOffset ms (Server: $serverTime, Client: $clientTime)',
        );
      } else {
        debugPrint('⚠️ Date header missing in time sync response');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync time with server: $e');
    }
  }

  // ── HMAC Signature Helper ──────────────────────────────────────────────────
  Map<String, String> _getRequestHeaders(String payloadJson) {
    final headers = Map<String, String>.from(_mainHeaders);
    final String sharedSecret = 'bia_hmac_secret_key_2026_07_10_console';

    final String timestamp = _getAdjustedTimestamp();
    final String dataToSign = "$timestamp.$payloadJson";

    final List<int> key = utf8.encode(sharedSecret);
    final List<int> bytes = utf8.encode(dataToSign);
    final Hmac hmacSha256 = Hmac(sha256, key);
    final Digest digest = hmacSha256.convert(bytes);

    headers['x-timestamp'] = timestamp;
    headers['x-signature'] = digest.toString();
    return headers;
  }

  // ── Central authorized request wrapper ────────────────────────────────────
  Future<http.Response> _authorizedRequest(
    String url,
    Future<http.Response> Function() apiCall,
  ) async {
    await _ensureTimeSynced();
    final isPublic = url.contains('/auth/') || url.contains('/services/status');
    if (!isPublic) {
      await _waitForInit();
    }
    http.Response response = await apiCall();

    if (response.statusCode == 401) {
      final body = response.body.toLowerCase();
      // Check for timestamp/expired error first to self-heal clock drift
      if (body.contains('timestamp') || body.contains('expired')) {
        AppLogger.debug('⏰ Timestamp/HMAC error detected. Re-syncing time and retrying...');
        _timeSyncFuture = null; // force re-sync
        await _ensureTimeSynced();
        // Retry the call
        response = await apiCall();
        return response;
      }

      // 💡 Optimization: If the 401 is actually a wrong PIN error, don't refresh.
      if (body.contains('pin') ||
          body.contains('incorrect') ||
          body.contains('invalid')) {
        AppLogger.debug('⚠️ 401 received but appears to be a PIN error — skipping refresh.');
        return response;
      }

      AppLogger.debug('⚠️ 401 received — attempting token refresh...');
      final refreshed = await _refreshToken();
      if (refreshed) {
        AppLogger.debug('🔁 Retrying request after successful token refresh...');
        response = await apiCall();
      }
    }

    return response;
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<http.Response> postData(String url, Map<String, dynamic> body) async {
    final cleanedBody = _sanitizeBody(body);
    return _authorizedRequest(url, () async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      AppLogger.debug('📤 POST $fullUrl');
      final payloadJson = jsonEncode(cleanedBody);
      final response = await http.post(
        fullUrl,
        headers: _getRequestHeaders(payloadJson),
        body: payloadJson,
      );
      AppLogger.debug('📥 RESPONSE [${response.statusCode}] $url');
      return apiHelper.handleResponse(response);
    });
  }

  // ── PATCH ─────────────────────────────────────────────────────────────────
  Future<http.Response> patchData(String url, Map<String, dynamic> body) async {
    final cleanedBody = _sanitizeBody(body);
    return _authorizedRequest(url, () async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      AppLogger.debug('📤 PATCH $fullUrl');
      final payloadJson = jsonEncode(cleanedBody);
      final response = await http.patch(
        fullUrl,
        headers: _getRequestHeaders(payloadJson),
        body: payloadJson,
      );
      AppLogger.debug('📥 RESPONSE [${response.statusCode}] $url');
      return apiHelper.handleResponse(response);
    });
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<http.Response> putData(String url, Map<String, dynamic> body) async {
    final cleanedBody = _sanitizeBody(body);
    return _authorizedRequest(url, () async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      AppLogger.debug('📤 PUT $fullUrl');
      final payloadJson = jsonEncode(cleanedBody);
      final response = await http.put(
        fullUrl,
        headers: _getRequestHeaders(payloadJson),
        body: payloadJson,
      );
      AppLogger.debug('📥 RESPONSE [${response.statusCode}] $url');
      return apiHelper.handleResponse(response);
    });
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<http.Response> getData(String url) async {
    return _authorizedRequest(url, () async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      AppLogger.debug('📥 GET $fullUrl');
      final response = await http.get(
        fullUrl,
        headers: _getRequestHeaders('{}'),
      );
      AppLogger.debug('📥 RESPONSE [${response.statusCode}] $url');
      return apiHelper.handleResponse(response);
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<http.Response> deleteData(String url) async {
    return _authorizedRequest(url, () async {
      final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);
      AppLogger.debug('🗑️ DELETE $fullUrl');
      final response = await http.delete(
        fullUrl,
        headers: _getRequestHeaders('{}'),
      );
      AppLogger.debug('📥 RESPONSE [${response.statusCode}] $url');
      return apiHelper.handleResponse(response);
    });
  }

  // ── POST PHOTO / Multipart ────────────────────────────────────────────────
  Future<http.StreamedResponse> postPhoto(String url, String imagePath) async {
    await _ensureTimeSynced();
    final String timestamp = _getAdjustedTimestamp();
    final String dataToSign = "$timestamp.{}";
    final List<int> key = utf8.encode('bia_hmac_secret_key_2026_07_10_console');
    final List<int> bytes = utf8.encode(dataToSign);
    final Hmac hmacSha256 = Hmac(sha256, key);
    final Digest digest = hmacSha256.convert(bytes);

    var headers = {
      'Content-Type': 'multipart/form-data',
      'Accept': 'text/plain',
      'Authorization': 'Bearer $token',
      'x-timestamp': timestamp,
      'x-signature': digest.toString(),
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstant.BASE_URL + url),
    );
    request.fields.addAll({'URL': url});
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        request.headers['Authorization'] = 'Bearer $token';
        // Regenerate signature if token refreshed
        final String newTimestamp = _getAdjustedTimestamp();
        final String newDataToSign = "$newTimestamp.{}";
        final List<int> newBytes = utf8.encode(newDataToSign);
        final Digest newDigest = Hmac(sha256, key).convert(newBytes);
        request.headers['x-timestamp'] = newTimestamp;
        request.headers['x-signature'] = newDigest.toString();

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
    await _ensureTimeSynced();
    final fullUrl = Uri.parse(ApiConstant.BASE_URL + url);

    final request = http.MultipartRequest(method, fullUrl);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    final String timestamp = _getAdjustedTimestamp();
    final String dataToSign = "$timestamp.{}";
    final List<int> key = utf8.encode('bia_hmac_secret_key_2026_07_10_console');
    final List<int> bytes = utf8.encode(dataToSign);
    final Hmac hmacSha256 = Hmac(sha256, key);
    final Digest digest = hmacSha256.convert(bytes);
    request.headers['x-timestamp'] = timestamp;
    request.headers['x-signature'] = digest.toString();

    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    debugPrint('📤 MULTIPART $method $fullUrl');

    http.StreamedResponse streamedResponse = await request.send();

    if (streamedResponse.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        request.headers['Authorization'] = 'Bearer $token';
        // Regenerate signature if token refreshed
        final String newTimestamp = _getAdjustedTimestamp();
        final String newDataToSign = "$newTimestamp.{}";
        final List<int> newBytes = utf8.encode(newDataToSign);
        final Digest newDigest = Hmac(sha256, key).convert(newBytes);
        request.headers['x-timestamp'] = newTimestamp;
        request.headers['x-signature'] = newDigest.toString();

        streamedResponse = await request.send();
      }
    }

    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('🟢 STATUS: ${response.statusCode}');
    return response;
  }

  // ── Recursive Payload Sanitizer ────────────────────────────────────────────
  Map<String, dynamic> _sanitizeBody(Map<String, dynamic> body) {
    final Map<String, dynamic> cleaned = {};
    body.forEach((key, value) {
      if (value != null) {
        cleaned[key] = _sanitizeValue(value);
      }
    });
    return cleaned;
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      final Map<dynamic, dynamic> cleanedMap = {};
      value.forEach((k, v) {
        if (v != null) {
          cleanedMap[k] = _sanitizeValue(v);
        }
      });
      return cleanedMap;
    } else if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => _sanitizeValue(item))
          .toList();
    } else if (value is double) {
      if (value % 1 == 0) {
        return value.toInt();
      }
      return value;
    }
    return value;
  }
}
