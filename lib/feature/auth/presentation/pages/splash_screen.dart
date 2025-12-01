import 'package:bia/app/utils/image.dart';
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
    await Future.delayed(const Duration(seconds: 2));

    final box = await Hive.openBox("authBox");
    final token = box.get("token");
    print("TOKEN → $token");

    if (!mounted) return;

    if (token != null && token.toString().isNotEmpty) {
      // User already logged in
      Navigator.pushReplacementNamed(
        context,
        RouteList.welcomeBackScreen,
      );
    } else {
      // No login found
      Navigator.pushReplacementNamed(
        context,
        RouteList.getStarted,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: accentColor,
        alignment: Alignment.center,
        child: Image.asset( splashLogo,
          height: 200.h,
        ),
      ),
    );
  }
}