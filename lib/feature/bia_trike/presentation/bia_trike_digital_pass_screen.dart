import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/bia_trike_controller.dart';
import '../model/bia_trike_ride_model.dart';

class BiaTrikeDigitalPassScreen extends ConsumerStatefulWidget {
  const BiaTrikeDigitalPassScreen({super.key});

  @override
  ConsumerState<BiaTrikeDigitalPassScreen> createState() => _BiaTrikeDigitalPassScreenState();
}

class _BiaTrikeDigitalPassScreenState extends ConsumerState<BiaTrikeDigitalPassScreen> {
  final _otpInputCtrl = TextEditingController();

  @override
  void dispose() {
    _otpInputCtrl.dispose();
    super.dispose();
  }

  void _showDriverOtpVerificationDialog(BiaTrikeNotifier notifier, BiaTrikeState state) {
    _otpInputCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            'Enter Passenger 4-Digit OTP',
            style: TextStyle(color: darkBackground, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ask the passenger for their 4-digit PIN shown on their screen before starting trip.',
                style: TextStyle(color: lightSecondaryText, fontSize: 12.sp),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _otpInputCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, letterSpacing: 8.0),
                decoration: InputDecoration(
                  hintText: '1699',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final otp = _otpInputCtrl.text.trim();
                final ok = await notifier.advanceRideStatus('IN_TRANSIT', otpCode: otp);
                nav.pop();
                if (!mounted) return;
                ToastHelper.showToast(
                  context: context,
                  message: ok ? "OTP Verified! Trip started." : "Incorrect PIN. Ask passenger to confirm code.",
                  icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  iconColor: ok ? primaryGreenColor : errorColor,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Verify & Start Trip', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biaTrikeStateNotifierProvider);
    final notifier = ref.read(biaTrikeStateNotifierProvider.notifier);
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Use active pass or fallback pass for presentation
    final pass = state.riderPass ??
        DigitalRiderPass(
          passCode: 'BIA-TRK-2026-6878',
          status: 'APPROVED',
          plateNumber: 'KMC-482-XA',
          trikeModel: 'TVS King Deluxe (Yellow)',
          city: 'Kano Municipal',
          rating: 4.9,
          totalTrips: 142,
          isOnline: true,
          qrPayload: 'BIA-TRK-PASS:BIA-TRK-2026-6878:7',
          verifiedAt: DateTime.now(),
        );

    final app = state.riderApp;
    final driverName = app?.fullName.isNotEmpty == true ? app!.fullName : 'Aliyu Bello';

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
          'Bia Trike Driver Pass',
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
                  // Metallic Hologram Verification Card Screen 4
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2027)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: pass.status == 'APPROVED'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: const BoxDecoration(
                                      color: primaryGreenColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.verified_rounded,
                                        color: Colors.white, size: 14.sp),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'VERIFIED COMMERCIAL RIDER PASS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: pass.status == 'APPROVED'
                                      ? primaryGreenColor.withValues(alpha: 0.2)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: pass.status == 'APPROVED'
                                        ? primaryGreenColor
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: Text(
                                  pass.status,
                                  style: TextStyle(
                                    color: pass.status == 'APPROVED'
                                        ? primaryGreenColor
                                        : const Color(0xFFF59E0B),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pass ID: ${pass.passCode}',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'City: ${pass.city}',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11.sp),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16.h),

                              // Driver Identity Info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28.r,
                                    backgroundColor: primaryColor,
                                    child: Text(
                                      driverName.substring(0, 2).toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driverName.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          'Plate: ${pass.plateNumber}',
                                          style: TextStyle(
                                            color: primaryGreenColor,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Vehicle: ${pass.trikeModel}',
                                          style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontSize: 11.5.sp,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.star_rounded,
                                                color: const Color(0xFFF59E0B), size: 14.sp),
                                            SizedBox(width: 4.w),
                                            Text(
                                              '${pass.rating} ★ (${pass.totalTrips} trips completed)',
                                              style: TextStyle(
                                                color: const Color(0xFFF59E0B),
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),
                              Divider(color: Colors.white.withValues(alpha: 0.15)),
                              SizedBox(height: 14.h),

                              // Offline-Capable Scannable QR Code
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                      child: QrImageView(
                                        data: pass.qrPayload,
                                        version: QrVersions.auto,
                                        size: 140.r,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      'Official Security QR — Scannable Offline by VIO / KAROTA',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 14.h),
                              Center(
                                child: Text(
                                  'Verified by Bia Pay Transport Security Network',
                                  style: TextStyle(
                                    color: primaryGreenColor,
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 400.ms),

                  SizedBox(height: 20.h),

                  // Driver Online / Offline Control Card
                  Container(
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    color: pass.isOnline
                                        ? primaryGreenColor
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  pass.isOnline
                                      ? 'STATUS: ONLINE 🟢'
                                      : 'STATUS: OFFLINE 🔴',
                                  style: TextStyle(
                                    color: darkBackground,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: pass.isOnline,
                              activeTrackColor: primaryGreenColor,
                              onChanged: (val) {
                                notifier.toggleRiderOnlineStatus(val);
                                ToastHelper.showToast(
                                  context: context,
                                  message: val
                                      ? "You are now ONLINE. Receiving nearby trip requests!"
                                      : "You are now OFFLINE.",
                                  icon: val ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                  iconColor: val ? primaryGreenColor : errorColor,
                                );
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),
                        Divider(color: Colors.grey.shade200),
                        SizedBox(height: 10.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Today\'s Earnings',
                                    style: TextStyle(color: lightSecondaryText, fontSize: 11.sp)),
                                SizedBox(height: 2.h),
                                Text('₦14,850',
                                    style: TextStyle(
                                        color: primaryGreenColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                            Container(width: 1.w, height: 30.h, color: Colors.grey.shade300),
                            Column(
                              children: [
                                Text('Trips Today',
                                    style: TextStyle(color: lightSecondaryText, fontSize: 11.sp)),
                                SizedBox(height: 2.h),
                                Text('12',
                                    style: TextStyle(
                                        color: darkBackground,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Enter Passenger OTP Action (for Driver Mode)
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDriverOtpVerificationDialog(notifier, state),
                      icon: Icon(Icons.pin_rounded, color: Colors.white, size: 18.sp),
                      label: Text(
                        'Verify Passenger 4-Digit OTP PIN',
                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                    ),
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
