import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
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

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: 'Manage Your Transport',
      titleColor: 'with Ease',
      subtitle: 'A fast, cashless way to pay for rides —\nanytime, anywhere.',
      imagePath: onboardingFirstPng,
      slidePath: onboardingFirstSvg,
    ),
    OnboardingData(
      title: 'Bia Pay\nKeeps',
      titleColor: 'You Moving',
      subtitle: 'Secure your wallet now and enjoy smooth,\nstress-free trips.',
      imagePath: onboardingSecondPng,
      slidePath: onboardingSecondSvg,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: PageView.builder(
        controller: _pageController,
        itemCount: onboardingPages.length,
        itemBuilder: (context, index) {
          final pageData = onboardingPages[index];
          final isLastPage = index == onboardingPages.length - 1;

          return _OnboardingPage(
            data: pageData,
            pageController: _pageController,
            isLastPage: isLastPage,
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String titleColor;
  final String subtitle;
  final String imagePath;
  final String slidePath;

  OnboardingData({
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.imagePath,
    required this.slidePath,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final PageController pageController;
  final bool isLastPage;

  const _OnboardingPage({
    required this.data,
    required this.pageController,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      color: lightBackground,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 300.h),
            Center(
              child: Image.asset(
                data.imagePath,
                height: 170.h,
              ),
            ),
            SizedBox(height: 60.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: lightText,
                    fontWeight: FontWeight.w600,
                    fontSize: 35.sp,
                  ),
                ),
                Text(
                  data.titleColor,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 35.sp,
                  ),
                ),
                SizedBox(height: 13.h),
                SizedBox(
                  width: 810.w,
                  child: Text(
                    data.subtitle,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: lightSecondaryText,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SvgPicture.asset(
                  data.slidePath,
                  height: 6.h,
                ),
                SizedBox(
                  height: 50.h,
                  width: 100.w,
                  child: CustomButton(
                    buttonColor: primaryColor,
                    buttonTextColor: secondaryColor,
                    buttonName: isLastPage ? 'Done' : 'Skip',
                    onPressed: () {
                      if (isLastPage) {
                        context.go(RouteList.phoneRegScreen);
                      } else {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}