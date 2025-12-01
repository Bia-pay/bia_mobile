import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/utils/widgets/pin_field.dart';
import '../../../app/utils/colors.dart';
import '../dashboardcontroller/dashboardcontroller.dart';

class PinModalManager {
  /// 🔐 Step 1: Show old PIN first (for change flow)
  static void showPinModal(BuildContext context, bool isForgot) {
    final TextEditingController oldPin = TextEditingController();
    final TextEditingController newPin = TextEditingController();
    final TextEditingController confirmPin = TextEditingController();

    if (isForgot) {
      // Directly show reset modal if user forgot PIN
      _showNewPinModal(context, newPin, confirmPin, isForgot: true);
      return;
    }

    // Step 1: Ask for old PIN
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          25.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Payment PIN',
                style: TextStyle(
                  color: lightText,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 25.h),
              Text('Enter Old PIN', style: TextStyle(color: lightSecondaryText, fontSize: 16.sp)),
              SizedBox(height: 8.h),

              AppPinCodeField(
                controller: oldPin,
                length: 4,
                obscure: true,
                onCompleted: (_) {
                  Navigator.pop(context);
                  _showNewPinModal(context, newPin, confirmPin);
                },
                onChanged: (value) => oldPin.text = value,
              ),

              SizedBox(height: 20.h),
              Text(
                "Enter your old PIN to continue",
                style: TextStyle(color: kGray, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔁 Step 2: Show modal for new + confirm PIN
  static void _showNewPinModal(
      BuildContext context,
      TextEditingController newPin,
      TextEditingController confirmPin, {
        bool isForgot = false,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          25.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isForgot ? 'Reset Payment PIN' : 'Set New Payment PIN',
                style: TextStyle(
                  color: lightText,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 25.h),

              Text('Enter New PIN', style: TextStyle(color: lightSecondaryText, fontSize: 16.sp)),
              SizedBox(height: 8.h),
              AppPinCodeField(
                controller: newPin,
                length: 4,
                obscure: true,
                onChanged: (v) => newPin.text = v,
              ),
              SizedBox(height: 15.h),

              Text('Confirm New PIN', style: TextStyle(color: lightSecondaryText, fontSize: 16.sp)),
              SizedBox(height: 8.h),
              AppPinCodeField(
                controller: confirmPin,
                length: 4,
                obscure: true,
                onChanged: (v) => confirmPin.text = v,
              ),

              SizedBox(height: 25.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: Size(double.infinity, 50.h),
                ),
                onPressed: () {
                  if (newPin.text != confirmPin.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("PINs do not match"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isForgot ? 'PIN reset successfully' : 'PIN changed successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(isForgot ? 'Reset PIN' : 'Update PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Set PIN modal for first time
  static Future<bool?> showSetPinModal(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final controller = ref.read(dashboardControllerProvider.notifier);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              25.h,
              20.w,
              MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Set Transaction PIN",
                    style: TextStyle(
                      color: lightText,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 25.h),

                  Text("Enter 4-digit PIN", style: TextStyle(color: lightSecondaryText, fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  AppPinCodeField(
                    controller: pinController,
                    length: 4,
                    obscure: true,
                    onChanged: (v) => pinController.text = v,
                  ),

                  SizedBox(height: 15.h),
                  Text("Confirm PIN", style: TextStyle(color: lightSecondaryText, fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  AppPinCodeField(
                    controller: confirmController,
                    length: 4,
                    obscure: true,
                    onChanged: (v) => confirmController.text = v,
                  ),

                  SizedBox(height: 25.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: Size(double.infinity, 50.h),
                    ),
                    onPressed: () async {
                      if (pinController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("PINs do not match"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final response = await controller.setPin(
                        context,
                        pinController.text.trim(),
                        confirmController.text.trim(),
                      );

                      if (response?.responseSuccessful == true) {
                        Navigator.pop(context, true); // ✅ PIN created
                      }
                    },
                    child: const Text("Set PIN"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}