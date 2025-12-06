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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// 🔹 QR Illustration
              SvgPicture.asset(
                'assets/svg/qr-code.svg', // 🔸 Change to .svg → use flutter_svg if needed
                height: 200.h,
                fit: BoxFit.contain,
              ),

              SizedBox(height: 50.h),

              /// 🔹 Instruction Text
              Text(
                'The QR code will be automatically\n detected when you place\n it inside the frame.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16.sp,
                  height: 1.6,
                ),
              ),

              SizedBox(height: 100.h),

              /// 🔹 Scan Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  buttonName: 'Scan Item',
                  buttonColor: theme.colorScheme.primary,
                  buttonTextColor: Colors.white,
                  onPressed: () => Navigator.pushNamed(context, RouteList.qrScannerScreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}