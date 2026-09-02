import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:bia/core/services/secure_storage_service.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';

class GetStarted extends ConsumerStatefulWidget {
  const GetStarted({super.key});

  @override
  ConsumerState<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends ConsumerState<GetStarted> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: accentColor,
      body: Stack(
        children: [
          // 1. Organic Background Blobs
          _buildAnimatedBackground(),

          // 2. Main Content
          SafeArea(
            child: isTablet
                ? _buildTabletLayout(context, theme, screenHeight)
                : _buildPhoneLayout(context, theme, screenHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
      BuildContext context, ThemeData theme, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 24.h),
      child: Row(
        children: [
          // Left Side: Hero Card
          Expanded(
            flex: 5,
            child: Center(
              child: _buildHeroCard(screenHeight),
            ),
          ),

          SizedBox(width: 40.w),

          // Right Side: Hook Text & Action Buttons
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadge(theme),
                SizedBox(height: 20.h),

                Text(
                  'Fast Payments.\nNo Boundaries.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 32.spMin,
                    fontWeight: FontWeight.w900,
                    color: offWhiteBackground,
                    letterSpacing: 0.5,
                    height: 1.15,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                SizedBox(height: 16.h),

                Text(
                  'Experience the next generation of QR payments. Secure, instant, and designed for you.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16.spMin,
                    height: 1.6,
                    color: offWhiteBackground.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                SizedBox(height: 40.h),

                _buildFooterActions(context, theme, isTablet: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(
      BuildContext context, ThemeData theme, double screenHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  /// 🔥 Feature Bento-Glass Card
                  _buildHeroCard(screenHeight),

                  const Spacer(flex: 3),

                  /// 🔥 Branding & Hook
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBadge(theme),
                        SizedBox(height: 16.h),

                        /// 🔥 Headline
                        Text(
                          'Fast Payments.\nNo Boundaries.',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28.spMin,
                            fontWeight: FontWeight.w800,
                            color: offWhiteBackground,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

                        SizedBox(height: 16.h),

                        /// 🔥 Supporting Text
                        Text(
                          'Experience the next generation of QR payments. Secure, instant, and designed for you.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16.spMin,
                            height: 1.6,
                            color: offWhiteBackground.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  /// 🔥 Footer Actions
                  _buildFooterActions(context, theme),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(double screenHeight) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 280.r,
            height: 280.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(duration: 3.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),

          // Glass Card
          ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 320.w,
                height: 320.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(50.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: EdgeInsets.all(40.r),
                child: SvgPicture.asset(
                  qrCodeSvg,
                  fit: BoxFit.contain,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .shimmer(duration: 2.seconds, color: Colors.white24)
                 .moveY(begin: -10, end: 10, duration: 2.seconds, curve: Curves.easeInOut),
              ),
            ),
          ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }

  Widget _buildBadge(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: secondaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: secondaryColor, size: 16.sp),
          SizedBox(width: 4.w),
          Text(
            'SECURE & FAST',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 10.spMin,
              fontWeight: FontWeight.w900,
              color: secondaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).scale();
  }

  Widget _buildFooterActions(BuildContext context, ThemeData theme,
      {bool isTablet = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 24.w),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60.h,
            child: CustomButton(
              onPressed: () => context.go(RouteList.onBoardingScreen),
              buttonColor: primaryColor,
              buttonTextColor: Colors.white,
              buttonName: 'Create Free Account',
              textStyle: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 18.spMin,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).scale(),

          SizedBox(height: 16.h),

          SizedBox(
            width: double.infinity,
            height: 60.h,
            child: CustomButton(
              onPressed: () async {
                await ref.read(secureStorageServiceProvider).setHasSeenOnboarding(true);
                if (context.mounted) {
                  context.go(RouteList.loginScreen);
                }
              },
              buttonColor: Colors.white,
              buttonTextColor: primaryColor,
              buttonName: 'Log In',
              buttonBorderColor: Colors.white.withOpacity(0.2),
              textStyle: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 18.spMin,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
          ).animate().fadeIn(delay: 800.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Top Left Blob
        Positioned(
          top: -150.h,
          left: -150.w,
          child: _CircularBlob(
            color: primaryColor.withOpacity(0.3),
            size: 400.r,
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .move(begin: const Offset(-20, -20), end: const Offset(30, 30), duration: 10.seconds),
        ),

        // Bottom Right Blob
        Positioned(
          bottom: -100.h,
          right: -100.w,
          child: _CircularBlob(
            color: secondaryColor.withOpacity(0.15),
            size: 350.r,
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .move(begin: const Offset(30, 30), end: const Offset(-40, -40), duration: 8.seconds),
        ),
      ],
    );
  }
}

class _CircularBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _CircularBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}