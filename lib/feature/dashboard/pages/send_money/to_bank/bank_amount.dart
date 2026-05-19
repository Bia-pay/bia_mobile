import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/view/widget/app_textfield.dart';
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
    this.title = "Enter Amount Bank",
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    final sectionSpacing = isSmallScreen ? 20.h : (isLargeScreen ? 60.h : 55.h);
    final smallSpacing = isSmallScreen ? 6.h : 10.h;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recipient Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14.sp : 16.sp,
                        ),
                      ),
                      SizedBox(height: smallSpacing),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: isSmallScreen ? 8.h : 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: offWhite,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isSmallScreen ? 16.r : 20.r,
                              backgroundColor: secondaryColor,
                              child: widget.recipientIconPath != null
                                  ? SvgPicture.asset(
                                widget.recipientIconPath!,
                                height: isSmallScreen ? 24.h : 30.h,
                                colorFilter: ColorFilter.mode(
                                  primaryColor,
                                  BlendMode.srcIn,
                                ),
                              )
                                  : Icon(
                                Icons.person,
                                size: isSmallScreen ? 24.sp : 30.sp,
                                color: primaryColor,
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
                                      fontWeight: FontWeight.w600,
                                      color: lightText,
                                      fontSize: isSmallScreen ? 13.sp : 14.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.recipientAccount,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: lightSecondaryText,
                                      fontSize: isSmallScreen ? 11.sp : 12.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: SvgPicture.asset(
                                editSvg,
                                height: isSmallScreen ? 14.h : 16.h,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      Text(
                        'Enter Amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14.sp : 16.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      AppTextField(
                        controller: widget.controller,
                        readOnly: true,
                        borderRadius: 8.r,
                        hintTextAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: isSmallScreen ? 20.sp : 24.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: "₦0.00",
                          hintStyle: theme.textTheme.titleLarge?.copyWith(
                            color: lightSecondaryText,
                            fontSize: isSmallScreen ? 20.sp : 24.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12.h : 16.h,
                            horizontal: 12.w,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: showInsufficientFundsWarning
                                  ? errorColor
                                  : primaryColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: showInsufficientFundsWarning
                                  ? errorColor
                                  : primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      if (showMinWarning)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h, left: 4.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: errorColor,
                                size: isSmallScreen ? 14.sp : 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  "Minimum amount you can send is ₦100",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: errorColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: isSmallScreen ? 11.sp : 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (showInsufficientFundsWarning)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h, left: 4.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: errorColor,
                                size: isSmallScreen ? 14.sp : 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  "Insufficient funds. Your balance is ₦${_getWalletBalance().toStringAsFixed(2)}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: errorColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 11.sp : 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: sectionSpacing),

                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: ActionKey(
                            child: SvgPicture.asset(
                              'assets/svg/cancel.svg',
                              height: isSmallScreen ? 18.h : 22.h,
                              colorFilter: ColorFilter.mode(
                                primaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            onTap: removeDigit,
                          ),
                          rightAction: ActionKey(
                            child: Icon(
                              Icons.arrow_forward,
                              color: lightBackground,
                              size: isSmallScreen ? 22.sp : 26.sp,
                            ),
                            backgroundColor: primaryColor,
                            onTap: _showConfirmBottomSheet,
                          ),
                        ),
                      ),
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