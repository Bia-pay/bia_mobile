import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import '../../../../app/utils/router/route_constant.dart';

class Splash extends ConsumerStatefulWidget {
  const Splash({super.key});

  @override
  ConsumerState<Splash> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<Splash> {
  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _handleFirstLaunch(); // ask notification permission
      await _checkAuthStatus();   // navigate
    });
  }

  Future<bool> requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _handleFirstLaunch() async {
    final box = await Hive.openBox('appBox');
    final isFirstLaunch = box.get('first_launch', defaultValue: true);

    if (isFirstLaunch) {
      final granted = await requestNotificationPermission();

      if (granted) {
        final fcm = await FirebaseMessaging.instance.getToken();
        final authBox = await Hive.openBox('authBox');
        await authBox.put('fcmToken', fcm);
      }

      await box.put('first_launch', false);
    }
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token");

      if (!mounted) return;

      if (token != null && token.toString().isNotEmpty) {
        context.go(RouteList.welcomeBackScreen);
      } else {
        context.go(RouteList.getStarted);
      }
    } catch (e) {
      if (!mounted) return;
      context.go(RouteList.getStarted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: accentColor,
        alignment: Alignment.center,
        child: Image.asset(splashLogo, height: 200.h),
      ),
    );
  }
}