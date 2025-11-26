import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/utils/widgets/pin_field.dart';
import '../dashboardcontroller/dashboardcontroller.dart';

class PinModalManager {
  /// 🔐 Step 1: Show old PIN first (for change flow)
  static void showPinModal(BuildContext context, bool isForgot) {
    final TextEditingController oldPin = TextEditingController();
    final TextEditingController newPin = TextEditingController();
    final TextEditingController confirmPin = TextEditingController();
    final theme = context.themeContext;

    if (isForgot) {
      // Directly show reset modal if user forgot PIN
      _showNewPinModal(context, newPin, confirmPin, theme, isForgot: true);
      return;
    }

    // Step 1: Ask for old PIN
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.tertiaryBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          25,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Payment PIN',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 25.h),
              Text('Enter Old PIN', style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 8.h),

              AppPinCodeField(
                controller: oldPin,
                length: 4,
                obscure: true,
                onCompleted: (value) {
                  Navigator.pop(context); // close old PIN modal
                  // Next step: show new + confirm modal
                  _showNewPinModal(context, newPin, confirmPin, theme);
                },
                onChanged: (value) => oldPin.text = value,
              ),

              SizedBox(height: 20.h),
              Text(
                "Enter your old PIN to continue",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
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
      TextEditingController confirmPin,
      dynamic theme, {
        bool isForgot = false,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.tertiaryBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          25,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isForgot ? 'Reset Payment PIN' : 'Set New Payment PIN',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 25.h),

              Text('Enter New PIN', style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 8.h),
              AppPinCodeField(
                controller: newPin,
                length: 4,
                obscure: true,
                onChanged: (v) => newPin.text = v,
              ),
              SizedBox(height: 15.h),

              Text('Confirm New PIN', style: Theme.of(context).textTheme.bodyMedium),
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
                  backgroundColor: theme.kPrimary,
                  minimumSize: const Size(double.infinity, 50),
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
                      content: Text(isForgot
                          ? 'PIN reset successfully'
                          : 'PIN changed successfully'),
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
  static Future<bool?> showSetPinModal(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final theme = Theme.of(context);

    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final controller = ref.read(dashboardControllerProvider.notifier);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              25,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Set Transaction PIN",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 25.h),

                  Text("Enter 4-digit PIN",
                      style: theme.textTheme.bodyMedium),
                  SizedBox(height: 8.h),
                  AppPinCodeField(
                    controller: pinController,
                    length: 4,
                    obscure: true,
                    onChanged: (v) => pinController.text = v,
                  ),

                  SizedBox(height: 15.h),
                  Text("Confirm PIN", style: theme.textTheme.bodyMedium),
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
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
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