import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../feature/auth/authcontroller/authcontroller.dart';
import '../../app/utils/router/route_constant.dart';
import '../../core/local/transaction_cache.dart';
import 'package:go_router/go_router.dart';
import '../../feature/auth/interceptor/interceptor.dart';

enum SessionState { active, warning, loggedOut, locked }

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref ref;
  Timer? _inactivityTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 30;

  DateTime? _backgroundedAt;
  bool _isLockScreenVisible = false;

  // Routes that should NOT trigger inactivity logout
  final Set<String> _excludedRoutes = {
    RouteList.splash,
    RouteList.onBoardingScreen,
    RouteList.createAccountScreen,
    RouteList.createAccountVerifyOtpScreen,
    RouteList.loginScreen,
    RouteList.getStarted,
    RouteList.phoneRegScreen,
    RouteList.welcomeBackScreen,
    RouteList.forgotPassword,
    RouteList.forgotPasswordReset,
  };

  SessionNotifier(this.ref) : super(SessionState.active);

  int get remainingSeconds => _remainingSeconds;

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen('settingsBox')) {
      await Hive.openBox('settingsBox');
    }
  }

  Future<void> init([String? currentPath]) async {
    await _initBox();
    final isEnabled = Hive.box('settingsBox').get('auto_logout_enabled', defaultValue: true);
    if (isEnabled && currentPath != null) {
      handleRouteChange(currentPath);
    }
  }

  void handleRouteChange(String path) {
    if (_excludedRoutes.contains(path)) {
      _cancelTimers();
    } else {
      resetTimer(path);
    }
  }

  void _cancelTimers() {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    state = SessionState.active;
  }

  void resetTimer([String? currentPath]) async {
    if (currentPath != null && _excludedRoutes.contains(currentPath)) {
      _cancelTimers();
      return;
    }

    final box = await Hive.openBox('settingsBox');
    final isEnabled = box.get('auto_logout_enabled', defaultValue: true);
    
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    
    if (!isEnabled) {
      state = SessionState.active;
      return;
    }

    state = SessionState.active;
    _remainingSeconds = 30;

    final durationMinutes = box.get('auto_logout_duration', defaultValue: 5);
    _inactivityTimer = Timer(Duration(minutes: durationMinutes), () {
      _startWarning();
    });
  }

  void _startWarning() {
    state = SessionState.warning;
    _remainingSeconds = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        state = SessionState.warning; 
      } else {
        timer.cancel();
        logout();
      }
    });
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    state = SessionState.loggedOut;
    _isLockScreenVisible = false;
    _backgroundedAt = null;
    await ref.read(authControllerProvider.notifier).logout();
  }

  void clearLockState() {
    _isLockScreenVisible = false;
    _backgroundedAt = null;
  }

  void handleAppLifecycle(AppLifecycleState lifeCycleState, [String? currentPath]) {
    if (lifeCycleState == AppLifecycleState.paused || 
        lifeCycleState == AppLifecycleState.hidden) {
      // 🔐 App goes background: Preserve current stack/routes but set background time for lock evaluation
      if (currentPath != null && !_excludedRoutes.contains(currentPath) && !_isLockScreenVisible) {
        debugPrint("🔐 App backgrounded on protected route ($currentPath). Setting lock checkpoint.");
        _backgroundedAt = DateTime.now();
      }
    } else if (lifeCycleState == AppLifecycleState.resumed) {
      if (_backgroundedAt != null && currentPath != null && !_excludedRoutes.contains(currentPath)) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        debugPrint("🔐 App resumed. Time spent in background: ${elapsed.inSeconds} seconds.");
        
        final navContext = navigatorKey.currentContext;
        if (navContext != null && !_isLockScreenVisible) {
          _isLockScreenVisible = true;
          
          if (elapsed.inMinutes < 10) {
            // ⏰ Under 10 minutes: Unlock & pop back to the exact current screen (preserving stack)
            debugPrint("🔐 Within 10 min window. Pushing Welcome Back screen as session lock.");
            navContext.pushNamed(
              RouteList.welcomeBackScreen,
              extra: {'isSessionLock': true, 'forceHome': false},
            );
          } else {
            // 🚨 Over 10 minutes: Timeout. Force home/dashboard navigation after unlock, clear cached transaction states
            debugPrint("🔐 Timeout window exceeded. Pushing Welcome Back to unlock and redirect to Home.");
            TransactionCache.clearAllTransactions();
            
            navContext.pushNamed(
              RouteList.welcomeBackScreen,
              extra: {'isSessionLock': true, 'forceHome': true},
            );
          }
        }
      }
      _backgroundedAt = null;

      if (currentPath != null) {
        handleRouteChange(currentPath);
      } else {
        resetTimer();
      }
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final sessionServiceProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
