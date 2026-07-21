import 'package:flutter/foundation.dart';

/// Centralized logger utility that ensures sensitive information
/// (API response bodies, tokens, PINs, HMAC keys) is NEVER logged to
/// the console/logcat in production/release mode.
class AppLogger {
  /// General debug log (suppressed automatically in release mode)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Info log
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Error log (only logs basic exception message, no raw payloads)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message ${error != null ? "($error)" : ""}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
