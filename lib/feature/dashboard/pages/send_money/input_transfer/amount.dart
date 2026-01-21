import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/view/widget/app_textfield.dart';
import '../../../widgets/keypad.dart';
import 'complete_transaction.dart';

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
  });

  @override
  ConsumerState<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends ConsumerState<AmountPage> {
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

  void _showConfirmBottomSheet() {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompleteTransactionBottomSheet(
        amount: numericAmount.toString(),
        recipientName: widget.recipientName,
        recipientAccount: widget.recipientAccount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipient Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: offWhite,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: secondaryColor,
                    child: widget.recipientIconPath != null
                        ? SvgPicture.asset(
                      widget.recipientIconPath!,
                      height: 30.h,
                      colorFilter: ColorFilter.mode(
                        primaryColor,
                        BlendMode.srcIn,
                      ),
                    )
                        : Icon(
                      Icons.person,
                      size: 30.sp,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipientName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: lightText,
                          ),
                        ),
                        Text(
                          widget.recipientAccount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(editSvg, height: 15.h),
                  ),
                ],
              ),
            ),

            SizedBox(height: 45.h),

            Text(
              'Enter Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5.h),

            AppTextField(
              controller: widget.controller,
              readOnly: true,
              borderRadius: 8.r,
              hintTextAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "₦0.00",
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: lightSecondaryText,
                  fontSize: 23.sp,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color:
                    showInsufficientFundsWarning ? errorColor : primaryColor,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color:
                    showInsufficientFundsWarning ? errorColor : primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            if (showMinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: errorColor, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Minimum amount you can send is ₦50",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            if (showInsufficientFundsWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: errorColor, size: 16.sp),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        "Insufficient funds. Your balance is ₦${_getWalletBalance().toStringAsFixed(2)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 50.h),

            /// 🔢 Keypad (NO BIOMETRIC HERE)
            Expanded(
              child: CustomGridKeypad(
                onNumberPressed: addDigit,

                leftAction: ActionKey(
                  child: SvgPicture.asset(
                    'assets/svg/cancel.svg',
                    height: 20.h,
                    colorFilter: ColorFilter.mode(
                      primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),

                rightAction: ActionKey(
                  child: const Icon(Icons.arrow_forward,
                      color: lightBackground),
                  backgroundColor: primaryColor,
                  onTap: _showConfirmBottomSheet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}