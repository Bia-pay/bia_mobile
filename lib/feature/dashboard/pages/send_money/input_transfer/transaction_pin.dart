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

class TransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;
  final String type; // airtime | data | transfer | cable | electricity
  final Map<String, dynamic>? meta;
  final String? narration;

  const TransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
    required this.type,
    this.meta,
    this.narration,
  });

  @override
  ConsumerState<TransactionPin> createState() => _TransactionPinState();
}

class _TransactionPinState extends ConsumerState<TransactionPin> {
  String pin = "";
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;

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

      if (mounted) {
        setState(() {
          _hasBiometric = isAvailable;
          _biometricEnabled = isEnabled && savedPin != null;
        });
      }

      if (isAvailable && isEnabled && savedPin != null) {
        Future.delayed(const Duration(milliseconds: 500), _authenticateWithBiometric);
      }
    } catch (e) {
      debugPrint('❌ Biometric init error: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating || !_hasBiometric || !_biometricEnabled) return;
    setState(() => _isAuthenticating = true);
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      final biometricService = BiometricService();
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to complete transaction',
        biometricOnly: true,
      );

      if (!authenticated) return;

      final savedPin = await biometricService.getTransactionPin(effectiveUserId);
      if (savedPin != null && savedPin.isNotEmpty) {
        await _processTransaction(savedPin);
      }
    } catch (e) {
      debugPrint('⚠️ Biometric error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void addDigit(String value) {
    if (pin.length >= 4) return;
    setState(() {
      pin += value;
    });

    if (pin.length == 4) {
      _processTransaction(pin);
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _processTransaction(String transactionPin) async {
    if (transactionPin.length < 4) return;
    
    final controller = ref.read(dashboardControllerProvider.notifier);
    EasyLoading.show(status: "Processing...");

    try {
      dynamic response;
      if (widget.type == "airtime") {
        response = await controller.buyAirtime(context, phone: widget.recipientAccount, amount: widget.amount.toInt(), network: widget.meta?['network']?.toString().toLowerCase() ?? '', pin: transactionPin);
      } else if (widget.type == "data") {
        response = await controller.buyData(context, phone: widget.recipientAccount, serviceId: widget.meta?['serviceId'], variationCode: widget.meta?['variationCode'], amount: widget.amount.toInt(), pin: transactionPin);
      } else if (widget.type == "cable") {
        response = await controller.buyCable(context, serviceId: widget.meta?['serviceId'], smartcard: widget.recipientAccount, packageName: widget.meta?['packageName'] ?? widget.meta?['variationCode'], variationCode: widget.meta?['variationCode'], amount: widget.amount.toInt(), phone: widget.recipientAccount, pin: transactionPin);
      } else if (widget.type == "electricity") {
        response = await controller.buyElectricity(
          context, 
          serviceId: widget.meta?['serviceId'], 
          meterNumber: widget.recipientAccount, 
          variationCode: widget.meta?['variationCode'], 
          amount: widget.amount.toInt(), 
          phone: widget.meta?['userPhone'] ?? widget.recipientAccount, 
          pin: transactionPin
        );
      } else {
        response = await controller.sendMoney(context, widget.recipientAccount, widget.amount.toStringAsFixed(2), widget.narration ?? 'Transfer', transactionPin, save: widget.saveAsBeneficiary);
      }

      EasyLoading.dismiss();

      if (response != null && response.responseSuccessful == false) {
        final msg = (response.responseMessage ?? "Transaction failed").toString().toLowerCase();
        if (msg.contains('pin') || msg.contains('incorrect') || msg.contains('invalid')) {
          await SecurityService.registerFailure();
          setState(() => pin = "");
          _showError('Incorrect PIN', 'Please try again.');
          return;
        }
        _showError('Failed', response.responseMessage ?? "Transaction failed");
        return;
      }

      await SecurityService.clearFailures();
      
      final isSuccess = response?.responseSuccessful == true || response?.responseBody?.status?.toString().toLowerCase() == "success";
      final status = isSuccess ? "success" : (response?.responseBody?.status?.toString().toLowerCase() == "pending" ? "pending" : "failed");

      context.goNamed(RouteList.successScreen, extra: {
        "type": status,
        "amount": widget.amount.toStringAsFixed(2),
        "recipientName": widget.recipientName,
        "recipientAccount": widget.recipientAccount,
        "reference": response?.responseBody?.reference ?? '',
        "channel": widget.type.toUpperCase(),
        "message": response?.responseMessage ?? '',
      });
    } catch (e) {
      EasyLoading.dismiss();
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
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    final topSpacing = isSmallScreen ? 20.h : (isLargeScreen ? 60.h : 55.h);
    final sectionSpacing = isSmallScreen ? 16.h : (isLargeScreen ? 30.h : 30.h);
    final pinSpacing = isSmallScreen ? 24.h : (isLargeScreen ? 40.h : 30.h);
    final keypadSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 60.h);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
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

                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12.h : 15.h,
                          horizontal: isSmallScreen ? 12.w : 15.w,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.4),
                              primaryColor,
                              primaryColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(isSmallScreen ? 8.r : 10.r),
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
                        'Enter Transaction PIN',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 16.sp : (isLargeScreen ? 24.sp : 20.sp),
                        ),
                      ),

                      SizedBox(height: pinSpacing),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < pin.length;
                          final dotSize = isSmallScreen ? 12.w : 14.w;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: filled ? primaryColor : Colors.grey,
                                width: isSmallScreen ? 1.5 : 2,
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: keypadSpacing),

                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: (pin.isEmpty && _hasBiometric && _biometricEnabled)
                              ? ActionKey(
                                  child: Icon(
                                    Icons.fingerprint,
                                    color: Colors.white,
                                    size: isSmallScreen ? 24.sp : 28.sp,
                                  ),
                                  backgroundColor: primaryColor,
                                  onTap: _authenticateWithBiometric,
                                )
                              : ActionKey(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 20.sp : 24.sp,
                                  ),
                                  backgroundColor: primaryColor,
                                  onTap: () => _processTransaction(pin),
                                ),
                          rightAction: ActionKey(
                            child: Icon(
                              Icons.backspace_rounded,
                              color: primaryColor,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            onTap: removeDigit,
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _handleForgotPin(),
                          child: Text(
                            'Forget Pin?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: lightText,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 13.sp : 14.sp,
                            ),
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
