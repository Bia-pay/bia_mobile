import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/colors.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../dashboard/dashboard_repo/repo.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/widgets/keypad.dart';

class ChangePaymentPin extends ConsumerStatefulWidget {
  const ChangePaymentPin({super.key});

  @override
  ConsumerState<ChangePaymentPin> createState() =>
      _ChangePaymentPinState();
}

class _ChangePaymentPinState extends ConsumerState<ChangePaymentPin> {
  String pin = "";
  bool showWarning = false;

  void addDigit(String value) {
    if (pin.length >= 4) return;

    setState(() {
      pin += value;
      showWarning = false;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;

    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  void _goNext() {
    if (pin.length != 4) {
      setState(() => showWarning = true);
      return;
    }

    context.pushNamed(
      RouteList.changeNewPaymentPin,
      extra: pin,
    );
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

            /// Lock Card (same as transaction pin)
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
              child:
              Icon(Icons.lock, color: Colors.white, size: 30.sp),
            ),

            SizedBox(height: 20.h),

            Text(
              "Enter Old PIN",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 40.h),

            /// PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < pin.length;

                return AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 150),
                  width: 16,
                  height: 16,
                  margin:
                  EdgeInsets.symmetric(horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: filled
                        ? primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? inactiveColor
                          : disabledTextColor,
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
                  child: Icon(Icons.check,
                      color: Colors.white),
                  backgroundColor: primaryColor,
                  onTap: _goNext,
                ),
                rightAction: ActionKey(
                  child: Icon(Icons.backspace,
                      color: primaryColor),
                  backgroundColor:
                  primaryColor.withOpacity(0.1),
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



class SetNewPin extends ConsumerStatefulWidget {
  final String oldPin;

  const SetNewPin({super.key, required this.oldPin});

  @override
  ConsumerState<SetNewPin> createState() => _SetNewPinState();
}

class _SetNewPinState extends ConsumerState<SetNewPin> {
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
        RouteList.confirmChangeNewPaymentPin,
        extra: {
          "oldPin": widget.oldPin,
          "newPin": pin,
        },
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
                        RouteList.confirmChangeNewPaymentPin,
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


class ConfirmSetNewPin extends ConsumerStatefulWidget {
  final String oldPin;
  final String newPin;

  const ConfirmSetNewPin({
    super.key,
    required this.oldPin,
    required this.newPin,
  });

  @override
  ConsumerState<ConfirmSetNewPin> createState() => _ConfirmSetNewPinState();
}

class _ConfirmSetNewPinState extends ConsumerState<ConfirmSetNewPin> {
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

    final response = await controller.changePin(
      context,
      widget.oldPin,
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
