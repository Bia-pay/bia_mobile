import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/view/widget/app_button.dart';
import '../../../../core/services/session_service.dart';

class InactivityWarningModal extends ConsumerWidget {
  const InactivityWarningModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the session service to get the remaining seconds
    final sessionState = ref.watch(sessionServiceProvider);
    final remainingSeconds = ref.read(sessionServiceProvider.notifier).remainingSeconds;

    // If we've been logged out while the modal was open, close it
    if (sessionState == SessionState.loggedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 32.h),
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/key.svg', 
                width: 32.w,
                colorFilter: const ColorFilter.mode(errorColor, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "Session Expiring Soon",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: lightText,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14.sp,
                color: lightSecondaryText,
                height: 1.5,
                fontFamily: 'Inter', // Assuming Inter is available as per aesthetics instructions
              ),
              children: [
                const TextSpan(text: "You will be logged out in "),
                TextSpan(
                  text: "$remainingSeconds seconds",
                  style: const TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: " due to inactivity. Do you want to stay logged in?"),
              ],
            ),
          ),
          SizedBox(height: 40.h),
          AppButton(
            text: "I'm Still Here",
            onPressed: () {
              ref.read(sessionServiceProvider.notifier).resetTimer();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 12.h),
          AppButton(
            text: "Log Out Now",
            isPrimary: false,
            isOutlined: true,
            onPressed: () {
              ref.read(sessionServiceProvider.notifier).logout();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
