import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import '../../../widgets/keypad.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'on_bank_complete_payment.dart';
import '../../../../../app/utils/widgets/custom_text_field.dart';

// ---------------------------------------------------------------------------
// Responsive helper – derive all sizing from real screen dimensions so the
// layout adapts automatically from tiny phones (360 dp) to 12" tablets.
// ---------------------------------------------------------------------------
class _Dims {
  final double screenW;
  final double screenH;

  // Breakpoints (logical pixels / dp)
  final bool isTinyPhone;  // height < 600
  final bool isSmallPhone; // height < 700
  final bool isTablet;     // width  >= 600
  final bool isLargeTablet;// width  >= 900

  const _Dims({
    required this.screenW,
    required this.screenH,
    required this.isTinyPhone,
    required this.isSmallPhone,
    required this.isTablet,
    required this.isLargeTablet,
  });

  factory _Dims.of(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    return _Dims(
      screenW: w,
      screenH: h,
      isTinyPhone: h < 600,
      isSmallPhone: h < 700,
      isTablet: w >= 600,
      isLargeTablet: w >= 900,
    );
  }

  // ── Spacing ──────────────────────────────────────────────────────────────
  double get topBarV => isTinyPhone ? 6 : (isSmallPhone ? 8 : (isTablet ? 16 : 12));
  double get topBarH => isTablet ? 28 : 16;
  double get sectionGap => isTinyPhone ? 8 : (isSmallPhone ? 12 : (isTablet ? 32 : 26));
  double get cardPadH => isTablet ? 20 : 14;
  double get cardPadV => isTinyPhone ? 10 : (isTablet ? 18 : 14);
  double get cardRadius => isTablet ? 20 : 16;
  double get cardHMargin => isTablet ? 32 : 20;
  double get keypadHPad => isTablet ? 0 : 20;
  double get bottomPad => isTinyPhone ? 6 : (isSmallPhone ? 8 : (isTablet ? 24 : 16));

  // ── Avatar ───────────────────────────────────────────────────────────────
  double get avatarSize => isTinyPhone ? 36 : (isTablet ? 52 : 44);
  double get avatarFontSize => isTinyPhone ? 14 : (isTablet ? 20 : 16);

  // ── Typography ───────────────────────────────────────────────────────────
  double get titleFontSize => isTablet ? 18 : 15;
  double get recipientNameFontSize => isTinyPhone ? 13 : (isTablet ? 16 : 14);
  double get recipientSubFontSize => isTinyPhone ? 10 : (isTablet ? 13 : 11);
  double get amountFontSize {
    if (isTinyPhone) return 34;
    if (isSmallPhone) return 42;
    if (isLargeTablet) return 64;
    if (isTablet) return 56;
    return 52;
  }
  double get hintFontSize => isTinyPhone ? 11 : (isTablet ? 14 : 13);
  double get warningFontSize => isTinyPhone ? 10 : (isTablet ? 13 : 12);
  double get balanceFontSize => isTinyPhone ? 10 : (isTablet ? 13 : 11);

  // ── Icons ────────────────────────────────────────────────────────────────
  double get backIconSize => isTablet ? 20 : 16;
  double get walletIconSize => isTablet ? 16 : 14;
  double get bankIconSize => isTinyPhone ? 10 : (isTablet ? 14 : 11);
  double get swapIconSize => isTablet ? 20 : 16;
  double get warningIconSize => isTinyPhone ? 12 : (isTablet ? 16 : 14);
  double get keypadActionIconSize => isTablet ? 28 : (isSmallPhone ? 20 : 24);

