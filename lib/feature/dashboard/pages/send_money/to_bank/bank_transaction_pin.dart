import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../../../core/services/security_service.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class BankTransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;
  final String bankCode;
  final String bankName;
  final String? narration;

  const BankTransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
    required this.bankCode,
    required this.bankName,
    this.narration,
  });

  @override
  ConsumerState<BankTransactionPin> createState() => _BankTransactionPinState();
}

class _BankTransactionPinState extends ConsumerState<BankTransactionPin> {
  String pin = "";
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  bool _isProcessing = false;
  IconData _biometricIcon = Icons.fingerprint_rounded;

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) return;

      final biometricService = BiometricService();
      final isAvailable = await biometricService.canCheckBiometrics();
      final isEnabled = await biometricService.isPaymentEnabled(effectiveUserId);
      final savedPin = await biometricService.getTransactionPin(effectiveUserId);
      final icon = await biometricService.getBiometricIcon();

      if (mounted) {
        setState(() {
          _hasBiometric = isAvailable;
          _biometricEnabled = isEnabled && savedPin != null;
          _biometricIcon = icon;
        });
      }

      if (isAvailable && isEnabled && savedPin != null) {
        Future.delayed(const Duration(milliseconds: 500), _authenticateWithBiometric);
      }
    } catch (e) {
      debugPrint('❌ Bank PIN biometric init error: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating || !_hasBiometric || !_biometricEnabled || _isProcessing) return;
    setState(() => _isAuthenticating = true);
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      final biometricService = BiometricService();
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to complete bank transfer',
        biometricOnly: true,
      );

      if (!authenticated) return;

      final savedPin = await biometricService.getTransactionPin(effectiveUserId);
      if (savedPin != null && savedPin.isNotEmpty) {
        await _processTransfer(savedPin);
      }
    } catch (e) {
      debugPrint('⚠️ Biometric error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void addDigit(String value) {
    if (pin.length >= 4 || _isProcessing) return;
    setState(() {
      pin += value;
    });

    if (pin.length == 4) {
      _processTransfer(pin);
    }
  }

  void removeDigit() {
    if (pin.isEmpty || _isProcessing) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _processTransfer(String transactionPin) async {
    if (transactionPin.length < 4 || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    final controller = ref.read(dashboardControllerProvider.notifier);
    EasyLoading.show(status: 'Processing...');

    try {
      final response = await controller.sendMoneyToBank(
        context,
        accountNumber: widget.recipientAccount,
        bankCode: widget.bankCode,
        bankName: widget.bankName,
        amount: widget.amount.toStringAsFixed(2),
        narration: widget.narration?.isNotEmpty == true ? widget.narration! : 'Bank Transfer',
        pin: transactionPin,
        saveBeneficiary: widget.saveAsBeneficiary,
      );

      EasyLoading.dismiss();

      if (response != null && response.responseSuccessful == false) {
        final msg = (response.responseMessage ?? "Transaction failed").toString().toLowerCase();
        if (msg.contains('pin') || msg.contains('incorrect') || msg.contains('invalid')) {
          await SecurityService.registerFailure();
          setState(() {
            pin = "";
            _isProcessing = false;
          });
          _showError('Incorrect PIN', 'Please try again.');
          return;
        }
        setState(() {
          _isProcessing = false;
        });
        _showError('Failed', response.responseMessage ?? "Transaction failed");
        return;
      }

      await SecurityService.clearFailures();
      
      final isSuccess = response?.responseSuccessful == true || response?.responseBody?.status?.toString().toLowerCase() == "success";
      final status = isSuccess ? "success" : (response?.responseBody?.status?.toString().toLowerCase() == "pending" ? "pending" : "failed");
      final reference = response?.responseBody?.txnRef ?? response?.responseBody?.paymentRef ?? '';

      context.pushNamed(RouteList.successScreen, extra: {
        'type': status,
        'amount': widget.amount.toStringAsFixed(2),
        'recipientName': widget.recipientName,
        'recipientAccount': widget.recipientAccount,
        'reference': reference,
        'channel': widget.bankName,
        'message': response?.responseMessage ?? '',
      });
    } catch (e) {
      EasyLoading.dismiss();
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      _showError('Error', e.toString());
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _handleForgotPin() async {
    try {
      LoadingHelper.show();
      await ref.read(dashboardControllerProvider.notifier).forgotPaymentPin(context);
      LoadingHelper.dismiss();
      context.pushNamed(RouteList.forgotPin);
    } catch (e) {
      LoadingHelper.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    final topSpacing = isTablet ? 24.0 : (isSmallScreen ? 20.h : (isLargeScreen ? 60.h : 55.h));
    final sectionSpacing = isTablet ? 20.0 : (isSmallScreen ? 16.h : (isLargeScreen ? 30.h : 30.h));
    final pinSpacing = isTablet ? 24.0 : (isSmallScreen ? 24.h : (isLargeScreen ? 40.h : 30.h));
    final keypadSpacing = isTablet ? 24.0 : (isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 60.h));

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: isTablet ? 18.0 : 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 440 : 600),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 24.w,
                      vertical: isTablet ? 20.0 : (isSmallScreen ? 20.h : 30.h),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: topSpacing),

                        Container(
                          padding: EdgeInsets.all(isTablet ? 14.0 : (isSmallScreen ? 12.h : 15.h)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withValues(alpha: 0.4),
                                primaryColor,
                                primaryColor.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(isTablet ? 14.0 : (isSmallScreen ? 8.r : 10.r)),
                            ),
                          ),
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: isTablet ? 28.0 : (isSmallScreen ? 24.sp : 30.sp),
                          ),
                        ),

                        SizedBox(height: sectionSpacing),

                        Text(
                          'Enter Transaction PIN',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 20.0 : (isSmallScreen ? 16.sp : (isLargeScreen ? 24.sp : 20.sp)),
                          ),
                        ),

                        SizedBox(height: pinSpacing),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final filled = index < pin.length;
                            final dotSize = isTablet ? 14.0 : (isSmallScreen ? 12.w : 14.w);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.symmetric(horizontal: isTablet ? 6.0 : 6.w),
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled ? primaryColor : Colors.transparent,
                                border: Border.all(
                                  color: filled ? primaryColor : Colors.grey,
                                  width: isTablet ? 2.0 : (isSmallScreen ? 1.5 : 2),
                                ),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: keypadSpacing),

                        SizedBox(
                          width: isTablet ? 360.0 : double.infinity,
                          child: CustomGridKeypad(
                            onNumberPressed: addDigit,
                            leftAction: (pin.isEmpty && _hasBiometric && _biometricEnabled)
                                ? ActionKey(
                                    child: Icon(
                                      _biometricIcon,
                                      color: Colors.white,
                                      size: isTablet ? 24.0 : (isSmallScreen ? 24.sp : 28.sp),
                                    ),
                                    backgroundColor: primaryColor,
                                    onTap: _authenticateWithBiometric,
                                  )
                                : ActionKey(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                                    ),
                                    backgroundColor: primaryColor,
                                    onTap: () => _processTransfer(pin),
                                  ),
                            rightAction: ActionKey(
                              child: Icon(
                                Icons.backspace_rounded,
                                color: primaryColor,
                                size: isTablet ? 22.0 : (isSmallScreen ? 20.sp : 24.sp),
                              ),
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              onTap: removeDigit,
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 20.0 : 16.h),

                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => _handleForgotPin(),
                            child: Text(
                              'Forget Pin?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: lightText,
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 13.5 : (isSmallScreen ? 13.sp : 14.sp),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 20.0 : (isSmallScreen ? 10.h : 20.h)),
                      ],
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