import 'package:bia/feature/dashboard/pages/send_money/input_transfer/transaction_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../core/constants.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

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

class BiaToBiaCompleteTransactionBottomSheet extends ConsumerStatefulWidget {
  final String amount;
  final String recipientName;
  final String recipientAccount;
  final String? recipientIconPath;
  final String? narration;
  final double? preCalculatedCharge;
  final double? preCalculatedTotal;
  final String? preCalculatedFeeDescription;

  const BiaToBiaCompleteTransactionBottomSheet({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientAccount,
    this.recipientIconPath,
    this.narration,
    this.preCalculatedCharge,
    this.preCalculatedTotal,
    this.preCalculatedFeeDescription,
  });

  @override
  ConsumerState<BiaToBiaCompleteTransactionBottomSheet> createState() =>
      _BiaToBiaCompleteTransactionBottomSheetState();
}

class _BiaToBiaCompleteTransactionBottomSheetState
    extends ConsumerState<BiaToBiaCompleteTransactionBottomSheet> {
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
            widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;

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
          _chargeAmount = 0.0;
          _totalAmount = numericAmount;
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
              'Confirm Transfer',
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
              'Verify details before completing transaction',
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
                    'TOTAL SEND AMOUNT',
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

            // Visual Transfer Diagram (Sender -> Recipient)
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
                  // Sender Card
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

                  // Connection
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

                  // Recipient Card
                  Column(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: primaryGreenColor600.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryGreenColor600.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : 'B',
                            style: TextStyle(
                              color: primaryGreenColor600,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SizedBox(
                        width: 80.w,
                        child: Text(
                          widget.recipientName.split(' ')[0],
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
                      label: 'Transfer Type',
                      value: 'Bia to Bia',
                      logo: widget.recipientIconPath,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildDetailRow(
                      context,
                      label: 'Recipient',
                      value: widget.recipientName,
                      isHighlighted: true,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildDetailRow(
                      context,
                      label: 'Bia Tag/Account',
                      value: widget.recipientAccount.startsWith('@')
                          ? widget.recipientAccount
                          : '@${widget.recipientAccount}',
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
                      value: '$currencySymbol${widget.amount}.00',
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
                        '$currencySymbol${_chargeAmount.toStringAsFixed(2)}',
                      ),

                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    _buildSummaryRow(
                      context,
                      'Total Payable',
                      '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
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

            SizedBox(height: 16.h),

            // Wallet Balance Mini Card
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: _buildWalletBalanceRow(
                context,
                balance: _getWalletBalance().toStringAsFixed(2),
                currencySymbol: currencySymbol,
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
                              builder: (_) => TransactionPin(
                                recipientAccount: widget.recipientAccount,
                                recipientName: widget.recipientName,
                                amount: _principalAmount,
                                saveAsBeneficiary: _saveAsBeneficiary,
                                type: "internal_transfer",
                                narration: widget.narration,
                              ),
                            ),
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
    String? logo,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (logo != null)
                Container(
                  width: 18.w,
                  height: 18.w,
                  margin: EdgeInsets.only(right: 6.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
          SizedBox(
            height: 12.h,
            width: 12.w,
            child: PulsingLogoIndicator(logoPath: 'assets/svg/logo-b.png'),
          )
        else if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              color: isHighlighted ? primaryColor : const Color(0xFF0F172A),
              fontSize: 14.sp,
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
              width: 38.w,
              height: 22.h,
              decoration: BoxDecoration(
                color: isToggled ? primaryColor : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(11.h),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isToggled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
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