import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/colors.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/services/biometric_service.dart';
import '../../dashboard/dashboard_repo/repo.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    // Adaptive spacing
    final topSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 70.h : 50.h);
    final sectionSpacing = isSmallScreen ? 12.h : (isLargeScreen ? 24.h : 20.h);
    final pinSpacing = isSmallScreen ? 24.h : (isLargeScreen ? 50.h : 40.h);
    final keypadSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 70.h);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: isSmallScreen ? 20.h : 30.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topSpacing),

                      /// Lock Card
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12.w : 15.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.4),
                              primaryColor,
                              primaryColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 8.r : 10.r,
                          ),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: isSmallScreen ? 24.sp : 30.sp,
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      Text(
                        "Enter Old PIN",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 18.sp : (isLargeScreen ? 24.sp : 22.sp),
                        ),
                      ),

                      SizedBox(height: pinSpacing),

                      /// PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < pin.length;
                          final dotSize = isSmallScreen ? 14.w : 16.w;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: dotSize,
                            height: dotSize,
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            decoration: BoxDecoration(
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: filled ? inactiveColor : disabledTextColor,
                                width: isSmallScreen ? 1.5 : 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),

                      if (showWarning)
                        Padding(
                          padding: EdgeInsets.only(top: isSmallScreen ? 10.h : 15.h),
                          child: Text(
                            "PIN must be 4 digits",
                            style: TextStyle(
                              color: errorColor,
                              fontSize: isSmallScreen ? 12.sp : 14.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: keypadSpacing),

                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: ActionKey(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor,
                            onTap: _goNext,
                          ),
                          rightAction: ActionKey(
                            child: Icon(
                              Icons.backspace,
                              color: primaryColor,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            onTap: removeDigit,
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 10.h : 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    // Adaptive spacing
    final topSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 70.h : 50.h);
    final sectionSpacing = isSmallScreen ? 12.h : (isLargeScreen ? 24.h : 20.h);
    final pinSpacing = isSmallScreen ? 24.h : (isLargeScreen ? 50.h : 40.h);
    final keypadSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 70.h);

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: isSmallScreen ? 20.h : 30.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topSpacing),

                      /// Lock icon card
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12.w : 15.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.4),
                              primaryColor,
                              primaryColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 8.r : 10.r,
                          ),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: isSmallScreen ? 24.sp : 30.sp,
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      Text(
                        "Set Transaction PIN",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 18.sp : (isLargeScreen ? 24.sp : 22.sp),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 10.h : 15.h),

                      Text(
                        "Enter a new 4-digit PIN",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isSmallScreen ? 12.sp : 14.sp,
                        ),
                      ),

                      SizedBox(height: pinSpacing),

                      /// PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < pin.length;
                          final dotSize = isSmallScreen ? 14.w : 16.w;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: dotSize,
                            height: dotSize,
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            decoration: BoxDecoration(
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: filled ? inactiveColor : disabledTextColor,
                                width: isSmallScreen ? 1.5 : 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),

                      if (showWarning)
                        Padding(
                          padding: EdgeInsets.only(top: isSmallScreen ? 10.h : 15.h),
                          child: Text(
                            "PIN must be 4 digits",
                            style: TextStyle(
                              color: errorColor,
                              fontSize: isSmallScreen ? 12.sp : 14.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: keypadSpacing),

                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: ActionKey(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: isSmallScreen ? 20.sp : 24.sp,
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
                              Icons.backspace,
                              color: primaryColor,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            onTap: removeDigit,
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 10.h : 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
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
      // Save new PIN securely for biometric use
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    // Adaptive spacing
    final topSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 70.h : 50.h);
    final sectionSpacing = isSmallScreen ? 12.h : (isLargeScreen ? 24.h : 20.h);
    final pinSpacing = isSmallScreen ? 24.h : (isLargeScreen ? 50.h : 40.h);
    final keypadSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 70.h);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: isSmallScreen ? 20.h : 30.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topSpacing),

                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12.w : 15.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.4),
                              primaryColor,
                              primaryColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 8.r : 10.r,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: isSmallScreen ? 24.sp : 30.sp,
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      Text(
                        "Confirm PIN",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 18.sp : (isLargeScreen ? 24.sp : 22.sp),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 10.h : 15.h),

                      Text(
                        "Re-enter your 4-digit PIN",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isSmallScreen ? 12.sp : 14.sp,
                        ),
                      ),

                      SizedBox(height: pinSpacing),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < pin.length;
                          final dotSize = isSmallScreen ? 14.w : 16.w;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: dotSize,
                            height: dotSize,
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            decoration: BoxDecoration(
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: filled ? inactiveColor : disabledTextColor,
                                width: isSmallScreen ? 1.5 : 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),

                      if (showError)
                        Padding(
                          padding: EdgeInsets.only(top: isSmallScreen ? 10.h : 15.h),
                          child: Text(
                            "PINs do not match",
                            style: TextStyle(
                              color: errorColor,
                              fontSize: isSmallScreen ? 12.sp : 14.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: keypadSpacing),

                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: ActionKey(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor,
                            onTap: _submit,
                          ),
                          rightAction: ActionKey(
                            child: Icon(
                              Icons.backspace,
                              color: primaryColor,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            onTap: removeDigit,
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 10.h : 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}