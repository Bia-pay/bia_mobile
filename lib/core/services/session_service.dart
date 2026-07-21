import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../feature/auth/authcontroller/authcontroller.dart';
import '../../app/utils/router/route_constant.dart';
import 'package:go_router/go_router.dart';
import '../../feature/auth/interceptor/interceptor.dart';

enum SessionState { active, warning, loggedOut, locked }

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref ref;
  Timer? _inactivityTimer;

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
    state = SessionState.active;
  }

  void resetTimer([String? currentPath]) async {
    if (currentPath != null && _excludedRoutes.contains(currentPath)) {
      _cancelTimers();
      return;
    }

    final box = await Hive.openBox('settingsBox');
    final isEnabled = box.get('auto_logout_enabled', defaultValue: true);
    final durationMinutes = box.get('auto_logout_duration', defaultValue: 5) as int;

    _inactivityTimer?.cancel();

    if (!isEnabled) {
      state = SessionState.active;
      return;
    }

    state = SessionState.active;

    // Lock after preferred duration of inactivity
    _inactivityTimer = Timer(Duration(minutes: durationMinutes), lockSession);
  }

  void lockSession() {
    _inactivityTimer?.cancel();
    if (_isLockScreenVisible || state == SessionState.locked) {
      debugPrint("🔐 lockSession: Session is already locked or lock screen is visible. Skipping push.");
      return;
    }
    state = SessionState.locked;
    _isLockScreenVisible = true;
    _backgroundedAt = null;

    final navContext = navigatorKey.currentContext;
    if (navContext != null) {
      // forceHome: false so user resumes wherever they were after re-auth
      navContext.pushNamed(
        RouteList.welcomeBackScreen,
        extra: {'isSessionLock': true, 'forceHome': false},
      );
    }
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    state = SessionState.loggedOut;
    _isLockScreenVisible = false;
    _backgroundedAt = null;
    await ref.read(authControllerProvider.notifier).logout();
  }

  void clearLockState() {
    _isLockScreenVisible = false;
    _backgroundedAt = null;
    state = SessionState.active;
  }

  bool _bypassLifecycle = false;

  void setBypassLifecycle(bool value) {
    debugPrint("🔐 Setting bypass lifecycle to: $value");
    _bypassLifecycle = value;
  }

  void handleAppLifecycle(AppLifecycleState lifeCycleState, [String? currentPath]) {
    if (_bypassLifecycle) {
      debugPrint("🔐 Bypassing lifecycle state changes ($lifeCycleState) because bypassLifecycle is true.");
      if (lifeCycleState == AppLifecycleState.resumed) {
        _backgroundedAt = null;
      }
      return;
    }

    if (lifeCycleState == AppLifecycleState.paused || 
        lifeCycleState == AppLifecycleState.hidden) {
      // 🔐 App goes background: Preserve current stack/routes but set background time for lock evaluation
      if (currentPath != null && !_excludedRoutes.contains(currentPath) && !_isLockScreenVisible) {
        debugPrint("🔐 App backgrounded on protected route ($currentPath). Setting lock checkpoint.");
        _backgroundedAt = DateTime.now();
      }
    } else if (lifeCycleState == AppLifecycleState.resumed) {
      if (_backgroundedAt != null && currentPath != null && !_excludedRoutes.contains(currentPath)) {
        if (!_isLockScreenVisible) {
          final navContext = navigatorKey.currentContext;
          if (navContext != null) {
            _isLockScreenVisible = true;
            // Always resume the exact screen the user was on after re-auth
            navContext.pushNamed(
              RouteList.welcomeBackScreen,
              extra: {'isSessionLock': true, 'forceHome': false},
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
    super.dispose();
  }
}

final sessionServiceProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
