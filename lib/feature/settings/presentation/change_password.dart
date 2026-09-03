import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/widgets/keypad.dart';

class ChangePaymentPin extends ConsumerStatefulWidget {
  const ChangePaymentPin({super.key});

  @override
  ConsumerState<ChangePaymentPin> createState() => _ChangePaymentPinState();
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
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: isTablet ? 18.0 : 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 330 : double.infinity),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 0 : 24.w,
                vertical: isTablet ? 10.0 : 30.h,
              ),
              child: Column(
                children: [
                  SizedBox(height: isTablet ? 30.0 : 30.h),

                  /// Lock Card
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12.0 : 15.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.4),
                          primaryColor,
                          primaryColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
                    ),
                    child: Icon(Icons.lock, color: Colors.white, size: isTablet ? 24.0 : 30.sp),
                  ),

                  SizedBox(height: isTablet ? 16.0 : 20.h),

                  Text(
                    "Enter Old PIN",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 18.0 : 22.sp,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: isTablet ? 20.0 : 40.h),

                  /// PIN dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isTablet ? 12.0 : 16.w,
                        height: isTablet ? 12.0 : 16.w,
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 5.0 : 6.w),
                        decoration: BoxDecoration(
                          color: filled ? primaryColor : Colors.transparent,
                          border: Border.all(
                            color: filled ? primaryColor : Colors.grey.shade400,
                            width: isTablet ? 1.5 : 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  if (showWarning)
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 10.0 : 15.h),
                      child: Text(
                        "PIN must be 4 digits",
                        style: TextStyle(
                          color: errorColor,
                          fontSize: isTablet ? 12.0 : 14.sp,
                        ),
                      ),
                    ),

                  SizedBox(height: isTablet ? 20.0 : 40.h),

                  CustomGridKeypad(
                    onNumberPressed: addDigit,
                    leftAction: ActionKey(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isTablet ? 20.0 : 24.sp,
                      ),
                      backgroundColor: primaryColor,
                      onTap: _goNext,
                    ),
                    rightAction: ActionKey(
                      child: Icon(
                        Icons.backspace_rounded,
                        color: primaryColor,
                        size: isTablet ? 20.0 : 24.sp,
                      ),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      onTap: removeDigit,
                    ),
                  ),

                  SizedBox(height: isTablet ? 10.0 : 20.h),
                ],
              ),
            ),
          ),
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
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: isTablet ? 18.0 : 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 330 : double.infinity),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 0 : 24.w,
                vertical: isTablet ? 10.0 : 30.h,
              ),
              child: Column(
                children: [
                  SizedBox(height: isTablet ? 30.0 : 30.h),

                  /// Lock icon card
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12.0 : 15.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.4),
                          primaryColor,
                          primaryColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
                    ),
                    child: Icon(Icons.lock, color: Colors.white, size: isTablet ? 24.0 : 30.sp),
                  ),

                  SizedBox(height: isTablet ? 16.0 : 20.h),

                  Text(
                    "Set Transaction PIN",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 18.0 : 22.sp,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: isTablet ? 6.0 : 15.h),

                  Text(
                    "Enter a new 4-digit PIN",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isTablet ? 12.0 : 14.sp,
                    ),
                  ),

                  SizedBox(height: isTablet ? 20.0 : 40.h),

                  /// PIN dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isTablet ? 12.0 : 16.w,
                        height: isTablet ? 12.0 : 16.w,
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 5.0 : 6.w),
                        decoration: BoxDecoration(
                          color: filled ? primaryColor : Colors.transparent,
                          border: Border.all(
                            color: filled ? primaryColor : Colors.grey.shade400,
                            width: isTablet ? 1.5 : 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  if (showWarning)
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 10.0 : 15.h),
                      child: Text(
                        "PIN must be 4 digits",
                        style: TextStyle(
                          color: errorColor,
                          fontSize: isTablet ? 12.0 : 14.sp,
                        ),
                      ),
                    ),

                  SizedBox(height: isTablet ? 20.0 : 40.h),

                  CustomGridKeypad(
                    onNumberPressed: addDigit,
                    leftAction: ActionKey(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isTablet ? 20.0 : 24.sp,
                      ),
                      backgroundColor: primaryColor,
                      onTap: () {
                        if (pin.length == 4) {
                          context.pushNamed(
                            RouteList.confirmChangeNewPaymentPin,
                            extra: {
                              "oldPin": widget.oldPin,
                              "newPin": pin,
                            },
                          );
                        } else {
                          setState(() => showWarning = true);
                        }
                      },
                    ),
                    rightAction: ActionKey(
                      child: Icon(
                        Icons.backspace_rounded,
                        color: primaryColor,
                        size: isTablet ? 20.0 : 24.sp,
                      ),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      onTap: removeDigit,
                    ),
                  ),

                  SizedBox(height: isTablet ? 10.0 : 20.h),
                ],
              ),
            ),
          ),
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

    final controller = ref.read(dashboardControllerProvider.notifier);

    final response = await controller.changePin(
      context,
      widget.oldPin,
      widget.newPin,
      pin,
    );

    if (response != null && response.responseSuccessful) {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isNotEmpty) {
        final biometricService = BiometricService();
        await biometricService.saveTransactionPin(effectiveUserId, pin);
      }

      if (mounted) {
        context.goNamed(RouteList.bottomNavBar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: isTablet ? 18.0 : 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 330 : double.infinity),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 0 : 24.w,
                vertical: isTablet ? 10.0 : 30.h,
              ),
              child: Column(
                children: [
                  SizedBox(height: isTablet ? 30.0 : 30.h),

                  Container(
                    padding: EdgeInsets.all(isTablet ? 12.0 : 15.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.4),
                          primaryColor,
                          primaryColor.withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
                    ),
                    child: Icon(Icons.lock_outline, color: Colors.white, size: isTablet ? 24.0 : 30.sp),
                  ),

                  SizedBox(height: isTablet ? 16.0 : 20.h),

                  Text(
                    "Confirm PIN",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 18.0 : 22.sp,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: isTablet ? 6.0 : 15.h),

                  Text(
                    "Re-enter your 4-digit PIN",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isTablet ? 12.0 : 14.sp,
                    ),
                  ),

                  SizedBox(height: isTablet ? 20.0 : 40.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isTablet ? 12.0 : 16.w,
                        height: isTablet ? 12.0 : 16.w,
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 5.0 : 6.w),
                        decoration: BoxDecoration(
                          color: filled ? primaryColor : Colors.transparent,
                          border: Border.all(
                            color: filled ? primaryColor : Colors.grey.shade400,
                            width: isTablet ? 1.5 : 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  if (showError)
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 10.0 : 15.h),
                      child: Text(
                        "PINs do not match",
                        style: TextStyle(
                          color: errorColor,
                          fontSize: isTablet ? 12.0 : 14.sp,
                        ),
                      ),
                    ),

                  SizedBox(height: isTablet ? 20.0 : 40.h),

                  CustomGridKeypad(
                    onNumberPressed: addDigit,
                    leftAction: ActionKey(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isTablet ? 20.0 : 24.sp,
                      ),
                      backgroundColor: primaryColor,
                      onTap: _submit,
                    ),
                    rightAction: ActionKey(
                      child: Icon(
                        Icons.backspace_rounded,
                        color: primaryColor,
                        size: isTablet ? 20.0 : 24.sp,
                      ),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      onTap: removeDigit,
                    ),
                  ),

                  SizedBox(height: isTablet ? 10.0 : 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}