import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../dashboard/widgets/keypad.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../controller/qr_payment_controller.dart';
import 'qr_complete_transaction.dart';

class QrAmountEntryScreen extends ConsumerStatefulWidget {
  final String receiverAccount;
  final bool isCollectMode;

  const QrAmountEntryScreen({
    super.key,
    required this.receiverAccount,
    this.isCollectMode = false,
  });

  @override
  ConsumerState<QrAmountEntryScreen> createState() => _QrAmountEntryScreenState();
}

class _QrAmountEntryScreenState extends ConsumerState<QrAmountEntryScreen> {
  final _narrationController = TextEditingController();
  
  String amount = "0";
  bool showMinWarning = false;
  bool showInsufficientFundsWarning = false;
  
  String _customerName = "Loading...";
  bool _isResolving = true;

  @override
  void initState() {
    super.initState();
    _checkAmountValidation();
    _resolveCustomerName();
  }

  @override
  void dispose() {
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> _resolveCustomerName() async {
    setState(() => _isResolving = true);
    try {
      final controller = ref.read(dashboardControllerProvider.notifier);
      final response = await controller.verifyAccount(context, widget.receiverAccount);
      if (response != null && response.responseSuccessful) {
        setState(() {
          _customerName = response.responseBody?.user?.fullname ?? "Customer";
          _isResolving = false;
        });
      } else {
        setState(() {
          _customerName = "Customer";
          _isResolving = false;
        });
      }
    } catch (_) {
      setState(() {
        _customerName = "Customer";
        _isResolving = false;
      });
    }
  }

  void addDigit(String value) {
    setState(() {
      String current = amount.replaceAll('₦', '').replaceAll(',', '');

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      amount = '₦$current';
      _checkAmountValidation();
    });
  }

  void removeDigit() {
    setState(() {
      String current = amount.replaceAll('₦', '').replaceAll(',', '');
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
      }
      if (current.isEmpty) {
        current = "0";
      }

      amount = '₦$current';
      _checkAmountValidation();
    });
  }

  void _checkAmountValidation() {
    final numericValue = double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    setState(() {
      showMinWarning = numericValue < 50 && numericValue != 0;
      if (!widget.isCollectMode) {
        final walletBalance = _getWalletBalance();
        showInsufficientFundsWarning = numericValue > walletBalance && numericValue != 0;
      } else {
        showInsufficientFundsWarning = false;
      }
    });
  }

  double _getWalletBalance() {
    try {
      final box = Hive.box('authBox');
      final balanceStr = box.get('balance', defaultValue: '0').toString();
      return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '₦${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '₦${(balance / 1000).toStringAsFixed(1)}K';
    }
    return '₦${balance.toStringAsFixed(2)}';
  }

  void _onContinue() async {
    final numericValue = double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (numericValue <= 0 || numericValue < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount of at least ₦50')),
      );
      return;
    }

    if (!widget.isCollectMode) {
      final walletBalance = _getWalletBalance();
      if (numericValue > walletBalance) {
        setState(() => showInsufficientFundsWarning = true);
        return;
      }
    }

