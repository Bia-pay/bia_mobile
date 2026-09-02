import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/bia_trike_controller.dart';
import '../model/bia_trike_model.dart';

class BiaTrikeSuccessScreen extends ConsumerWidget {
  const BiaTrikeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(biaTrikeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: darkBackground, size: 18.sp),
          onPressed: () => context.go(RouteList.bottomNavBar),
        ),
        title: Text(
          'Digital Rider Pass',
          style: TextStyle(
            color: darkBackground,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: appState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
              error: (err, _) => Center(
                child: Text('Error: $err', style: TextStyle(color: darkBackground)),
              ),
              data: (app) {
                if (app == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No active application found.',
                          style: TextStyle(color: darkBackground, fontSize: 16.sp),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () =>
                              context.pushReplacement(RouteList.biaTrikeOnboarding),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          child: const Text('Apply Now',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                final formattedDate =
                    DateFormat('dd MMM yyyy, hh:mm a').format(app.submittedAt);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),

                      Container(
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: primaryGreenColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: primaryGreenColor,
                          size: 52.sp,
                        ),
                      ).animate().scale(duration: 400.ms),

                      SizedBox(height: 16.h),

                      Text(
                        'Application Submitted!',
                        style: TextStyle(
                          color: darkBackground,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Your application has been received and queued for physical verification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: 12.5.sp,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(20.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8.r),
                                            decoration: BoxDecoration(
                                              color: primaryColor
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.electric_rickshaw_rounded,
                                              color: primaryColor,
                                              size: 18.sp,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            'BIA TRIKE PASS',
                                            style: TextStyle(
                                              color: darkBackground,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13.sp,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          'VERIFYING',
                                          style: TextStyle(
                                            color: const Color(0xFFF59E0B),
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 20.h),
                                  Divider(color: Colors.grey.shade200),
                                  SizedBox(height: 12.h),

                                  _buildPassItem('RIDER NAME', app.fullName),
                                  SizedBox(height: 12.h),
                                  _buildPassItem('PHONE NUMBER', app.phoneNumber),
                                  SizedBox(height: 12.h),
                                  _buildPassItem(
                                      'CITY OF OPERATION', app.cityOfOperation),
                                  SizedBox(height: 12.h),
                                  _buildPassItem('TRIKE MODEL', app.trikeModel),
                                  SizedBox(height: 12.h),
                                  _buildPassItem('PLATE NUMBER', app.plateNumber),
                                  SizedBox(height: 12.h),
                                  _buildPassItem('NIN / LICENSE',
                                      app.licenseOrNinNumber),
                                  SizedBox(height: 12.h),
                                  _buildPassItem('SUBMITTED ON', formattedDate),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await ref
                                    .read(biaTrikeProvider.notifier)
                                    .clearApplication();
                                if (context.mounted) {
                                  ToastHelper.showToast(
                                    context: context,
                                    message: "Application reset.",
                                    icon: Icons.info_outline,
                                    iconColor: primaryColor,
                                  );
                                  context.pushReplacement(
                                      RouteList.biaTrikeOnboarding);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text(
                                'Edit Application',
                                style: TextStyle(
                                  color: darkBackground,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                context.go(RouteList.bottomNavBar);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text(
                                'Go to Home',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: lightSecondaryText,
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            color: darkBackground,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
