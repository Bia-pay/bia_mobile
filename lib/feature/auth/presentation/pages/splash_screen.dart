import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    // Reduce artificial delay from 2 seconds to 1 second
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final box = await Hive.openBox("authBox");
      final token = box.get("token");
      debugPrint("TOKEN → $token");

      if (!mounted) return;

      if (token != null && token.toString().isNotEmpty) {
        // User already logged in
        context.go(RouteList.welcomeBackScreen);
      } else {
        // No login found
        context.go(RouteList.getStarted);
      }
    } catch (e) {
      debugPrint("Error checking auth status: $e");
      if (!mounted) return;
      // Fallback to get started screen
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
