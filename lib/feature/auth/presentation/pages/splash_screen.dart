import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
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
    await Future.delayed(const Duration(seconds: 2)); // small splash delay

    final box = await Hive.openBox("authBox");
    final accessToken = box.get("token");
    print(accessToken);

    if (!mounted) return;

    if (accessToken != null && accessToken.toString().isNotEmpty) {
      // ✅ User is already logged in → navigate to main dashboard
      Navigator.pushReplacementNamed(context, RouteList.welcomeBackScreen);
    } else {
      // 🚀 No token → go to onboarding
      Navigator.pushReplacementNamed(context, RouteList.getStarted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeContext = context.themeContext;

    return Scaffold(
      body: Container(
        color: themeContext.kSplash,
        alignment: Alignment.center,
        child: Image.asset(
          'assets/svg/logo.png',
          height: 230.h,
        ),
      ),
    );
  }
}