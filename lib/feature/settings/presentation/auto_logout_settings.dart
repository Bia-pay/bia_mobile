import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../app/utils/colors.dart';
import '../../../../core/services/session_service.dart';

class AutoLogoutSettingsScreen extends ConsumerWidget {
  const AutoLogoutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settingsBox').listenable(),
      builder: (context, box, child) {
        final isEnabled = box.get('auto_logout_enabled', defaultValue: true);
        final currentDuration = box.get('auto_logout_duration', defaultValue: 5);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: lightText),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Auto Logout Settings",
              style: TextStyle(
                color: lightText,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ENABLE TOGGLE
                _buildSectionHeader("Activation"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(18.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enable Auto Logout",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: lightText,
                                ),
                              ),
                              Text(
                                "Automatically log out after a period of inactivity.",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: lightSecondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          activeColor: primaryColor,
                          onChanged: (value) async {
                            await box.put('auto_logout_enabled', value);
                            ref.read(sessionServiceProvider.notifier).resetTimer();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 35.h),

                /// DURATION SELECTION
                if (isEnabled) ...[
                  _buildSectionHeader("Inactivity Period"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDurationOption(box, ref, 1, "1 Minute"),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildDurationOption(box, ref, 2, "2 Minutes"),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildDurationOption(box, ref, 5, "5 Minutes", isDefault: true),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildDurationOption(box, ref, 10, "10 Minutes"),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 40.h),

                /// INFO CARD
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, color: primaryColor, size: 22.sp),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          "Auto logout enhances your account security by preventing unauthorized access if your phone is left unattended.",
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.8),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDurationOption(Box box, WidgetRef ref, int duration, String label, {bool isDefault = false}) {
    final currentDuration = box.get('auto_logout_duration', defaultValue: 5);
    final isSelected = currentDuration == duration;

    return InkWell(
      onTap: () async {
        await box.put('auto_logout_duration', duration);
        ref.read(sessionServiceProvider.notifier).resetTimer();
      },
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Row(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: lightText,
                ),
              ),
            ),
            if (isDefault)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  "Default",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
