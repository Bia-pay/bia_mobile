import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../feature/auth/authcontroller/authcontroller.dart';
import '../../app/utils/router/route_constant.dart';


enum SessionState { active, warning, loggedOut }

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref ref;
  Timer? _inactivityTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 30;

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


  SessionNotifier(this.ref) : super(SessionState.active) {
    // We don't call _init in constructor to avoid async issues in initializer
  }

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
    // If we're on an excluded page, don't run the timer
    if (currentPath != null && _excludedRoutes.contains(currentPath)) {
      _cancelTimers();
      return;
    }


    // Ensure box is open
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
        // Re-assign state to notify listeners of the time change
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
    // Call the unified logout in AuthController
    await ref.read(authControllerProvider.notifier).logout();
  }

  void handleAppLifecycle(AppLifecycleState lifeCycleState, [String? currentPath]) {
    if (lifeCycleState == AppLifecycleState.paused || 
        lifeCycleState == AppLifecycleState.hidden) {
      // Security: Logout immediately if the app is backgrounded from a protected screen
      if (currentPath != null && !_excludedRoutes.contains(currentPath)) {
        debugPrint("🔐 App backgrounded on protected route ($currentPath). Triggering auto-logout.");
        logout();
      }
    } else if (lifeCycleState == AppLifecycleState.resumed) {
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