  // ── Keypad container width ───────────────────────────────────────────────
  // Phone: unconstrained (full width inside padding).
  // Tablet: fixed column width so keys don't become huge.
  double get keypadMaxWidth => isLargeTablet ? 420 : (isTablet ? 380 : double.infinity);
}

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
  final _narrationController = TextEditingController();

  @override
  void dispose() {
    _narrationController.dispose();
    super.dispose();
  }

  // ── Amount logic ──────────────────────────────────────────────────────────

  void addDigit(String value) {
    setState(() {
      String current = amount.replaceAll('₦', '').replaceAll(',', '');
      current = (current == "0") ? value : current + value;
      final parsed = double.tryParse(current) ?? 0;
      amount = '₦${NumberFormat('#,##0').format(parsed)}';
      widget.controller.text = amount;
      _checkAmountValidation();
    });
  }

  void removeDigit() {
    setState(() {
      String current = amount.replaceAll('₦', '').replaceAll(',', '');
      if (current.isNotEmpty) current = current.substring(0, current.length - 1);
      if (current.isEmpty) current = "0";
      final parsed = double.tryParse(current) ?? 0;
      amount = '₦${NumberFormat('#,##0').format(parsed)}';
      widget.controller.text = amount;
      _checkAmountValidation();
    });
  }

  void _checkAmountValidation() {
    final v = _numericValue;
    showMinWarning = v < 100 && v != 0;
    showInsufficientFundsWarning = v > _getWalletBalance() && v != 0;
  }

  num get _numericValue =>
      num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  double _getWalletBalance() {
    final box = Hive.box('authBox');
    return double.tryParse(
          box.get('balance', defaultValue: '0').toString().replaceAll(',', ''),
        ) ??
        0.0;
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) return '₦${(balance / 1000000).toStringAsFixed(1)}M';
    if (balance >= 1000) return '₦${(balance / 1000).toStringAsFixed(1)}K';
    return '₦${NumberFormat('#,##0.00').format(balance)}';
  }

  // ── Confirm sheet ─────────────────────────────────────────────────────────

  Future<void> _showConfirmBottomSheet() async {
    final numericAmount = _numericValue;

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

      double chargeAmount = charges != null
          ? (charges['charge'] ?? 0).toDouble()
          : 10.0;
      double totalAmount = charges != null
          ? (charges['totalAmount'] ?? numericAmount).toDouble()
          : numericAmount.toDouble() + chargeAmount;
      String feeDescription = charges?['description'] ?? 'Transfer Fee';

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
          narration: _narrationController.text,
          preCalculatedCharge: chargeAmount,
          preCalculatedTotal: totalAmount,
          preCalculatedFeeDescription: feeDescription,
        ),
      );
    } catch (_) {
      EasyLoading.dismiss();
      EasyLoading.showError("Failed to calculate charges");
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletBalance = _getWalletBalance();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: offWhiteBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final d = _Dims.of(constraints);
              return d.isTablet
                  ? _buildTabletLayout(theme, walletBalance, d)
                  : _buildPhoneLayout(theme, walletBalance, d);
            },
          ),
        ),
      ),
    );
  }

  // ── Phone layout ──────────────────────────────────────────────────────────

  Widget _buildPhoneLayout(ThemeData theme, double walletBalance, _Dims d) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        _buildTopBar(theme, walletBalance, d),
        _buildRecipientCard(theme, d),
        SizedBox(height: d.sectionGap),
        _buildAmountDisplay(walletBalance, d),
        SizedBox(height: d.sectionGap),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: CustomTextFormField(
            controller: _narrationController,
            label: 'Narration (Optional)',
            hintText: 'What is this for?',
            validator: (val) => null,
          ),
        ),
        const Spacer(),
        if (!keyboardOpen) ...[
          _buildKeypad(d),
          SizedBox(height: d.bottomPad),
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
          SizedBox(height: d.bottomPad),
        ],
      ],
    );
  }

  // ── Tablet layout (side-by-side) ──────────────────────────────────────────

  Widget _buildTabletLayout(ThemeData theme, double walletBalance, _Dims d) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            _buildTopBar(theme, walletBalance, d),
            SizedBox(height: d.sectionGap),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: recipient + amount
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: EdgeInsets.only(left: d.cardHMargin),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRecipientCard(theme, d),
                          SizedBox(height: d.sectionGap * 1.2),
                          _buildAmountDisplay(walletBalance, d),
                          SizedBox(height: d.sectionGap),
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
                  ),
                  SizedBox(width: d.sectionGap * 1.5),
                  // Right: keypad
                  Expanded(
                    flex: 9,
                    child: Padding(
                      padding: EdgeInsets.only(right: d.cardHMargin),
                      child: _buildKeypad(d),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: d.bottomPad),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildTopBar(ThemeData theme, double walletBalance, _Dims d) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: d.topBarH, vertical: d.topBarV),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(d.isTablet ? 12 : 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: lightBorderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: d.backIconSize,
                color: darkBackground,
              ),
            ),
          ),
          const Spacer(),
          // Title
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: d.titleFontSize,
              color: darkBackground,
            ),
          ),
          const Spacer(),
          // Balance pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: d.isTablet ? 16 : 12,
              vertical: d.isTablet ? 8 : 6,
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
                  size: d.walletIconSize,
                  color: primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatBalance(walletBalance),
                  style: TextStyle(
                    fontSize: d.balanceFontSize,
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

  Widget _buildRecipientCard(ThemeData theme, _Dims d) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: d.cardHMargin),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: d.cardPadH,
          vertical: d.cardPadV,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(d.cardRadius),
          border: Border.all(color: lightBorderColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: d.avatarSize,
              height: d.avatarSize,
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
                    fontSize: d.avatarFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: d.isTablet ? 16 : 12),
            // Name & bank info
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
                      fontSize: d.recipientNameFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        size: d.bankIconSize,
                        color: lightSecondaryText,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${widget.bankName} • ${widget.recipientAccount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: lightSecondaryText,
                            fontSize: d.recipientSubFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Change recipient button
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(d.isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  color: lightBorderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: d.swapIconSize,
                  color: lightSecondaryText,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildAmountDisplay(double walletBalance, _Dims d) {
    return Column(
      children: [
        // Amount text – shrinks if too long via FittedBox
        Padding(
          padding: EdgeInsets.symmetric(horizontal: d.cardHMargin),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount == "0" ? "₦0" : amount,
              style: TextStyle(
                fontSize: d.amountFontSize,
                fontWeight: FontWeight.w800,
                color: showInsufficientFundsWarning ? errorColor : darkBackground,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Warning / hint
        if (showMinWarning)
          _buildWarningChip(
            "Minimum amount is ₦100",
            Icons.warning_amber_rounded,
            errorColor,
            d,
          ),
        if (showInsufficientFundsWarning)
          _buildWarningChip(
            "Insufficient balance (₦${NumberFormat('#,##0.00').format(walletBalance)})",
            Icons.error_outline_rounded,
            errorColor,
            d,
          ),
        if (!showMinWarning && !showInsufficientFundsWarning)
          Text(
            "Enter amount to transfer",
            style: TextStyle(
              fontSize: d.hintFontSize,
              color: lightSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }

  Widget _buildKeypad(_Dims d) {
    final Widget keypad = Padding(
      padding: EdgeInsets.symmetric(horizontal: d.keypadHPad),
      child: CustomGridKeypad(
        onNumberPressed: addDigit,
        leftAction: ActionKey(
          child: Icon(
            Icons.arrow_forward_rounded,
            color: lightBackground,
            size: d.keypadActionIconSize,
          ),
          backgroundColor: primaryColor,
          onTap: _showConfirmBottomSheet,
        ),
        rightAction: ActionKey(
          child: Icon(
            Icons.backspace_rounded,
            color: primaryColor,
            size: d.keypadActionIconSize,
          ),
          backgroundColor: primaryColor.withValues(alpha: 0.1),
          onTap: removeDigit,
        ),
      ),
    );

    // On tablet we constrain the keypad width so keys don't become huge
    if (d.isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: d.keypadMaxWidth),
          child: keypad,
        ),
      );
    }

    // On phone we let FittedBox shrink it if the screen is tiny
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: d.screenW,
        child: keypad,
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.08, end: 0, duration: 500.ms);
  }

  Widget _buildWarningChip(String text, IconData icon, Color color, _Dims d) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: EdgeInsets.symmetric(
        horizontal: d.isTablet ? 16 : 12,
        vertical: d.isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: d.warningIconSize),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: d.warningFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}