    if (widget.isCollectMode) {
      EasyLoading.show(status: 'Calculating charges...');

      double chargeAmount = 0.0;
      double totalAmount = numericValue;
      String feeDescription = "Transaction Fee";

      try {
        final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
        final charges = await dashboardCtrl.getTransactionCharges(
          context,
          amount: numericValue,
          transactionType: "DEBIT",
          serviceType: "TRANSFER",
        );

        if (charges != null) {
          chargeAmount = (charges['charge'] ?? 0).toDouble();
          totalAmount = (charges['totalAmount'] ?? numericValue).toDouble();
          feeDescription = charges['description'] ?? 'Transaction Fee';
        }
      } catch (_) {}

      EasyLoading.dismiss();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QrCompleteTransactionBottomSheet(
            amount: numericValue,
            payerName: _customerName,
            payerAccount: widget.receiverAccount,
            chargeAmount: chargeAmount,
            totalAmount: totalAmount,
            feeDescription: feeDescription,
            narration: _narrationController.text,
          ),
        );
      }
      return;
    }

    EasyLoading.show(status: 'Initiating Payment...');

    final controller = ref.read(qrPaymentControllerProvider.notifier);
    final response = await controller.initiateQrPayment(
      context: context,
      receiverAccount: widget.receiverAccount,
      amount: numericValue,
      narration: _narrationController.text,
    );

    EasyLoading.dismiss();

    if (response != null && response.responseSuccessful) {
      final responseBody = response.responseBody;
      if (responseBody != null) {
        final requestId = responseBody.requestId ?? '';
        final receiverName = responseBody.receiverName ?? widget.receiverAccount;
        
        if (mounted) {
          context.pushNamed(RouteList.qrPaymentReviewScreen, extra: {
            'requestId': requestId,
            'receiverName': receiverName,
            'amount': numericValue,
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletBalance = _getWalletBalance();
    final isLoading = ref.watch(qrPaymentControllerProvider) is AsyncLoading;

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenH = constraints.maxHeight;
            final isSmall = screenH < 700;
            final isTiny = screenH < 600;

            final topBar = _buildTopBar(context, theme, walletBalance, isTiny);
            final recipientCard = _buildRecipientCard(context, theme, isTiny);
            final amountDisplay = _buildAmountDisplay(walletBalance, isTiny, isSmall);
            final keypad = _buildKeypad(isTiny, isSmall, isLoading);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isTiny ? 8.h : 16.h),
                  child: Column(
                    children: [
                      topBar,
                      recipientCard,
                      SizedBox(height: isTiny ? 12.h : 20.h),
                      amountDisplay,
                      SizedBox(height: isTiny ? 12.h : 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: CustomTextFormField(
                          controller: _narrationController,
                          label: 'Narration (Optional)',
                          hintText: 'What is this for?',
                          validator: (val) => null,
                        ),
                      ),
                      const Spacer(),
                      if (!keyboardOpen) ...[
                        keypad,
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: TextButton.icon(
                              onPressed: () => FocusScope.of(context).unfocus(),
                              icon: const Icon(Icons.keyboard_hide_rounded, size: 18),
                              label: const Text('Done'),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                backgroundColor: primaryColor.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTopBar(BuildContext context, ThemeData theme, double walletBalance, bool isTiny) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: isTiny ? 6.h : 12.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: lightBorderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16.sp,
                color: darkBackground,
              ),
            ),
          ),
          const Spacer(),
          Text(
            widget.isCollectMode ? 'Collect via QR' : 'Pay via QR',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: darkBackground,
            ),
          ),
          const Spacer(),
          // Balance pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14.sp,
                  color: primaryColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  _formatBalance(walletBalance),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientCard(BuildContext context, ThemeData theme, bool isTiny) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: isTiny ? 10.h : 14.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: lightBorderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isTiny ? 36.r : 42.r,
              height: isTiny ? 36.r : 42.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _customerName.isNotEmpty
                      ? _customerName[0].toUpperCase()
                      : 'C',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: isTiny ? 14.sp : 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isResolving ? 'Loading...' : _customerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: darkBackground,
                      fontSize: isTiny ? 13.sp : 14.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.receiverAccount,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: lightSecondaryText,
                      fontSize: isTiny ? 11.sp : 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: lightBorderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 16.sp,
                  color: lightSecondaryText,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildAmountDisplay(double walletBalance, bool isTiny, bool isSmall) {
    return Column(
      children: [
        Text(
          amount == "0" ? "₦0" : amount,
          style: TextStyle(
            fontSize: isTiny
                ? 36.sp
                : (isSmall ? 42.sp : 52.sp),
            fontWeight: FontWeight.w800,
            color: showInsufficientFundsWarning
                ? errorColor
                : darkBackground,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 6.h),
        // Warnings
        if (showMinWarning)
          _buildWarningChip(
            "Minimum amount is ₦50",
            Icons.warning_amber_rounded,
            errorColor,
            isTiny,
          ),
        if (showInsufficientFundsWarning)
          _buildWarningChip(
            "Insufficient balance (₦${walletBalance.toStringAsFixed(2)})",
            Icons.error_outline_rounded,
            errorColor,
            isTiny,
          ),
        if (!showMinWarning && !showInsufficientFundsWarning)
          Text(
            widget.isCollectMode ? "Enter amount to collect" : "Enter amount to pay",
            style: TextStyle(
              fontSize: isTiny ? 11.sp : 13.sp,
              color: lightSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0, duration: 500.ms);
  }

  Widget _buildKeypad(bool isTiny, bool isSmall, bool isLoading) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 400.w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: CustomGridKeypad(
            onNumberPressed: addDigit,
            leftAction: ActionKey(
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.arrow_forward_rounded,
                      color: lightBackground,
                      size: isSmall ? 20.sp : 24.sp,
                    ),
              backgroundColor: primaryColor,
              onTap: isLoading ? () {} : _onContinue,
            ),
            rightAction: ActionKey(
              child: Icon(
                Icons.backspace_rounded,
                color: primaryColor,
                size: isSmall ? 20.sp : 24.sp,
              ),
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              onTap: removeDigit,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.08, end: 0, duration: 500.ms);
  }

  Widget _buildWarningChip(
    String text,
    IconData icon,
    Color color,
    bool isTiny,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isTiny ? 12.sp : 14.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: isTiny ? 10.sp : 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
