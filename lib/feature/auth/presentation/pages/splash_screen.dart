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
      await _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    // 🚀 Minimum delay so the user can actually see the brand logo
    // but not so long that it feels sluggish.
    final minDelay = Future.delayed(const Duration(milliseconds: 1200));

    try {
      final box = Hive.box("authBox");
      final userId = box.get("userId");
      final phone = box.get("phone");
      
      final bool hasIdentity = (userId != null && userId.toString().isNotEmpty) || 
                               (phone != null && phone.toString().isNotEmpty);

      // Wait for both the check and the minimum delay
      await minDelay;

      if (!mounted) return;

      if (hasIdentity) {
        // ✅ Known user: Always send to Welcome Back to enforce local security (PIN/Biometric)
        context.go(RouteList.welcomeBackScreen);
      } else {
        // 🆕 Totally fresh user: Send to onboarding
        context.go(RouteList.getStarted);
      }
    } catch (_) {
      await minDelay;
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

