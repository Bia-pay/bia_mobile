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
      debugPrint('❌ Biometric init error: $e');
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
    if (pin.length >= 4 || _isProcessing) return;
    setState(() {
      pin += value;
    });

    if (pin.length == 4) {
      _processTransaction(pin);
    }
  }

  void removeDigit() {
    if (pin.isEmpty || _isProcessing) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _processTransaction(String transactionPin) async {
    if (transactionPin.length < 4 || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    final controller = ref.read(dashboardControllerProvider.notifier);
    EasyLoading.show(status: "Processing...");

    try {
      dynamic response;
      if (widget.type == "airtime") {
        response = await controller.buyAirtime(
          context, 
          phone: widget.recipientAccount, 
          amount: widget.amount.toInt(), 
          network: widget.meta?['network']?.toString().toLowerCase() ?? '', 
          pin: transactionPin,
          saveBeneficiary: widget.saveAsBeneficiary || (widget.meta?['saveBeneficiary'] ?? false),
          beneficiaryName: widget.meta?['beneficiaryName'],
        );
      } else if (widget.type == "data") {
        response = await controller.buyData(
          context, 
          phone: widget.recipientAccount, 
          serviceId: widget.meta?['serviceId'], 
          variationCode: widget.meta?['variationCode'], 
          amount: widget.amount.toInt(), 
          pin: transactionPin,
          saveBeneficiary: widget.saveAsBeneficiary || (widget.meta?['saveBeneficiary'] ?? false),
          beneficiaryName: widget.meta?['beneficiaryName'],
        );
      } else if (widget.type == "cable") {
        response = await controller.buyCable(
          context, 
          serviceId: widget.meta?['serviceId'], 
          smartcard: widget.recipientAccount, 
          packageName: widget.meta?['packageName'] ?? widget.meta?['variationCode'], 
          variationCode: widget.meta?['variationCode'], 
          amount: widget.amount.toInt(), 
          phone: widget.recipientAccount, 
          pin: transactionPin,
          saveBeneficiary: widget.saveAsBeneficiary || (widget.meta?['saveBeneficiary'] ?? false),
          beneficiaryName: widget.meta?['beneficiaryName'],
        );
      } else if (widget.type == "electricity") {
        response = await controller.buyElectricity(
          context, 
          serviceId: widget.meta?['serviceId'], 
          meterNumber: widget.recipientAccount, 
          variationCode: widget.meta?['variationCode'], 
          amount: widget.amount.toInt(), 
          phone: widget.meta?['userPhone'] ?? widget.recipientAccount, 
          pin: transactionPin,
          saveBeneficiary: widget.saveAsBeneficiary || (widget.meta?['saveBeneficiary'] ?? false),
          beneficiaryName: widget.meta?['beneficiaryName'],
        );
      } else {
        response = await controller.sendMoney(
          context,
          widget.recipientAccount,
          widget.amount.toStringAsFixed(2),
          (widget.narration == null || widget.narration!.trim().isEmpty)
              ? 'Transfer'
              : widget.narration!,
          transactionPin,
          save: widget.saveAsBeneficiary,
        );
      }

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
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final topSpacing = isTablet ? 30.0 : 40.h;
    final sectionSpacing = isTablet ? 16.0 : 20.h;
    final pinSpacing = isTablet ? 16.0 : 24.h;
    final keypadSpacing = isTablet ? 20.0 : 30.h;

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
            constraints: BoxConstraints(maxWidth: isTablet ? 330 : double.infinity),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 0 : 24.w,
                  vertical: isTablet ? 10.0 : 20.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topSpacing),

                    Container(
                      padding: EdgeInsets.all(isTablet ? 12.0 : 14.h),
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
                        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: isTablet ? 24.0 : 28.sp,
                      ),
                    ),

                    SizedBox(height: sectionSpacing),

                    Text(
                      'Enter Transaction PIN',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 18.0 : 20.sp,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    SizedBox(height: pinSpacing),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < pin.length;
                        final dotSize = isTablet ? 12.0 : 14.w;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.symmetric(horizontal: isTablet ? 5.0 : 6.w),
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: filled ? primaryColor : Colors.grey.shade400,
                              width: isTablet ? 1.5 : 2,
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: keypadSpacing),

                    CustomGridKeypad(
                      onNumberPressed: addDigit,
                      leftAction: (pin.isEmpty && _hasBiometric && _biometricEnabled)
                          ? ActionKey(
                              child: Icon(
                                _biometricIcon,
                                color: Colors.white,
                                size: isTablet ? 22.0 : 24.sp,
                              ),
                              backgroundColor: primaryColor,
                              onTap: _authenticateWithBiometric,
                            )
                          : ActionKey(
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: isTablet ? 20.0 : 22.sp,
                              ),
                              backgroundColor: primaryColor,
                              onTap: () => _processTransaction(pin),
                            ),
                      rightAction: ActionKey(
                        child: Icon(
                          Icons.backspace_rounded,
                          color: primaryColor,
                          size: isTablet ? 20.0 : 22.sp,
                        ),
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        onTap: removeDigit,
                      ),
                    ),

                    SizedBox(height: isTablet ? 14.0 : 16.h),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _handleForgotPin(),
                        child: Text(
                          'Forget Pin?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 12.0 : 13.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 10.0 : 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
