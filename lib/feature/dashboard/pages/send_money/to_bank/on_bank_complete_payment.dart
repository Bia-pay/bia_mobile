import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
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

  const BankCompleteTransactionBottomSheet({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientAccount,
    required this.bankCode,
    required this.bankName,
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
  String _feeType = "flat";
  String _feeDescription = "";

  @override
  void initState() {
    super.initState();
    _fetchCharges();
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
        _principalAmount = numericAmount; // ✅ Store principal separately
        if (charges != null) {
          _chargeAmount = (charges['charge'] ?? 0).toDouble();
          _totalAmount = (charges['totalAmount'] ?? numericAmount).toDouble();
          _feeType = charges['feeType'] ?? 'flat';
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
    final ValueNotifier<bool> useCashback = ValueNotifier<bool>(false);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: lightBackground,
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
              width: isSmallScreen(context) ? 32.w : 40.w,
              height: isSmallScreen(context) ? 3.h : 4.h,
              decoration: BoxDecoration(
                color: grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: r.mediumSpacing),
            Text(
              'Please confirm your transfer details',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: r.subtitleFontSize,
                color: grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: r.smallSpacing),

            // Title - Centered
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$currencySymbol${_totalAmount.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: r.titleFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),


            SizedBox(height: r.largeSpacing),

            // Details Card - Responsive with max width
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(r.cardPadding),
                decoration: BoxDecoration(
                  color: grey50,
                  borderRadius: BorderRadius.circular(r.cardRadius),
                  border: Border.all(color: grey200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bank Logo & Name Row
                    _buildDetailRow(
                      context,
                      label: 'Bank',
                      value: widget.bankName,
                      logo: null,
                      isHighlighted: false,
                      r: r,
                    ),
                    Divider(height: r.mediumSpacing, color: grey300),

                    // Recipient Name Row
                    _buildDetailRow(
                      context,
                      label: 'Recipient',
                      value: widget.recipientName,
                      isHighlighted: true,
                      r: r,
                    ),
                    Divider(height: r.mediumSpacing, color: grey300),

                    // Account Number Row
                    _buildDetailRow(
                      context,
                      label: 'Account Number',
                      value: widget.recipientAccount,
                      r: r,
                    ),
                    Divider(height: r.mediumSpacing, color: grey300),

                    // Amount Row
                    _buildDetailRow(
                      context,
                      label: 'Amount',
                      value: '$currencySymbol${widget.amount}.00',
                      isHighlighted: true,
                      r: r,
                    ),

                    // Transfer Fee
                    if (_isLoadingCharges)
                      _buildSummaryRow(
                        context,
                        _feeDescription.isNotEmpty ? _feeDescription : 'Fee',
                        '${currencySymbol}0.00',
                        isLoading: true,
                        primaryColor: primaryColor,
                        r: r,
                      )
                    else
                      _buildSummaryRow(
                        context,
                        _feeDescription.isNotEmpty ? _feeDescription : 'Transfer Fee',
                        '$currencySymbol${_chargeAmount.toStringAsFixed(2)}',
                        primaryColor: primaryColor,
                        r: r,
                      ),

                    // Total Amount
                    Divider(height: r.mediumSpacing, color: grey300),
                    // Save as Beneficiary Toggle
                    SizedBox(height: r.smallSpacing),
                    ValueListenableBuilder<bool>(
                      valueListenable: useCashback,
                      builder: (context, isToggled, child) {
                        return _buildSummaryRow(
                          context,
                          'Save as Beneficiary',
                          '',
                          hasToggle: true,
                          isToggled: _saveAsBeneficiary,
                          onToggle: (value) {
                            setState(() {
                              _saveAsBeneficiary = value;
                            });
                          },
                          primaryColor: primaryColor,
                          r: r,
                        );
                      },
                    ),

                    // Wallet Balance
                    Divider(height: r.mediumSpacing, color: grey300),
                    _buildWalletBalanceRow(
                      context,
                      balance: _getWalletBalance().toStringAsFixed(2),
                      currencySymbol: currencySymbol,
                      primaryColor: primaryColor,
                      r: r,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: r.largeSpacing),

            // Continue Button - Full width responsive
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: SizedBox(
                width: double.infinity,
                height: r.buttonHeight,
                child: CustomButton(
                  buttonColor: primaryColor,
                  buttonTextColor: lightBackground,
                  buttonName: 'Continue',
                  onPressed: _isLoadingCharges
                      ? null
                      : () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankTransactionPin(
                          recipientAccount: widget.recipientAccount,
                          recipientName: widget.recipientName,
                          amount: _principalAmount, // ✅ Fixed: Send principal, not total
                          saveAsBeneficiary: _saveAsBeneficiary,
                          bankCode: widget.bankCode,
                          bankName: widget.bankName,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: r.mediumSpacing),

            // Cancel Button
            // TextButton(
            //   onPressed: () => Navigator.pop(context),
            //   child: Text(
            //     'Cancel',
            //     style: theme.textTheme.bodyMedium?.copyWith(
            //       color: grey,
            //       fontSize: r.bodyFontSize,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static Widget _buildDetailRow(
      BuildContext context, {
        required String label,
        required String value,
        String? logo,
        bool isHighlighted = false,
        required _ResponsiveHelper r,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.smallSpacing / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: grey600,
                fontSize: r.bodyFontSize,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (logo != null)
                  Container(
                    width: r.logoSize,
                    height: r.logoSize,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isHighlighted ? primaryGreenColor600 : transparentBlack87,
                      fontSize: r.bodyFontSize,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        required Color primaryColor,
        required _ResponsiveHelper r,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: grey600,
                fontSize: r.bodyFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  height: 12.h,
                  width: 12.w,
                  child: PulsingLogoIndicator(logoPath: 'assets/svg/logo-b.png'),
                )
              else if (value.isNotEmpty)
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isHighlighted ? primaryGreenColor600 : transparentBlack87,
                    fontSize: r.bodyFontSize,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              SizedBox(width: 8.w),
              if (hasToggle)
                GestureDetector(
                  onTap: () {
                    if (onToggle != null) {
                      onToggle(!isToggled);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: r.toggleWidth,
                    height: r.toggleHeight,
                    decoration: BoxDecoration(
                      color: isToggled ? primaryColor : grey300,
                      borderRadius: BorderRadius.circular(r.toggleHeight / 2),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isToggled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: r.toggleKnobSize,
                        height: r.toggleKnobSize,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: const BoxDecoration(
                          color: lightBackground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildWalletBalanceRow(
      BuildContext context, {
        required String balance,
        required String currencySymbol,
        required Color primaryColor,
        required _ResponsiveHelper r,
      }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: r.mediumSpacing,
        horizontal: r.cardPadding,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: grey300),
        borderRadius: BorderRadius.circular(r.buttonRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: primaryColor,
            size: r.iconSize,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: grey600,
                    fontSize: r.smallFontSize,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$currencySymbol$balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: r.bodyFontSize,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: primaryColor,
            size: r.iconSize,
          ),
        ],
      ),
    );
  }
}