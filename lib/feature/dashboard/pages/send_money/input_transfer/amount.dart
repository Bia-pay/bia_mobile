import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
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
      amount = '₦${NumberFormat('#,##0').format(widget.initialAmount)}';
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
      String current = amount.replaceAll('₦', '').replaceAll(',', '');

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      final parsed = double.tryParse(current) ?? 0;
      amount = '₦${NumberFormat('#,##0').format(parsed)}';
      widget.controller.text = amount;

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

      final parsed = double.tryParse(current) ?? 0;
      amount = '₦${NumberFormat('#,##0').format(parsed)}';
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
    return '₦${NumberFormat('#,##0.00').format(balance)}';
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: offWhiteBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenH = constraints.maxHeight;
              final isSmall = screenH < 780;
              final isTiny = screenH < 600;
              final isTablet = MediaQuery.of(context).size.width > 600;

              final topBar = _buildTopBar(context, theme, walletBalance, isTiny);
              final recipientCard = _buildRecipientCard(context, theme, isTiny);
              final amountDisplay = _buildAmountDisplay(walletBalance, isTiny, isSmall);
              final keypad = _buildKeypad(isTiny, isSmall);

              if (isTablet) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          topBar,
                          const SizedBox(height: 12),
                          recipientCard,
                          const SizedBox(height: 16),
                          amountDisplay,
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: CustomTextFormField(
                                controller: _narrationController,
                                label: 'Narration (Optional)',
                                hintText: 'What is this for?',
                                validator: (val) => null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!keyboardOpen) keypad,
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isTiny ? 6.h : (isSmall ? 8.h : 14.h),
                    ),
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
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeData theme, double walletBalance, bool isTiny) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8.0 : 16.w,
        vertical: isTablet ? 10.0 : (isTiny ? 6.h : 12.h),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 10.0 : 10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                border: Border.all(
                  color: lightBorderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: isTablet ? 16.0 : 16.sp,
                color: darkBackground,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 12.0 : 12.w),
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkBackground,
                fontSize: isTablet ? 16.0 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isTablet ? 8.0 : 8.w),
          // Balance pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 10.0 : 12.w,
              vertical: isTablet ? 6.0 : 6.h,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: isTablet ? 14.0 : 14.sp,
                  color: primaryColor,
                ),
                SizedBox(width: isTablet ? 4.0 : 4.w),
                Text(
                  _formatBalance(walletBalance),
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 11.sp,
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.0 : 14.w,
          vertical: isTablet ? 12.0 : (isTiny ? 10.h : 14.h),
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
              width: isTablet ? 42.0 : (isTiny ? 36.r : 42.r),
              height: isTablet ? 42.0 : (isTiny ? 36.r : 42.r),
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
                        height: isTablet ? 22.0 : (isTiny ? 20.h : 24.h),
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
                          fontSize: isTablet ? 16.0 : (isTiny ? 14.sp : 16.sp),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(width: isTablet ? 12.0 : 12.w),
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
                      fontSize: isTablet ? 14.0 : (isTiny ? 13.sp : 14.sp),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.recipientAccount,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: lightSecondaryText,
                      fontSize: isTablet ? 12.0 : (isTiny ? 11.sp : 12.sp),
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
                padding: EdgeInsets.all(isTablet ? 8.0 : 8.w),
                decoration: BoxDecoration(
                  color: lightBorderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: isTablet ? 16.0 : 16.sp,
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Column(
      children: [
        Text(
          amount == "0" ? "₦0" : amount,
          style: TextStyle(
            fontSize: isTablet
                ? 44.0
                : (isTiny
                    ? 36.sp
                    : (isSmall ? 42.sp : 52.sp)),
            fontWeight: FontWeight.w800,
            color: showInsufficientFundsWarning
                ? errorColor
                : darkBackground,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: isTablet ? 6.0 : 6.h),
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
            "Insufficient balance (₦${NumberFormat('#,##0.00').format(walletBalance)})",
            Icons.error_outline_rounded,
            errorColor,
            isTiny,
          ),
        if (!showMinWarning && !showInsufficientFundsWarning)
          Text(
            "Enter amount to send",
            style: TextStyle(
              fontSize: isTablet ? 13.0 : (isTiny ? 11.sp : 13.sp),
              color: lightSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0, duration: 500.ms);
  }

  Widget _buildKeypad(bool isTiny, bool isSmall) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: isTablet ? 360.0 : 400.w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 20.w),
          child: CustomGridKeypad(
            onNumberPressed: addDigit,
            leftAction: ActionKey(
              child: Icon(
                Icons.arrow_forward_rounded,
                color: lightBackground,
                size: isTablet ? 22.0 : (isSmall ? 20.sp : 24.sp),
              ),
              backgroundColor: primaryColor,
              onTap: _showConfirmBottomSheet,
            ),
            rightAction: ActionKey(
              child: Icon(
                Icons.backspace_rounded,
                color: primaryColor,
                size: isTablet ? 22.0 : (isSmall ? 20.sp : 24.sp),
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      margin: EdgeInsets.only(top: isTablet ? 6.0 : 4.h),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14.0 : 12.w,
        vertical: isTablet ? 6.0 : 6.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isTablet ? 14.0 : (isTiny ? 12.sp : 14.sp)),
          SizedBox(width: isTablet ? 6.0 : 6.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: isTablet ? 12.0 : (isTiny ? 10.sp : 12.sp),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}