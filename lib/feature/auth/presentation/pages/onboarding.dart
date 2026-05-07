import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';

class OnBoardingScreen extends ConsumerStatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  ConsumerState<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends ConsumerState<OnBoardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: 'Manage Your Transport',
      titleHighlight: 'with Ease',
      subtitle: 'A fast, cashless way to pay for rides — anytime, anywhere.',
      imagePath: onboardingFirstPng,
      isSvg: false,
    ),
    OnboardingData(
      title: 'Bia Pay Keeps',
      titleHighlight: 'You Moving',
      subtitle: 'Secure your wallet now and enjoy smooth, stress-free trips.',
      imagePath: onboardingSecondPng,
      isSvg: false,
    ),
    OnboardingData(
      title: 'Experience Financial',
      titleHighlight: 'Freedom',
      subtitle: 'Take control of your spending and grow your wealth with Bia.',
      imagePath: onboardingThirdSvg,
      isSvg: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: inactiveColorOp,
      body: Stack(
        children: [
          // 1. Subtle Background Elements
          _buildBackgroundElements(),

          // 2. Main Content Slider
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingPages.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return _OnboardingPageContent(
                data: onboardingPages[index],
                theme: theme,
                screenHeight: screenHeight,
              );
            },
          ),

          // 3. Navigation Footer
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30.h,
            left: 24.w,
            right: 24.w,
            child: _buildFooter(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        Positioned(
          top: -50.h,
          right: -50.w,
          child: Container(
            width: 250.r,
            height: 250.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final isLastPage = _currentIndex == onboardingPages.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pill Indicators
        Row(
          children: List.generate(
            onboardingPages.length,
            (index) => _buildIndicator(index == _currentIndex),
          ),
        ),

        // Action Button
        SizedBox(
          width: 140.w,
          height: 56.h,
          child: CustomButton(
            buttonColor: primaryColor,
            buttonTextColor: Colors.white,
            buttonName: isLastPage ? 'Get Started' : 'Next',
            onPressed: () {
              if (isLastPage) {
                context.go(RouteList.phoneRegScreen);
              } else {
                _pageController.nextPage(
                  duration: 500.ms,
                  curve: Curves.easeOutQuart,
                );
              }
            },
            textStyle: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 16.spMin,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: 300.ms,
      margin: EdgeInsets.only(right: 8.w),
      height: 8.h,
      width: isActive ? 24.w : 8.w,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String titleHighlight;
  final String subtitle;
  final String imagePath;
  final bool isSvg;

  OnboardingData({
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.imagePath,
    this.isSvg = false,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;
  final ThemeData theme;
  final double screenHeight;

  const _OnboardingPageContent({
    required this.data,
    required this.theme,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          const Spacer(flex: 3),

          /// 🔥 Illustration (Top Half)
          Container(
            width: double.infinity,
            height: screenHeight * 0.35,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40.r),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: data.isSvg 
                ? SvgPicture.asset(data.imagePath, fit: BoxFit.contain)
                : Image.asset(data.imagePath, fit: BoxFit.contain),
            ),
          ).animate(key: ValueKey(data.imagePath)).fadeIn().scale(begin: const Offset(0.9, 0.9)),

          const Spacer(flex: 1),

          /// 🔥 Typography (Bottom Half)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    height: 1.1,
                  ),
                  children: [
                    TextSpan(text: '${data.title}\n'),
                    TextSpan(
                      text: data.titleHighlight,
                      style: TextStyle(color: accentColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              ).animate(key: ValueKey(data.title)).fadeIn(delay: 200.ms).slideX(begin: 0.1),

              SizedBox(height: 18.h),

              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: primaryColor.withOpacity(0.5),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ).animate(key: ValueKey(data.subtitle)).fadeIn(delay: 400.ms).slideX(begin: 0.1),
            ],
          ),

          const Spacer(flex: 5),
        ],
      ),
    );
  }
}