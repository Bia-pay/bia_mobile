import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class PinLockoutStatus {
  final bool isLocked;
  final bool isPermanentlyFrozen;
  final Duration remainingTime;
  final int failedAttempts;

  PinLockoutStatus({
    required this.isLocked,
    required this.isPermanentlyFrozen,
    required this.remainingTime,
    required this.failedAttempts,
  });
}

class SecurityService {
  static const String _attemptsKey = 'pin_failed_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';

  /// Register a failed PIN attempt and update lockout status if needed.
  static Future<void> registerFailure() async {
    final box = await Hive.openBox('authBox');
    int attempts = box.get(_attemptsKey, defaultValue: 0) + 1;
    await box.put(_attemptsKey, attempts);

    DateTime? lockoutUntil;
    
    if (attempts >= 9) {
      // Permanent Freeze
      lockoutUntil = DateTime(2999, 12, 31);
    } else if (attempts >= 6) {
      // 24 Hour Lock
      lockoutUntil = DateTime.now().add(const Duration(hours: 24));
    } else if (attempts >= 3) {
      // 30 Minute Lock
      lockoutUntil = DateTime.now().add(const Duration(minutes: 30));
    }

    if (lockoutUntil != null) {
      await box.put(_lockoutUntilKey, lockoutUntil.toIso8601String());
    }
    
    debugPrint('🔐 SecurityService: Registered failure #$attempts. Lockout: $lockoutUntil');
  }

  /// Clear all failures upon successful PIN entry.
  static Future<void> clearFailures() async {
    final box = await Hive.openBox('authBox');
    await box.delete(_attemptsKey);
    await box.delete(_lockoutUntilKey);
    debugPrint('🔐 SecurityService: Failures cleared.');
  }

  /// Get current lockout status.
  static Future<PinLockoutStatus> getLockoutStatus() async {
    final box = await Hive.openBox('authBox');
    final int attempts = box.get(_attemptsKey, defaultValue: 0);
    final String? lockoutUntilStr = box.get(_lockoutUntilKey);
    
    if (lockoutUntilStr == null) {
      return PinLockoutStatus(
        isLocked: false,
        isPermanentlyFrozen: false,
        remainingTime: Duration.zero,
        failedAttempts: attempts,
      );
    }

    final DateTime lockoutUntil = DateTime.parse(lockoutUntilStr);
    final DateTime now = DateTime.now();
    
    if (now.isAfter(lockoutUntil)) {
      // Lockout expired - we don't clear attempts automatically, 
      // but the user is no longer locked.
      return PinLockoutStatus(
        isLocked: false,
        isPermanentlyFrozen: false,
        remainingTime: Duration.zero,
        failedAttempts: attempts,
      );
    }

    final bool isPermanent = lockoutUntil.year > 2100;
    
    return PinLockoutStatus(
      isLocked: true,
      isPermanentlyFrozen: isPermanent,
      remainingTime: lockoutUntil.difference(now),
      failedAttempts: attempts,
    );
  }

  /// Manually reset a lockout (e.g. for testing or support)
  static Future<void> resetLockout() async {
    final box = await Hive.openBox('authBox');
    await box.delete(_attemptsKey);
    await box.delete(_lockoutUntilKey);
  }
}
