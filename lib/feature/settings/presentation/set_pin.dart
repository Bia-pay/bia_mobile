import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../core/services/biometric_service.dart';
import '../../../feature/dashboard/widgets/keypad.dart';
import '../../dashboard/dashboard_repo/repo.dart';

class SetPin extends ConsumerStatefulWidget {
  const SetPin({super.key});

  @override
  ConsumerState<SetPin> createState() => _SetPinState();
}

class _SetPinState extends ConsumerState<SetPin> {
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
        RouteList.confirmSetPin,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;
    final isTablet = screenWidth > 600;

    // Adaptive spacing
    final topSpacing = isTablet ? 20.0 : (isSmallScreen ? 30.h : (isLargeScreen ? 70.h : 50.h));
    final sectionSpacing = isTablet ? 14.0 : (isSmallScreen ? 12.h : (isLargeScreen ? 24.h : 20.h));
    final pinSpacing = isTablet ? 28.0 : (isSmallScreen ? 24.h : (isLargeScreen ? 50.h : 40.h));
    final keypadSpacing = isTablet ? 30.0 : (isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 70.h));

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
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : double.infinity),
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
                        horizontal: isTablet ? 32.0 : 24.w,
                        vertical: isTablet ? 16.0 : (isSmallScreen ? 20.h : 30.h),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: topSpacing),

                          /// Lock icon card
                          Container(
                            padding: EdgeInsets.all(isTablet ? 14.0 : (isSmallScreen ? 12.w : 15.w)),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.4),
                                  primaryColor,
                                  primaryColor.withOpacity(0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isTablet ? 10.0 : (isSmallScreen ? 8.r : 10.r),
                              ),
                            ),
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: isTablet ? 26.0 : (isSmallScreen ? 24.sp : 30.sp),
                            ),
                          ),

                          SizedBox(height: sectionSpacing),

                          Text(
                            "Set Transaction PIN",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 22.0 : (isSmallScreen ? 18.sp : (isLargeScreen ? 24.sp : 22.sp)),
                            ),
                          ),

                          SizedBox(height: isTablet ? 10.0 : (isSmallScreen ? 10.h : 15.h)),

                          Text(
                            "Enter a new 4-digit PIN",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: isTablet ? 14.0 : (isSmallScreen ? 12.sp : 14.sp),
                            ),
                          ),

                          SizedBox(height: pinSpacing),

                          /// PIN dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final filled = index < pin.length;
                              final dotSize = isTablet ? 14.0 : (isSmallScreen ? 14.w : 16.w);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: dotSize,
                                height: dotSize,
                                margin: EdgeInsets.symmetric(horizontal: isTablet ? 6.0 : 6.w),
                                decoration: BoxDecoration(
                                  color: filled ? primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: filled ? inactiveColor : disabledTextColor,
                                    width: isTablet ? 1.5 : (isSmallScreen ? 1.5 : 2),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),

                          if (showWarning)
                            Padding(
                              padding: EdgeInsets.only(top: isTablet ? 12.0 : (isSmallScreen ? 10.h : 15.h)),
                              child: Text(
                                "PIN must be 4 digits",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: isTablet ? 13.0 : (isSmallScreen ? 12.sp : 14.sp),
                                ),
                              ),
                            ),

                          SizedBox(height: keypadSpacing),

                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: isTablet ? 360 : double.infinity),
                              child: SizedBox(
                                height: isTablet ? 370.0 : null,
                                child: CustomGridKeypad(
                                  onNumberPressed: addDigit,
                                  leftAction: ActionKey(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                    ),
                                    backgroundColor: primaryColor,
                                    onTap: () {
                                      if (pin.length == 4) {
                                        context.pushNamed(
                                          RouteList.confirmSetPin,
                                          extra: pin,
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
                                      size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                    ),
                                    backgroundColor: primaryColor.withOpacity(0.1),
                                    onTap: removeDigit,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 16.0 : (isSmallScreen ? 10.h : 20.h)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ConfirmSetPin extends ConsumerStatefulWidget {
  final String originalPin;

  const ConfirmSetPin({super.key, required this.originalPin});

  @override
  ConsumerState<ConfirmSetPin> createState() => _ConfirmSetPinState();
}

class _ConfirmSetPinState extends ConsumerState<ConfirmSetPin> {
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
    if (pin != widget.originalPin) {
      setState(() {
        pin = "";
        showError = true;
      });
      return;
    }

    final repo = ref.read(dashboardRepositoryProvider);

    final response = await repo.setPin({
      "pin": pin,
      "confirmPin": pin,
    });

    if (response.responseSuccessful) {
      final box = Hive.box('authBox');
      await box.put('has_pin', true);

      // Save PIN securely for biometric use
      final userId = box.get('userId', defaultValue: '');
      final phone = box.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isNotEmpty) {
        final biometricService = BiometricService();
        await biometricService.saveTransactionPin(effectiveUserId, pin);
        debugPrint('🔐 Transaction PIN saved securely for user: $effectiveUserId');
      }

      if (!mounted) return;
      context.goNamed(RouteList.bottomNavBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;
    final isTablet = screenWidth > 600;

    // Adaptive spacing
    final topSpacing = isTablet ? 20.0 : (isSmallScreen ? 30.h : (isLargeScreen ? 70.h : 50.h));
    final sectionSpacing = isTablet ? 14.0 : (isSmallScreen ? 12.h : (isLargeScreen ? 24.h : 20.h));
    final pinSpacing = isTablet ? 28.0 : (isSmallScreen ? 24.h : (isLargeScreen ? 50.h : 40.h));
    final keypadSpacing = isTablet ? 30.0 : (isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 70.h));

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : double.infinity),
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
                        horizontal: isTablet ? 32.0 : 24.w,
                        vertical: isTablet ? 16.0 : (isSmallScreen ? 20.h : 30.h),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: topSpacing),

                          Container(
                            padding: EdgeInsets.all(isTablet ? 14.0 : (isSmallScreen ? 12.w : 15.w)),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.4),
                                  primaryColor,
                                  primaryColor.withOpacity(0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isTablet ? 10.0 : (isSmallScreen ? 8.r : 10.r),
                              ),
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: isTablet ? 26.0 : (isSmallScreen ? 24.sp : 30.sp),
                            ),
                          ),

                          SizedBox(height: sectionSpacing),

                          Text(
                            "Confirm PIN",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 22.0 : (isSmallScreen ? 18.sp : (isLargeScreen ? 24.sp : 22.sp)),
                            ),
                          ),

                          SizedBox(height: isTablet ? 10.0 : (isSmallScreen ? 10.h : 15.h)),

                          Text(
                            "Re-enter your 4-digit PIN",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: isTablet ? 14.0 : (isSmallScreen ? 12.sp : 14.sp),
                            ),
                          ),

                          SizedBox(height: pinSpacing),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final filled = index < pin.length;
                              final dotSize = isTablet ? 14.0 : (isSmallScreen ? 14.w : 16.w);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: dotSize,
                                height: dotSize,
                                margin: EdgeInsets.symmetric(horizontal: isTablet ? 6.0 : 6.w),
                                decoration: BoxDecoration(
                                  color: filled ? primaryColor : Colors.transparent,
                                  border: Border.all(
                                    color: filled ? inactiveColor : disabledTextColor,
                                    width: isTablet ? 1.5 : (isSmallScreen ? 1.5 : 2),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),

                          if (showError)
                            Padding(
                              padding: EdgeInsets.only(top: isTablet ? 12.0 : (isSmallScreen ? 10.h : 15.h)),
                              child: Text(
                                "PINs do not match",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: isTablet ? 13.0 : (isSmallScreen ? 12.sp : 14.sp),
                                ),
                              ),
                            ),

                          SizedBox(height: keypadSpacing),

                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: isTablet ? 360 : double.infinity),
                              child: SizedBox(
                                height: isTablet ? 370.0 : null,
                                child: CustomGridKeypad(
                                  onNumberPressed: addDigit,
                                  leftAction: ActionKey(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                    ),
                                    backgroundColor: primaryColor,
                                    onTap: _submit,
                                  ),
                                  rightAction: ActionKey(
                                    child: Icon(
                                      Icons.backspace_rounded,
                                      color: primaryColor,
                                      size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                    ),
                                    backgroundColor: primaryColor.withOpacity(0.1),
                                    onTap: removeDigit,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 16.0 : (isSmallScreen ? 10.h : 20.h)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}