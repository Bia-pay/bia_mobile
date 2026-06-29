import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/utils/colors.dart';
import '../dashboardcontroller/provider.dart';

enum ServiceType { airtime, data, utility, qr }

class ServiceGuard extends ConsumerWidget {
  final ServiceType service;
  final Widget child;
  final Widget? fallback;

  const ServiceGuard({
    super.key,
    required this.service,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(servicesStatusProvider);
    bool isEnabled = true;
    String serviceName = '';

    switch (service) {
      case ServiceType.airtime:
        isEnabled = status.airtime;
        serviceName = 'Airtime';
        break;
      case ServiceType.data:
        isEnabled = status.data;
        serviceName = 'Data';
        break;
      case ServiceType.utility:
        isEnabled = status.utility;
        serviceName = 'Utility';
        break;
      case ServiceType.qr:
        isEnabled = status.qr;
        serviceName = 'QR Payment';
        break;
    }

    if (isEnabled) {
      return child;
    }

    if (fallback != null) {
      return fallback!;
    }

    // Default premium maintenance page design
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.construction_rounded,
                    color: Colors.orange.shade700,
                    size: 54.sp,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                '$serviceName Temporarily Disabled',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A), // slate 900
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Our $serviceName service is currently undergoing scheduled maintenance to improve your experience. We will be back online shortly.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B), // slate 500
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
