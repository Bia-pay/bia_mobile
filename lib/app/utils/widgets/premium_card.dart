import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/colors.dart';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;

  const PremiumGlassCard({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 4.0 : 4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 24.0 : 30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 24.0 : 30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 24.0 : 24.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(isTablet ? 24.0 : 30.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 20.sp,
                    fontWeight: FontWeight.w900,
                    color: lightText,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: isTablet ? 4.0 : 4.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isTablet ? 14.0 : 14.sp,
                      color: lightSecondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                SizedBox(height: isTablet ? 20.0 : 24.h),
                Container(
                  padding: EdgeInsets.all(isTablet ? 16.0 : 16.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                ),
                SizedBox(height: isTablet ? 20.0 : 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/svg/logo-two.png',
                      height: isTablet ? 24.0 : 24.h,
                      errorBuilder: (_, __, ___) => Icon(Icons.wallet, color: primaryColor, size: isTablet ? 20.0 : null),
                    ),
                    SizedBox(width: isTablet ? 8.0 : 8.w),
                    Text(
                      "Verified Bia Account",
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 12.sp,
                        fontWeight: FontWeight.w700,
                        color: successColor,
                      ),
                    ),
                    SizedBox(width: isTablet ? 4.0 : 4.w),
                    Icon(Icons.verified, color: successColor, size: isTablet ? 14.0 : 14.sp),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
