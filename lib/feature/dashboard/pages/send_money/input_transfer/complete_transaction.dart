import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/pages/send_money/input_transfer/transaction_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';

class CompleteTransactionBottomSheet extends ConsumerStatefulWidget {
  final String amount;
  final String recipientName;
  final String recipientAccount;

  const CompleteTransactionBottomSheet({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientAccount,
  });

  @override
  ConsumerState<CompleteTransactionBottomSheet> createState() =>
      _CompleteTransactionBottomSheetState();
}

class _CompleteTransactionBottomSheetState
    extends ConsumerState<CompleteTransactionBottomSheet> {
  final TextEditingController pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  bool _saveAsBeneficiary = false;

  String? savedPin;
  @override
  void initState() {
    super.initState();
    // _initializeSettings();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final amount =
        double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;
    const double fee = 10.00;
    final total = amount + fee;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SingleChildScrollView(
        reverse: true, // scrolls to bottom when keyboard appears
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(cancelSvg, height: 10.h),
              ),
            ),
            Text(
              'Are you sure?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryColor,
                fontSize: 27.sp,
              ),
            ),
            Text(
              'Please confirm your transfer details.',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall,
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: keyAColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    widget.recipientName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.recipientAccount,
                    style: textTheme.bodySmall?.copyWith(
                      color: lightSecondaryText,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    '${Constants.nairaCurrencySymbol}${total.toStringAsFixed(2)}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(color: checkboxBorderColor),
                  _buildRow('Amount', amount, lightSecondaryText, textTheme),
                  _buildRow('Fee', fee, lightSecondaryText, textTheme),
                ],
              ),
            ),
            SizedBox(height: 5.h),
            _buildBeneficiaryToggle(primaryColor, textTheme),
            SizedBox(height: 10.h),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  buttonName: 'Send Money',
                  buttonColor: primaryColor,
                  buttonTextColor: Colors.white,
                  onPressed: () {
                    final amountValue =
                        double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    const double fee = 10.0;
                    final total = amountValue + fee;

                    // Close bottom sheet first
                    Navigator.of(context).pop();

                    // Navigate to TransactionPin screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionPin(
                          recipientAccount: widget.recipientAccount,
                          recipientName: widget.recipientName,
                          amount: total,
                          saveAsBeneficiary: _saveAsBeneficiary,
                          type: "transfer",
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
      String label,
      double value,
      dynamic themeContext,
      TextTheme textTheme,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: lightSecondaryText),
        ),
        Text(
          '${Constants.nairaCurrencySymbol}${value.toStringAsFixed(2)}',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBeneficiaryToggle(dynamic themeContext, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: 8.w),
            Text(
              'Save as Beneficiary',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: lightText,
              ),
            ),
          ],
        ),
        Transform.scale(
          scale: 0.45,
          child: Switch(
            value: _saveAsBeneficiary,
            onChanged: (bool value) {
              setState(() {
                _saveAsBeneficiary = value;
              });
            },
            activeThumbColor: primaryColor,
          ),
        ),
      ],
    );
  }
}
