import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../core/constants.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'bank_transaction_pin.dart';

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

class BankCompleteTransactionBottomSheet extends ConsumerStatefulWidget {
  final String amount;
  final String recipientName;
  final String recipientAccount;
  final String bankName;
  final String bankCode;
  final String? narration;
  final double? preCalculatedCharge;
  final double? preCalculatedTotal;
  final String? preCalculatedFeeDescription;

  const BankCompleteTransactionBottomSheet({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientAccount,
    required this.bankCode,
    required this.bankName,
    this.narration,
    this.preCalculatedCharge,
    this.preCalculatedTotal,
    this.preCalculatedFeeDescription,
  });

  @override
  ConsumerState<BankCompleteTransactionBottomSheet> createState() =>
      _BankCompleteTransactionBottomSheetState();
}

class _BankCompleteTransactionBottomSheetState
    extends ConsumerState<BankCompleteTransactionBottomSheet> {
  final TextEditingController pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  bool _saveAsBeneficiary = false;
  bool _isLoadingCharges = true;
  double _principalAmount = 0.0;
  double _chargeAmount = 0.0;
  double _totalAmount = 0.0;
  String _feeDescription = "";

  @override
  void initState() {
    super.initState();
    _principalAmount = double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (widget.preCalculatedCharge != null && widget.preCalculatedTotal != null) {
      _chargeAmount = widget.preCalculatedCharge!;
      _totalAmount = widget.preCalculatedTotal!;
      _feeDescription = widget.preCalculatedFeeDescription ?? 'Transfer Fee';
      _isLoadingCharges = false;
    } else {
      _fetchCharges();
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  Future<void> _fetchCharges() async {
    final numericAmount = double.tryParse(
        widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')
    ) ?? 0.0;

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    final charges = await dashboardCtrl.getTransactionCharges(
      context,
      amount: numericAmount,
      transactionType: "DEBIT",
      serviceType: "TRANSFER",
    );

    if (mounted) {
      setState(() {
        _principalAmount = numericAmount;
        if (charges != null) {
          _chargeAmount = (charges['charge'] ?? 0).toDouble();
          _totalAmount = (charges['totalAmount'] ?? numericAmount).toDouble();
          _feeDescription = charges['description'] ?? 'Transfer Fee';
        } else {
          _chargeAmount = 10.0;
          _totalAmount = numericAmount + _chargeAmount;
        }
        _isLoadingCharges = false;
      });
    }
  }

  static double _getWalletBalance() {
    try {
      final box = Hive.box('authBox');
      final balanceStr = box.get('balance', defaultValue: '0').toString();
      return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _ResponsiveHelper(context);
    final currencySymbol = Constants.nairaCurrencySymbol;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 540 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: offWhiteBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isTablet ? 24.0 : r.sheetRadius)),
          ),
          padding: EdgeInsets.only(
            left: isTablet ? 20.0 : r.horizontalPadding,
            right: isTablet ? 20.0 : r.horizontalPadding,
            top: isTablet ? 16.0 : r.verticalPadding,
            bottom: 0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                Container(
                  width: isTablet ? 40.0 : 40.w,
                  height: isTablet ? 4.0 : 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: isTablet ? 14.0 : 16.h),

                Text(
                  'Confirm Bank Transfer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 20.0 : 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isTablet ? 4.0 : 6.h),
                Text(
                  'Verify details before completing transaction',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 12.0 : 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: isTablet ? 14.0 : 16.h),

                // Premium Large Amount Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 16.w, vertical: isTablet ? 16.0 : 18.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
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
                        'TOTAL SEND AMOUNT',
                        style: TextStyle(
                          fontSize: isTablet ? 10.0 : 10.sp,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6.0 : 8.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$currencySymbol${NumberFormat('#,##0.00').format(_totalAmount)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 28.0 : 28.sp,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 14.0 : 16.h),

                // Visual Transfer Diagram (Sender -> Bank/Recipient)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 20.w, vertical: isTablet ? 12.0 : 14.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Sender Card
                      Column(
                        children: [
                          Container(
                            width: isTablet ? 44.0 : 48.r,
                            height: isTablet ? 44.0 : 48.r,
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
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: isTablet ? 20.0 : 22,
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.0 : 6.h),
                          Text(
                            'My Wallet',
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),

                      // Connection
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 2.0 : 2.w),
                                  width: isTablet ? 4.0 : 5.w,
                                  height: isTablet ? 4.0 : 5.w,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: (index + 1) * 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: isTablet ? 2.0 : 4.h),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: primaryColor,
                              size: isTablet ? 14.0 : 16,
                            ),
                          ],
                        ),
                      ),

                      // Bank Recipient Card
                      Column(
                        children: [
                          Container(
                            width: isTablet ? 44.0 : 48.r,
                            height: isTablet ? 44.0 : 48.r,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              color: const Color(0xFF475569),
                              size: isTablet ? 18.0 : 20,
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.0 : 6.h),
                          SizedBox(
                            width: isTablet ? 90.0 : 80.w,
                            child: Text(
                              widget.recipientName.isNotEmpty ? widget.recipientName.split(' ')[0] : 'Recipient',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 12.0 : 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 14.0 : 16.h),

                // Details Card
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 16.0 : 16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailRow(
                          context,
                          label: 'Destination Bank',
                          value: widget.bankName,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),

                        _buildDetailRow(
                          context,
                          label: 'Recipient Name',
                          value: widget.recipientName,
                          isHighlighted: true,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),

                        _buildDetailRow(
                          context,
                          label: 'Account Number',
                          value: widget.recipientAccount,
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
                          label: 'Principal Amount',
                          value: '$currencySymbol${NumberFormat('#,##0.00').format(double.tryParse(widget.amount) ?? 0.0)}',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),

                        if (_isLoadingCharges)
                          _buildSummaryRow(
                            context,
                            _feeDescription.isNotEmpty ? _feeDescription : 'Fee',
                            '${currencySymbol}0.00',
                            isLoading: true,
                          )
                        else
                          _buildSummaryRow(
                            context,
                            _feeDescription.isNotEmpty ? _feeDescription : 'Transfer Fee',
                            '$currencySymbol${NumberFormat('#,##0.00').format(_chargeAmount)}',
                          ),

                        const Divider(height: 20, color: Color(0xFFF1F5F9)),

                        _buildSummaryRow(
                          context,
                          'Total Payable',
                          '$currencySymbol${NumberFormat('#,##0.00').format(_totalAmount)}',
                          isHighlighted: true,
                        ),

                        const Divider(height: 20, color: Color(0xFFF1F5F9)),

                        // Save as Beneficiary Toggle Row
                        _buildSummaryRow(
                          context,
                          'Save Beneficiary',
                          '',
                          hasToggle: true,
                          isToggled: _saveAsBeneficiary,
                          onToggle: (value) {
                            setState(() {
                              _saveAsBeneficiary = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 14.0 : 16.h),

                // Wallet Balance Mini Card
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                  child: _buildWalletBalanceRow(
                    context,
                    balance: NumberFormat('#,##0.00').format(_getWalletBalance()),
                    currencySymbol: currencySymbol,
                  ),
                ),

                SizedBox(height: isTablet ? 20.0 : 24.h),

                // Continue Button
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      buttonColor: primaryColor,
                      buttonTextColor: Colors.white,
                      buttonName: 'Continue to PIN',
                      onPressed: _isLoadingCharges
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context);

                              // Navigate to PIN screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BankTransactionPin(
                                    recipientAccount: widget.recipientAccount,
                                    recipientName: widget.recipientName,
                                    amount: _principalAmount,
                                    saveAsBeneficiary: _saveAsBeneficiary,
                                    bankCode: widget.bankCode,
                                    bankName: widget.bankName,
                                    narration: widget.narration,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                ),
                SizedBox(height: (isTablet ? 16.0 : 12.h) + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
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
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: isTablet ? 13.0 : 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 8.0 : 8.w),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHighlighted ? primaryGreenColor600 : const Color(0xFF0F172A),
              fontSize: isTablet ? 13.5 : 13.sp,
              fontWeight: FontWeight.bold,
            ),
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
    bool hasToggle = false,
    bool isToggled = false,
    bool isLoading = false,
    ValueChanged<bool>? onToggle,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isHighlighted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontSize: isTablet ? 13.0 : 13.sp,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        if (isLoading)
          SizedBox(
            height: isTablet ? 12.0 : 12.h,
            width: isTablet ? 12.0 : 12.w,
            child: PulsingLogoIndicator(logoPath: 'assets/svg/logo-b.png'),
          )
        else if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? primaryColor : const Color(0xFF0F172A),
              fontSize: isTablet ? 14.0 : 14.sp,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (hasToggle)
          GestureDetector(
            onTap: () {
              if (onToggle != null) {
                onToggle(!isToggled);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isTablet ? 38.0 : 38.w,
              height: isTablet ? 22.0 : 22.h,
              decoration: BoxDecoration(
                color: isToggled ? primaryColor : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(11.0),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isToggled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: isTablet ? 18.0 : 18.w,
                  height: isTablet ? 18.0 : 18.w,
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 2.0 : 2.w),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildWalletBalanceRow(
    BuildContext context, {
    required String balance,
    required String currencySymbol,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 12.h,
        horizontal: 16.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$currencySymbol$balance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}