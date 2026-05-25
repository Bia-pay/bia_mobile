import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bia/core/services/secure_storage_service.dart';
import '../../../../app/utils/router/route_constant.dart';

class Splash extends ConsumerStatefulWidget {
  const Splash({super.key});

  @override
  ConsumerState<Splash> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<Splash> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (_isInitializing) return;
    setState(() {
      _isInitializing = true;
    });

    // 🚀 Minimum delay so the user can actually see the brand logo
    // but not so long that it feels sluggish.
    final minDelay = Future.delayed(const Duration(milliseconds: 1200));

    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final hasSeenOnboarding = await secureStorage.hasSeenOnboarding();
      final isLoggedIn = await secureStorage.isLoggedIn();

      // Wait for both the check and the minimum delay
      await minDelay;

      // Remove the native splash screen smoothly so there is no white frame flash
      FlutterNativeSplash.remove();

      if (!mounted) return;

      if (!hasSeenOnboarding) {
        // 🆕 Totally fresh user: Send to onboarding (Get Started)
        context.go(RouteList.getStarted);
      } else {
        if (isLoggedIn) {
          // ✅ Known user with active session: Send to Welcome Back (PIN/Biometric lock)
          context.go(RouteList.welcomeBackScreen);
        } else {
          // 🚪 Identity exists but logged out: Send to login screen
          context.go(RouteList.loginScreen);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Splash checkAuthStatus Exception: $e');
      await minDelay;
      FlutterNativeSplash.remove();
      if (!mounted) return;
      context.go(RouteList.getStarted);
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
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
