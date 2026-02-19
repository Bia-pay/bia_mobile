import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;

          double illustrationSize;
          if (screenWidth < 350) {
            illustrationSize = screenWidth * 0.65;
          } else if (screenWidth < 600) {
            illustrationSize = screenWidth * 0.56;
          } else {
            illustrationSize = 264; // tablet cap
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  accentColor,
                ],
              ),
            ),
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

                        SizedBox(height: screenHeight * 0.08),

                        /// 🔥 Floating Illustration Card
                        Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(28.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: SvgPicture.asset(
                            qrCodeSvg,
                            height: illustrationSize,
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.06),

                        /// 🔥 Headline
                        Text(
                          'Scan. Pay. Move.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28.spMin,
                            fontWeight: FontWeight.w800,
                            color: offWhiteBackground,
                            letterSpacing: 0.5,
                          ),
                        ),

                        SizedBox(height: 18.h),

                        /// 🔥 Supporting Text
                        Text(
                          'Pay your Keke fare instantly\nwith secure QR payments.\nNo cash. No stress.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16.spMin,
                            height: 1.6,
                            color: offWhiteBackground.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const Spacer(),

                        /// 🔥 CTA Button
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            buttonColor: secondaryColor,
                            buttonTextColor: primaryColor,
                            buttonName: 'Get Started',
                            onPressed: () {
                              context.go(RouteList.onBoardingScreen);
                            },
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}