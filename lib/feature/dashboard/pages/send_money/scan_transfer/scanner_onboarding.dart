import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:svg_flutter/svg.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/qr_onboarding_provider.dart';
import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';

class ScannerOnboarding extends ConsumerStatefulWidget {
  const ScannerOnboarding({super.key});

  @override
  ConsumerState<ScannerOnboarding> createState() => _ScannerOnboardingState();
}

class _ScannerOnboardingState extends ConsumerState<ScannerOnboarding> {

  Future<void> _completeOnboarding() async {
    await ref.read(qrOnboardingProvider.notifier).completeOnboarding();
    // No need to push if it's in the BottomNavBar, it will rebuild
    // But if it's pushed from Settings, we should replace it
    if (mounted) {
      final location = GoRouterState.of(context).uri.toString();
      if (location == '/scanner-onboarding') {
        context.pushReplacementNamed(RouteList.qrScannerScreen);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dynamic Background Glows
          Positioned(
            top: -100.h,
            right: -50.w,
            child: _buildBlurCircle(350.r, primaryColor.withOpacity(0.1)),
          ),
          Positioned(
            bottom: 50.h,
            left: -120.w,
            child: _buildBlurCircle(450.r, successColor.withOpacity(0.08)),
          ),

          SafeArea(
            child: Column(
              children: [
            //    _buildHeader(),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        
                        // Hero Animation Section
                        _buildHeroSection(),

                        SizedBox(height: 40.h),

                        // Unified Ecosystem Message
                        _buildMainMessage(theme),

                      ],
                    ),
                  ),
                ),

                // Immersive Action Area
                _buildBottomAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate().fadeIn(duration: 2.seconds);
  }

  // Widget _buildHeader() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  //     child: Row(
  //       children: [
  //         IconButton(
  //           icon: const Icon(Icons.close, color: lightText),
  //           onPressed: () => Navigator.pop(context),
  //         ),
  //         const Spacer(),
  //         Container(
  //           padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //           decoration: BoxDecoration(
  //             color: primaryColor.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(20.r),
  //           ),
  //           child: Text(
  //             "Unified QR Portal",
  //             style: TextStyle(
  //               fontSize: 12.sp,
  //               fontWeight: FontWeight.w800,
  //               color: primaryColor,
  //               letterSpacing: 0.5,
  //             ),
  //           ),
  //         ),
  //         SizedBox(width: 40.w),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeroSection() {
    return Container(
      height: 280.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Premium Icon Hero
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                    qrCodeSvg,
                  height: 150.h,
                ).animate(onPlay: (controller) => controller.repeat())
                 .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.5))
                 .scale(duration: 1500.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniBadge(Icons.send_rounded, "Pay"),
                  SizedBox(width: 12.w),
                  _buildMiniBadge(Icons.download_rounded, "Receive"),
                ],
              ),
            ],
          ),
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user_rounded, color: successColor, size: 24.sp),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMiniBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: lightSecondaryText.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: lightSecondaryText),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMessage(ThemeData theme) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28.sp,
              color: lightText,
              height: 1.1,
            ),
            children: [
              const TextSpan(text: "Scan to Pay, "),
              TextSpan(
                text: "Scan to Receive.",
                style: TextStyle(color: primaryColor),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        SizedBox(height: 12.h),
        Text(
          "Experience the future of payments. Send and receive funds instantly with a single scan.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: lightSecondaryText,
            fontSize: 15.sp,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Duration delay,
  }) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 26.sp),
          ),
          SizedBox(width: 18.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: lightText,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: lightSecondaryText,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.1);
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.only(left:24.r, right: 24.r,top: 24.r,bottom: 44.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 60.h,
            child: CustomButton(
              buttonName: 'Get Started with QR',
              buttonColor: primaryColor,
              buttonTextColor: Colors.white,
              onPressed: _completeOnboarding,
            ),
          ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.95, 0.95)),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, color: successColor, size: 14.sp),
              SizedBox(width: 6.w),
              Text(
                "Secured by Bia Encryption",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: successColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}