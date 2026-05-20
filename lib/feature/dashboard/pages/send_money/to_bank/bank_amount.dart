import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../../../app/utils/image.dart';
import '../../../widgets/keypad.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'on_bank_complete_payment.dart';

class BankAmountPage extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String recipientName;
  final String recipientAccount;
  final String? recipientIconPath;
  final String title;
  final String bankCode;
  final String bankName;

  const BankAmountPage({
    super.key,
    required this.controller,
    required this.recipientName,
    required this.recipientAccount,
    required this.bankCode,
    this.recipientIconPath,
    required this.bankName,
    this.title = "Enter Amount",
  });

  @override
  ConsumerState<BankAmountPage> createState() => _BankAmountPageState();
}

class _BankAmountPageState extends ConsumerState<BankAmountPage> {
  String amount = "0";
  bool showMinWarning = false;
  bool showInsufficientFundsWarning = false;

  void addDigit(String value) {
    setState(() {
      String current = amount.replaceAll('₦', '');

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      amount = '₦$current';
      widget.controller.text = amount;

      _checkAmountValidation();
    });
  }

  void removeDigit() {
    setState(() {
      String current = amount.replaceAll('₦', '');
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
      }
      if (current.isEmpty) {
        current = "0";
      }

      amount = '₦$current';
      widget.controller.text = amount;

      _checkAmountValidation();
    });
  }

  void _checkAmountValidation() {
    final numericValue =
        num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    showMinWarning = numericValue < 100 && numericValue != 0;

    final walletBalance = _getWalletBalance();
    showInsufficientFundsWarning =
        numericValue > walletBalance && numericValue != 0;
  }

  double _getWalletBalance() {
    final box = Hive.box('authBox');
    final balanceStr = box.get('balance', defaultValue: '0').toString();
    return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '₦${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '₦${(balance / 1000).toStringAsFixed(1)}K';
    }
    return '₦${balance.toStringAsFixed(2)}';
  }

  Future<void> _showConfirmBottomSheet() async {
    final numericAmount =
        num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    if (numericAmount < 100) {
      setState(() => showMinWarning = true);
      return;
    }

    final walletBalance = _getWalletBalance();
    if (numericAmount > walletBalance) {
      setState(() => showInsufficientFundsWarning = true);
      return;
    }

    EasyLoading.show(status: "Calculating charges...");

    try {
      final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
      final charges = await dashboardCtrl.getTransactionCharges(
        context,
        amount: numericAmount.toDouble(),
        transactionType: "DEBIT",
        serviceType: "TRANSFER",
      );

      EasyLoading.dismiss();

      double chargeAmount = 0.0;
      double totalAmount = numericAmount.toDouble();
      String feeDescription = "Transfer Fee";

      if (charges != null) {
        chargeAmount = (charges['charge'] ?? 0).toDouble();
        totalAmount = (charges['totalAmount'] ?? numericAmount).toDouble();
        feeDescription = charges['description'] ?? 'Transfer Fee';
      } else {
        chargeAmount = 10.0;
        totalAmount = numericAmount.toDouble() + chargeAmount;
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BankCompleteTransactionBottomSheet(
          amount: numericAmount.toString(),
          recipientName: widget.recipientName,
          recipientAccount: widget.recipientAccount,
          bankCode: widget.bankCode,
          bankName: widget.bankName,
          preCalculatedCharge: chargeAmount,
          preCalculatedTotal: totalAmount,
          preCalculatedFeeDescription: feeDescription,
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError("Failed to calculate charges");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletBalance = _getWalletBalance();

    return Scaffold(
      backgroundColor: offWhiteBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenH = constraints.maxHeight;
            final isSmall = screenH < 700;
            final isTiny = screenH < 600;

            return Column(
              children: [
                /// 🔹 Top Bar
                Padding(
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
                        widget.title,
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
                ),

                /// 🔹 Recipient Card
                Padding(
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
                              widget.recipientName.isNotEmpty
                                  ? widget.recipientName[0].toUpperCase()
                                  : 'B',
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
                                widget.recipientName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: darkBackground,
                                  fontSize: isTiny ? 13.sp : 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_rounded,
                                    size: 11.sp,
                                    color: lightSecondaryText,
                                  ),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      '${widget.bankName} • ${widget.recipientAccount}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: lightSecondaryText,
                                        fontSize: isTiny ? 10.sp : 11.sp,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                  ),
                ),

                SizedBox(height: isTiny ? 16.h : 28.h),

                /// 🔹 Amount Display
                Column(
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
                        "Minimum amount is ₦100",
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
                        "Enter amount to transfer",
                        style: TextStyle(
                          fontSize: isTiny ? 11.sp : 13.sp,
                          color: lightSecondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                /// 🔹 Keypad
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: SizedBox(
                    height: isTiny ? 220.h : (isSmall ? 260.h : 320.h),
                    child: CustomGridKeypad(
                      onNumberPressed: addDigit,
                      leftAction: ActionKey(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: lightBackground,
                          size: isSmall ? 20.sp : 24.sp,
                        ),
                        backgroundColor: primaryColor,
                        onTap: _showConfirmBottomSheet,
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

                SizedBox(height: isTiny ? 8.h : 16.h),
              ],
            );
          },
        ),
      ),
    );
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