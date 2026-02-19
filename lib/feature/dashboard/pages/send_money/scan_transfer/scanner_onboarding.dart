import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
import 'scanner.dart';

class ScannerOnboarding extends ConsumerStatefulWidget {
  const ScannerOnboarding({super.key});

  @override
  ConsumerState<ScannerOnboarding> createState() => _ScannerOnboardingState();
}

class _ScannerOnboardingState extends ConsumerState<ScannerOnboarding> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FC),
              Color(0xFFEFF2F8),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final width = constraints.maxWidth;

              // Dynamic illustration size
              final illustrationHeight =
                  height * 0.28; // scales based on device height

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height,
                  ),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 500, // Better for tablets
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: height * 0.06),

                            /// TITLE
                            Text(
                              "Scan to Pay",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            SizedBox(height: 12.h),

                            Text(
                              "Quick, secure and contactless payments",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 14.sp,
                              ),
                            ),

                            SizedBox(height: height * 0.06),

                            /// ILLUSTRATION CARD
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/svg/qr-code.svg',
                                height: illustrationHeight.clamp(140, 260),
                              ),
                            ),

                            SizedBox(height: height * 0.06),

                            /// DESCRIPTION
                            Text(
                              'Place the QR code inside the frame and it will be detected automatically.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 15.sp,
                                height: 1.6,
                                color: Colors.grey.shade700,
                              ),
                            ),

                            const Spacer(),

                            /// PRIMARY BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                buttonName: 'Start Scanning',
                                buttonColor: theme.colorScheme.primary,
                                buttonTextColor: Colors.white,
                                onPressed: () => context.pushNamed(
                                  RouteList.qrScannerScreen,
                                ),
                              ),
                            ),

                            SizedBox(height: height * 0.14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}