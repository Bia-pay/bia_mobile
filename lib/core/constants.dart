class Constants {
  Constants._();

  static String nairaCurrencySymbol = "₦";
  static String appName = 'bia ';
  static String prodFlavorName = 'production';
  static String devAppName = 'niigma Provider';
  static String devFlavorName = 'dev';

  static String prodBaseUrl = "https://lionfish-app-3tfc2.ondigitalocean.app/";
  static String devBaseUrl = "https://seashell-app-lq4vz.ondigitalocean.app/";

  static String termsUrl = "";
  static String privacyUrl = "";

  static const apiRequestTimeout = Duration(seconds: 30);
  static const animationDuration = Duration(milliseconds: 600);
}
class AppConstants {
  // 🌍 Base URL — Production API
  static const String baseUrl = 'https://api.bia.com.ng';
  
  // WebSocket URL (if different from base URL)
  static const String wsUrl = 'wss://api.bia.com.ng';

  // WebSocket feature flag - disable if backend doesn't support it
  static const bool enableWebSocket = true; // ✅ Enabled - backend supports WebSocket with header auth

}