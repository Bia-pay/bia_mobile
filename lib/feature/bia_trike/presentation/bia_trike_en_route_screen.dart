import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/bia_trike_controller.dart';

class BiaTrikeEnRouteScreen extends ConsumerWidget {
  const BiaTrikeEnRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(biaTrikeStateNotifierProvider);
    final notifier = ref.read(biaTrikeStateNotifierProvider.notifier);
    final ride = state.activeRide;
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Status')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No active trip found.', style: TextStyle(fontSize: 16.sp)),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => context.go(RouteList.bottomNavBar),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final driver = ride.driver;
    final isArrived = ride.status == 'ARRIVED';
    final isInTransit = ride.status == 'IN_TRANSIT';
    final isCompleted = ride.status == 'COMPLETED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkBackground, size: 18.sp),
          onPressed: () => context.go(RouteList.bottomNavBar),
        ),
        title: Text(
          isCompleted
              ? 'Trip Completed'
              : isInTransit
                  ? 'In Transit to Destination'
                  : isArrived
                      ? 'Rider Has Arrived!'
                      : 'Rider En Route',
          style: TextStyle(
            color: darkBackground,
            fontSize: isTablet ? 16.0 : 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : 650),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                children: [
                  // Top Status Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isArrived
                          ? const Color(0xFFFEF3C7)
                          : isInTransit
                              ? primaryColor.withValues(alpha: 0.12)
                              : primaryGreenColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isArrived
                            ? const Color(0xFFF59E0B)
                            : isInTransit
                                ? primaryColor
                                : primaryGreenColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isArrived
                              ? Icons.location_on_rounded
                              : isInTransit
                                  ? Icons.directions_bus_rounded
                                  : Icons.electric_rickshaw_rounded,
                          color: isArrived
                              ? const Color(0xFFD97706)
                              : isInTransit
                                  ? primaryColor
                                  : primaryGreenColor,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            isArrived
                                ? 'Rider Mallam Aliyu has arrived at pickup point!'
                                : isInTransit
                                    ? 'En route to ${ride.destinationAddress}'
                                    : 'Rider is on the way (ETA: 2 mins)',
                            style: TextStyle(
                              color: darkBackground,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Prominent 4-Digit Trip OTP PIN Container (shown until IN_TRANSIT/COMPLETED)
                  if (!isInTransit && !isCompleted) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: primaryColor, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SHARE THIS PIN WITH YOUR RIDER UPON BOARDING',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 14.h),

                          // Monospaced 4-Digit Code Box
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: ride.otpCode));
                              HapticFeedback.lightImpact();
                              ToastHelper.showToast(
                                context: context,
                                message: "PIN ${ride.otpCode} copied to clipboard",
                                icon: Icons.copy_rounded,
                                iconColor: primaryColor,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ride.otpCode.split('').join('   '),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w900,
                                      color: darkBackground,
                                      letterSpacing: 4.0,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Icon(Icons.copy_rounded, color: primaryColor, size: 20.sp),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 10.h),
                          Text(
                            '⚠️ Security Rule: Do not share your PIN until you are inside the Keke.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: lightSecondaryText, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 350.ms),
                    SizedBox(height: 20.h),
                  ],

                  // Map Polyline Simulation Box
                  Container(
                    height: 180.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.map_rounded,
                            color: Colors.white.withValues(alpha: 0.15),
                            size: 110.sp,
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.electric_rickshaw_rounded,
                                color: Colors.white, size: 28.sp),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.1, 1.1),
                                duration: 1000.ms,
                              ),
                        ),
                        Positioned(
                          bottom: 12.h,
                          left: 16.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Live GPS Tracking Active',
                              style: TextStyle(color: Colors.white, fontSize: 10.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Rider Details Card
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26.r,
                              backgroundColor: primaryColor.withValues(alpha: 0.12),
                              child: Text(
                                driver?.name.substring(0, 2).toUpperCase() ?? 'AB',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver?.name ?? 'Aliyu Bello',
                                    style: TextStyle(
                                      color: darkBackground,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${driver?.trikeModel ?? 'Bajaj RE 4S Yellow'} · ${driver?.plateNumber ?? 'KMC-482-XA'}',
                                    style: TextStyle(
                                      color: lightSecondaryText,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded,
                                      color: const Color(0xFFF59E0B), size: 14.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    driver?.rating.toString() ?? '4.9',
                                    style: TextStyle(
                                      color: const Color(0xFFF59E0B),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),
                        Divider(color: Colors.grey.shade200),
                        SizedBox(height: 10.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Agreed Negotiated Fare',
                              style: TextStyle(color: lightSecondaryText, fontSize: 12.sp),
                            ),
                            Text(
                              '₦${NumberFormat('#,##0').format(ride.finalFare ?? ride.passengerOfferFare)}',
                              style: TextStyle(
                                color: darkBackground,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method',
                              style: TextStyle(color: lightSecondaryText, fontSize: 12.sp),
                            ),
                            Text(
                              ride.paymentMethod == 'WALLET' ? '🟢 Bia Pay Wallet' : '💵 Cash',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Action Buttons: Call Rider, Chat, Safety SOS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ToastHelper.showToast(
                              context: context,
                              message: "Calling Rider (${driver?.phone ?? '+2348031234501'})...",
                              icon: Icons.phone_rounded,
                              iconColor: primaryColor,
                            );
                          },
                          icon: Icon(Icons.phone_rounded, color: primaryColor, size: 16.sp),
                          label: Text('Call Rider', style: TextStyle(color: primaryColor, fontSize: 12.sp)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ToastHelper.showToast(
                              context: context,
                              message: "Chat feature opened.",
                              icon: Icons.chat_rounded,
                              iconColor: primaryColor,
                            );
                          },
                          icon: Icon(Icons.chat_rounded, color: primaryColor, size: 16.sp),
                          label: Text('Chat', style: TextStyle(color: primaryColor, fontSize: 12.sp)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ToastHelper.showToast(
                              context: context,
                              message: "Safety SOS alert sent to emergency contacts!",
                              icon: Icons.shield_rounded,
                              iconColor: Colors.white,
                            );
                          },
                          icon: Icon(Icons.shield_rounded, color: Colors.white, size: 16.sp),
                          label: Text('Safety SOS', style: TextStyle(color: Colors.white, fontSize: 11.5.sp)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Demo simulation trigger to advance trip status in dev mode
                  if (!isCompleted)
                    TextButton.icon(
                      onPressed: () async {
                        if (!isArrived && !isInTransit) {
                          await notifier.advanceRideStatus('ARRIVED');
                        } else if (isArrived) {
                          await notifier.advanceRideStatus('IN_TRANSIT', otpCode: ride.otpCode);
                        } else if (isInTransit) {
                          await notifier.advanceRideStatus('COMPLETED');
                        }
                      },
                      icon: Icon(Icons.fast_forward_rounded, color: primaryColor, size: 16.sp),
                      label: Text(
                        !isArrived
                            ? 'Simulate Driver Arrived'
                            : isArrived
                                ? 'Simulate OTP Validated & In-Transit'
                                : 'Simulate Trip Completed',
                        style: TextStyle(color: primaryColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ),

                  if (isCompleted)
                    ElevatedButton(
                      onPressed: () {
                        notifier.cancelActiveRide();
                        context.go(RouteList.bottomNavBar);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreenColor,
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: Text('Trip Complete — Back to Home',
                          style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
