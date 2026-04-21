import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      await _handleFirstLaunch();
      await _checkAuthStatus();
    });
  }

  /// 🔹 Only request permission — DO NOT generate token here
  Future<void> _handleFirstLaunch() async {
    final box = Hive.box('appBox');
    final isFirstLaunch = box.get('first_launch', defaultValue: true);

    if (isFirstLaunch) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await box.put('first_launch', false);
    }
  }

  Future<void> _checkAuthStatus() async {
    // Artificial delay removed for instantaneous boot
    await Future.delayed(const Duration(milliseconds: 1000));


    try {
      final box = Hive.box("authBox");
      final token = box.get("token");

      if (!mounted) return;

      if (token != null && token.toString().isNotEmpty) {
        context.go(RouteList.welcomeBackScreen);
      } else {
        context.go(RouteList.getStarted);
      }
    } catch (_) {
      if (!mounted) return;
      context.go(RouteList.getStarted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            double logoSize;

            if (screenWidth < 350) {
              logoSize = screenWidth * 0.45;
            } else if (screenWidth < 600) {
              logoSize = screenWidth * 0.40;
            } else {
              logoSize = 220;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      child: Image.asset(
                        splashLogo,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.1),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

