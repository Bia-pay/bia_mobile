import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/widgets/keypad.dart';

class RestoreNewPin extends ConsumerStatefulWidget {

  const RestoreNewPin({super.key,});

  @override
  ConsumerState<RestoreNewPin> createState() => _RestoreNewPinState();
}

class _RestoreNewPinState extends ConsumerState<RestoreNewPin> {
  String pin = "";
  bool showWarning = false;
  void addDigit(String value) {
    if (pin.length >= 4) return;

    setState(() {
      pin += value;
      showWarning = false;
    });

    if (pin.length == 4) {
      context.pushNamed(
        RouteList.confirmRestoreNewPin,
        extra: pin,
      );
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
        child: Column(
          children: [
            SizedBox(height: 50.h),

            /// Lock icon card
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.4),
                    primaryColor,
                    primaryColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.lock, color: Colors.white, size: 30.sp),
            ),

            SizedBox(height: 20.h),

            Text(
              "Set Transaction PIN",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 15.h),

            Text(
              "Enter a new 4-digit PIN",
              style: theme.textTheme.bodySmall,
            ),

            SizedBox(height: 40.h),

            /// PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16,
                  height: 16,
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: filled ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: filled ? inactiveColor : disabledTextColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            if (showWarning)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Text(
                  "PIN must be 4 digits",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            SizedBox(height: 70.h),

            Expanded(
              child: CustomGridKeypad(
                onNumberPressed: addDigit,
                leftAction: ActionKey(
                  child: Icon(Icons.check, color: Colors.white),
                  backgroundColor: primaryColor,
                  onTap: () {
                    if (pin.length == 4) {
                      context.pushNamed(
                        RouteList.confirmRestoreNewPin,
                        extra: pin,
                      );
                    } else {
                      setState(() => showWarning = true);
                    }
                  },
                ),
                rightAction: ActionKey(
                  child: Icon(Icons.backspace, color: primaryColor),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ConfirmRestoreNewPin extends ConsumerStatefulWidget {
  final String newPin;

  const ConfirmRestoreNewPin({
    super.key,
    required this.newPin,
  });

  @override
  ConsumerState<ConfirmRestoreNewPin> createState() => _ConfirmRestoreNewPinState();
}

class _ConfirmRestoreNewPinState extends ConsumerState<ConfirmRestoreNewPin> {
  String pin = "";
  bool showError = false;

  void addDigit(String value) {
    if (pin.length >= 4) return;

    setState(() {
      pin += value;
      showError = false;
    });

    if (pin.length == 4) {
      _submit();
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _submit() async {
    if (pin != widget.newPin) {
      setState(() {
        pin = "";
        showError = true;
      });
      return;
    }

    final controller =
    ref.read(dashboardControllerProvider.notifier);

    final response = await controller.resetForgotPin(
      context,
      widget.newPin,
      pin,
    );

    if (response != null &&
        response.responseSuccessful &&
        mounted) {
      context.goNamed(RouteList.bottomNavBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
        child: Column(
          children: [
            SizedBox(height: 50.h),

            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.4),
                    primaryColor,
                    primaryColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.lock_outline,
                  color: Colors.white, size: 30.sp),
            ),

            SizedBox(height: 20.h),

            Text(
              "Confirm PIN",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 15.h),

            Text(
              "Re-enter your 4-digit PIN",
              style: theme.textTheme.bodySmall,
            ),

            SizedBox(height: 40.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16,
                  height: 16,
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: filled ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: filled ? inactiveColor : disabledTextColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            if (showError)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Text(
                  "PINs do not match",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            SizedBox(height: 70.h),

            Expanded(
              child: CustomGridKeypad(
                onNumberPressed: addDigit,
                leftAction: ActionKey(
                  child: Icon(Icons.check, color: Colors.white),
                  backgroundColor: primaryColor,
                  onTap: _submit,
                ),
                rightAction: ActionKey(
                  child: Icon(Icons.backspace, color: primaryColor),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}