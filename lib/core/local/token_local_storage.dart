import 'package:shared_preferences/shared_preferences.dart';

class TokenLocalStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _nameKey = 'user_name';
  static const String _passwordKey = 'user_password';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? name,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    if (name != null) await prefs.setString(_nameKey, name);
    if (password != null) await prefs.setString(_passwordKey, password);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_passwordKey);
  }
}