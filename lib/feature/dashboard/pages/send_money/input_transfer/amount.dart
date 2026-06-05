import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../widgets/keypad.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'complete_transaction.dart';
import '../../../../../app/utils/widgets/custom_text_field.dart';

class AmountPage extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String recipientName;
  final String recipientAccount;
  final String? recipientIconPath;
  final String title;

  const AmountPage({
    super.key,
    required this.controller,
    required this.recipientName,
    required this.recipientAccount,
    this.recipientIconPath,
    this.title = "Enter Amount",
    this.initialAmount,
    this.initialNarration,
  });

  final double? initialAmount;
  final String? initialNarration;

  @override
  ConsumerState<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends ConsumerState<AmountPage> {
  String amount = "0";
  bool showMinWarning = false;
  bool showInsufficientFundsWarning = false;
  final _narrationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      amount = '₦${widget.initialAmount!.toStringAsFixed(0)}';
      widget.controller.text = amount;
      _checkAmountValidation();
    }
    if (widget.initialNarration != null) {
      _narrationController.text = widget.initialNarration!;
    }
  }

  @override
  void dispose() {
    _narrationController.dispose();
    super.dispose();
  }

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

    // Minimum ₦50
    showMinWarning = numericValue < 50 && numericValue != 0;

    // Wallet balance check
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

    if (numericAmount < 50) {
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
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BiaToBiaCompleteTransactionBottomSheet(
          amount: numericAmount.toString(),
          recipientName: widget.recipientName,
          recipientAccount: widget.recipientAccount,
          recipientIconPath: widget.recipientIconPath,
          narration: _narrationController.text,
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
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenH = constraints.maxHeight;
            final isSmall = screenH < 780;
            final isTiny = screenH < 600;
            final isTablet = constraints.maxWidth >= 768;

            final topBar = _buildTopBar(context, theme, walletBalance, isTiny);
            final recipientCard = _buildRecipientCard(context, theme, isTiny);
            final amountDisplay = _buildAmountDisplay(walletBalance, isTiny, isSmall);
            final keypad = _buildKeypad(isTiny, isSmall);

            if (isTablet) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      topBar,
                      SizedBox(height: 24.h),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 10,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  recipientCard,
                                  SizedBox(height: 32.h),
                                  amountDisplay,
                                  SizedBox(height: 24.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                                    child: CustomTextFormField(
                                      controller: _narrationController,
                                      label: 'Narration (Optional)',
                                      hintText: 'What is this for?',
                                      validator: (val) => null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 48.w),
                            Expanded(
                              flex: 9,
                              child: keypad,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isTiny ? 6.h : (isSmall ? 8.h : 14.h)),
                  child: Column(
                    children: [
                      topBar,
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              recipientCard,
                              SizedBox(height: isTiny ? 6.h : (isSmall ? 12.h : 18.h)),
                              amountDisplay,
                              SizedBox(height: isTiny ? 6.h : (isSmall ? 12.h : 18.h)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: CustomTextFormField(
                                  controller: _narrationController,
                                  label: 'Narration (Optional)',
                                  hintText: 'What is this for?',
                                  validator: (val) => null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                child: widget.recipientIconPath != null
                    ? SvgPicture.asset(
                        widget.recipientIconPath!,
                        height: isTiny ? 20.h : 24.h,
                        colorFilter: ColorFilter.mode(
                          primaryColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Text(
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
                  Text(
                    widget.recipientAccount,
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
            "Enter amount to send",
            style: TextStyle(
              fontSize: isTiny ? 11.sp : 13.sp,
              color: lightSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0, duration: 500.ms);
  }

  Widget _buildKeypad(bool isTiny, bool isSmall) {
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