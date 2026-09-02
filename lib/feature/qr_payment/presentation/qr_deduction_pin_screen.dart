import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../dashboard/widgets/keypad.dart';
import '../controller/qr_payment_controller.dart';
import 'dart:async';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../../core/services/security_service.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';

class QrDeductionPinScreen extends ConsumerStatefulWidget {
  final String ownerAccount;
  final double amount;
  final String narration;

  const QrDeductionPinScreen({
    super.key,
    required this.ownerAccount,
    required this.amount,
    required this.narration,
  });

  @override
  ConsumerState<QrDeductionPinScreen> createState() => _QrDeductionPinScreenState();
}

class _QrDeductionPinScreenState extends ConsumerState<QrDeductionPinScreen> with WidgetsBindingObserver {
  String pin = "";
  Timer? _inactivityTimer;
  double _chargeAmount = 0.0;
  double _totalAmount = 0.0;
  bool _isLoadingCharges = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
    _fetchCharges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Auto clear transaction session if app minimized/backgrounded during PIN entry
      setState(() => pin = "");
      context.pop(); // Pop back to scanner for security
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() => pin = "");
        _showError('Session Expired', 'Transaction timed out due to inactivity.');
        context.pop(); // Pop back for security
      }
    });
  }

  Future<void> _fetchCharges() async {
    setState(() {
      _isLoadingCharges = true;
    });

    try {
      final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
      final charges = await dashboardCtrl.getTransactionCharges(
        context,
        amount: widget.amount,
        transactionType: "DEBIT",
        serviceType: "TRANSFER",
      );

      if (mounted) {
        setState(() {
          if (charges != null) {
            _chargeAmount = (charges['charge'] ?? 0).toDouble();
            _totalAmount = (charges['totalAmount'] ?? widget.amount).toDouble();
          } else {
            _chargeAmount = 0.0;
            _totalAmount = widget.amount;
          }
          _isLoadingCharges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chargeAmount = 0.0;
          _totalAmount = widget.amount;
          _isLoadingCharges = false;
        });
      }
    }
  }

  void addDigit(String value) {
    _resetInactivityTimer();
    if (pin.length >= 4) return;
    setState(() {
      pin += value;
    });

    if (pin.length == 4) {
      _processPayment(pin);
    }
  }

  void removeDigit() {
    _resetInactivityTimer();
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _processPayment(String enteredPin) async {
    if (enteredPin.length < 4) return;
    
    final controller = ref.read(qrPaymentControllerProvider.notifier);
    EasyLoading.show(status: "Processing Deduction...");

    try {
      final response = await controller.deductQrPayment(
        context: context,
        ownerAccount: widget.ownerAccount,
        amount: widget.amount,
        narration: widget.narration,
        pin: enteredPin,
      );

      EasyLoading.dismiss();

      // Clear the PIN immediately for security on merchant device
      setState(() => pin = "");

      if (response == null || !response.responseSuccessful) {
        final msg = (response?.responseMessage ?? "Transaction failed").toLowerCase();
        if (msg.contains('pin') || msg.contains('incorrect') || msg.contains('invalid')) {
          await SecurityService.registerFailure();
          _showError('Incorrect PIN', 'Please try again.');
          return;
        }
        _showError('Failed', response?.responseMessage ?? "Transaction failed");
        return;
      }

      await SecurityService.clearFailures();
      
      final isSuccess = response.responseSuccessful;
      final status = isSuccess ? "success" : "failed";
      final refId = response.responseBody?.debitReference ?? response.responseBody?.reference ?? '';

      if (mounted) {
        context.goNamed(RouteList.successScreen, extra: {
          "type": status,
          "amount": NumberFormat('#,##0.00').format(_totalAmount > 0 ? _totalAmount : widget.amount),
          "recipientName": widget.ownerAccount,
          "recipientAccount": "QR Deduction",
          "reference": refId ?? '',
          "channel": "QR",
          "message": response.responseMessage ?? '',
        });
      }
    } catch (e) {
      EasyLoading.dismiss();
      setState(() => pin = "");
      _showError('Error', e.toString());
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
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

                      // Locked icon with gradient container
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
                      SizedBox(height: 6.h),
                      Text(
                        'Authorize collection request of ₦${NumberFormat('#,##0.00').format(widget.amount)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: lightSecondaryText,
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 12.sp : 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: pinSpacing),

                      // PIN Dots
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

                      // Numeric Custom Keypad
                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: ActionKey(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor,
                            onTap: () => _processPayment(pin),
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
