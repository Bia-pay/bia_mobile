import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/utils/colors.dart';

class PinLockoutOverlay extends StatelessWidget {
  final bool isFrozen;
  final Duration remainingTime;
  final VoidCallback? onSupportTap;

  const PinLockoutOverlay({
    super.key,
    required this.isFrozen,
    required this.remainingTime,
    this.onSupportTap,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:${twoDigitMinutes}:${twoDigitSeconds}";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glow
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: errorColor.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: errorColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  isFrozen ? Icons.block : Icons.timer_outlined,
                  color: errorColor,
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 24.h),
              
              // Title
              Text(
                isFrozen ? 'Account Frozen' : 'Security Lockout',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                  color: isFrozen ? errorColor : lightText,
                ),
              ),
              SizedBox(height: 12.h),

              // Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  isFrozen
                      ? 'Maximum PIN attempts reached. Your transaction access has been suspended for security.'
                      : 'Too many failed attempts. For your security, transactions are locked temporarily.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: grey600,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Timer or Support Button
              if (!isFrozen) ...[
                Text(
                  'TRY AGAIN IN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: grey500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _formatDuration(remainingTime),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: primaryColor,
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: onSupportTap,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
