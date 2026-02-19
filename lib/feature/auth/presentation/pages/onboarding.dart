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
      title: 'Bia Pay Keeps',
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
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;

        double imageHeight;
        if (screenWidth < 350) {
          imageHeight = screenHeight * 0.22;
        } else if (screenWidth < 600) {
          imageHeight = screenHeight * 0.25;
        } else {
          imageHeight = 260; // tablet cap
        }

        return Container(
          color: lightBackground,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                  ),
                  child: Column(
                    children: [

                      SizedBox(height: screenHeight * 0.32),

                      /// IMAGE
                      Image.asset(
                        data.imagePath,
                        height: imageHeight,
                        fit: BoxFit.contain,
                      ),

                      const Spacer(),
                      /// TITLE
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: lightText,
                                fontWeight: FontWeight.w700,
                                fontSize: 26.spMin,
                              ),
                            ),
                            Text(
                              data.titleColor,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 28.spMin,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      /// SUBTITLE
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          data.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: lightSecondaryText,
                            fontSize: 15.spMin,
                            height: 1.6,
                          ),
                        ),
                      ),



                      /// INDICATOR + BUTTON
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(
                            data.slidePath,
                            height: 6.h,
                          ),
                          SizedBox(
                            width: screenWidth * 0.28,
                            child: CustomButton(
                              buttonColor: primaryColor,
                              buttonTextColor: secondaryColor,
                              buttonName:
                              isLastPage ? 'Done' : 'Next',
                              onPressed: () {
                                if (isLastPage) {
                                  context.go(
                                      RouteList.phoneRegScreen);
                                } else {
                                  pageController.nextPage(
                                    duration: const Duration(
                                        milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}