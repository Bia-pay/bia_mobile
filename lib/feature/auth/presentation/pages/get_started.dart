import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';

class GetStarted extends ConsumerStatefulWidget {
  const GetStarted({super.key});

  @override
  ConsumerState<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends ConsumerState<GetStarted> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
            colors: [
              context.themeContext.kPrimary,
              context.themeContext.kSplash,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 180.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Replace RSvg with SvgPicture.asset
              SvgPicture.asset(
                'assets/svg/qr-code.svg',
                height: 200.h,
              ),

              SizedBox(height: 50.h),

              Text(
                'Pay your Keke fare instantly by\n just scanning a QR code',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontSize: 19.sp,
                  color: context.themeContext.offWhiteBg,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 30.h),

              Text(
                'No cash, no delays\n just scan, pay, and move',
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  fontSize: 18.sp,
                  color: context.themeContext.offWhiteBg,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 50.h),

              // ✅ Replace SolidAppButton with your CustomButton
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: CustomButton(
                  buttonColor: context.themeContext.offWhiteBg,
                  buttonTextColor: context.themeContext.kPrimary,
                  buttonName: 'Get Started',
                  onPressed: () {
                    Navigator.pushNamed(
                        context, RouteList.onBoardingScreen);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}