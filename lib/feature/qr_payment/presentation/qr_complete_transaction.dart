import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../core/constants.dart';
import '../../../../core/easy_loading_config.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:go_router/go_router.dart';

/// Responsive helper class
class _ResponsiveHelper {
  final BuildContext context;
  _ResponsiveHelper(this.context);

  Size get size => MediaQuery.of(context).size;
  double get width => size.width;
  double get height => size.height;

  bool get isSmall => width < 360;
  bool get isMedium => width >= 360 && width < 600;
  bool get isTablet => width >= 600 && width < 900;
  bool get isLarge => width >= 900;
  bool get isLandscape => width > height;

  double get horizontalPadding => isSmall ? 16.w : (isTablet ? 32.w : 24.w);
  double get verticalPadding => isSmall ? 16.h : (isTablet ? 32.h : 24.h);
  double get cardPadding => isSmall ? 16.w : (isTablet ? 28.w : 20.w);

  double get titleFontSize => isSmall ? 20.sp : (isTablet ? 32.sp : 25.sp);
  double get subtitleFontSize => isSmall ? 11.sp : (isTablet ? 16.sp : 12.sp);
  double get bodyFontSize => isSmall ? 10.sp : (isTablet ? 14.sp : 11.sp);
  double get smallFontSize => isSmall ? 9.sp : (isTablet ? 12.sp : 10.sp);

  double get smallSpacing => isSmall ? 6.h : (isTablet ? 12.h : 8.h);
  double get mediumSpacing => isSmall ? 12.h : (isTablet ? 20.h : 16.h);
  double get largeSpacing => isSmall ? 16.h : (isTablet ? 28.h : 24.h);

  double get sheetRadius => isSmall ? 16.r : (isTablet ? 32.r : 24.r);
  double get cardRadius => isSmall ? 12.r : (isTablet ? 20.r : 16.r);
  double get buttonRadius => isSmall ? 8.r : (isTablet ? 16.r : 12.r);

  double get logoSize => isSmall ? 16.w : (isTablet ? 28.w : 20.w);
  double get iconSize => isSmall ? 18.sp : (isTablet ? 24.sp : 20.sp);

  double get toggleWidth => isSmall ? 36.w : (isTablet ? 48.w : 40.w);
  double get toggleHeight => isSmall ? 20.h : (isTablet ? 26.h : 22.h);
  double get toggleKnobSize => isSmall ? 16.w : (isTablet ? 22.w : 18.w);

  double get buttonHeight => isSmall ? 44.h : (isTablet ? 60.h : 48.h);

  double get maxContentWidth => isLarge ? 600.w : double.infinity;
}

class QrCompleteTransactionBottomSheet extends ConsumerStatefulWidget {
  final double amount;
  final String payerName;
  final String payerAccount;
  final double chargeAmount;
  final double totalAmount;
  final String feeDescription;
  final String? narration;

  const QrCompleteTransactionBottomSheet({
    super.key,
    required this.amount,
    required this.payerName,
    required this.payerAccount,
    required this.chargeAmount,
    required this.totalAmount,
    required this.feeDescription,
    this.narration,
  });

  @override
  ConsumerState<QrCompleteTransactionBottomSheet> createState() =>
      _QrCompleteTransactionBottomSheetState();
}

class _QrCompleteTransactionBottomSheetState
    extends ConsumerState<QrCompleteTransactionBottomSheet> {
  late final double _chargeAmount;
  late final double _totalAmount;
  late final String _feeDescription;

  @override
  void initState() {
    super.initState();
    _chargeAmount = widget.chargeAmount;
    _totalAmount = widget.totalAmount;
    _feeDescription = widget.feeDescription;
  }

  @override
  Widget build(BuildContext context) {
    final r = _ResponsiveHelper(context);
    final currencySymbol = Constants.nairaCurrencySymbol;

    return Container(
      decoration: BoxDecoration(
        color: offWhiteBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.sheetRadius)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: r.horizontalPadding,
        vertical: r.verticalPadding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),

            Text(
              'Confirm QR Collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Verify details before requesting payment authorization',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 16.h),

            // Premium Large Amount Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'TOTAL COLLECTION AMOUNT',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Visual Transfer Diagram (Customer/Payer -> Merchant)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Payer Card
                  Column(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF475569),
                          size: 24,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SizedBox(
                        width: 80.w,
                        child: Text(
                          widget.payerName.isNotEmpty ? widget.payerName.split(' ')[0] : 'Customer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Connection (Points from Payer to merchant wallet)
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 2.w),
                              width: 5.w,
                              height: 5.w,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: (index + 1) * 0.25),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 4.h),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                  // Merchant Wallet Card
                  Column(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'My Wallet',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Details Card
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      context,
                      label: 'Collection Type',
                      value: 'QR Request Pay',
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildDetailRow(
                      context,
                      label: 'Customer Name',
                      value: widget.payerName,
                      isHighlighted: true,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildDetailRow(
                      context,
                      label: 'Customer Account',
                      value: widget.payerAccount,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    if (widget.narration != null && widget.narration!.isNotEmpty) ...[
                      _buildDetailRow(
                        context,
                        label: 'Narration',
                        value: widget.narration!,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    ],

                    _buildDetailRow(
                      context,
                      label: 'Subtotal Amount',
                      value: '$currencySymbol${widget.amount.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildSummaryRow(
                      context,
                      _feeDescription.isNotEmpty ? _feeDescription : 'Transaction Fee',
                      '$currencySymbol${_chargeAmount.toStringAsFixed(2)}',
                    ),

                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildSummaryRow(
                      context,
                      'Total Deductable',
                      '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Continue Button
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  buttonColor: primaryColor,
                  buttonTextColor: Colors.white,
                  buttonName: 'Proceed to Payer PIN',
                  onPressed: () {
                    Navigator.pop(context);

                    // Navigate to secure deduction pin screen
                    context.pushNamed(
                      RouteList.qrDeductionPinScreen,
                      extra: {
                        'ownerAccount': widget.payerAccount,
                        'amount': widget.amount,
                        'narration': widget.narration ?? '',
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHighlighted ? primaryGreenColor600 : const Color(0xFF0F172A),
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildSummaryRow(
    BuildContext context,
    String title,
    String value, {
    bool isHighlighted = false,
    bool isLoading = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontSize: 13.sp,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        if (isLoading)
          const SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? primaryColor : const Color(0xFF0F172A),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
