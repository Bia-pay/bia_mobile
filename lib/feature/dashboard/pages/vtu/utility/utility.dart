import 'dart:async';

import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboard_repo/repo.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../dashboardcontroller/provider.dart';
import '../../../widgets/transaction.dart';
import '../../send_money/widget/tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bia/feature/dashboard/widgets/service_guard.dart';

class Electricity extends StatefulWidget {
  const Electricity({super.key});

  @override
  State<Electricity> createState() => _ElectricityState();
}

class _ElectricityState extends State<Electricity> {
  Map<String, dynamic>? _selectedProvider;

  @override
  Widget build(BuildContext context) {
    return ServiceGuard(
      service: ServiceType.utility,
      child: Scaffold(
          backgroundColor: offWhiteBackground,
        resizeToAvoidBottomInset: true,
        appBar: CustomAppBar(
          title: 'Electricity',
          onBackPressed: () async {
            FocusScope.of(context).unfocus();
            await Future.delayed(const Duration(milliseconds: 150));
            if (!context.mounted) return;
            if (context.canPop()) {
              context.pop();
            }
          },
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 18.w),
              child: SvgPicture.asset(
                bell,
                width: MediaQuery.of(context).size.width > 600 ? 22.0 : 24.w,
                height: MediaQuery.of(context).size.width > 600 ? 22.0 : 24.h,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              final isDesktop = constraints.maxWidth >= 1200;
              final horizontalPadding = isDesktop
                  ? 120.w
                  : (isTablet ? 30.w : 8.w);
              final maxContentWidth = isDesktop ? 800.w : double.infinity;
  
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CardTwo(
                            onChanged: (provider) {
                              setState(() {
                                _selectedProvider = provider;
                              });
                            },
                          ),
                         // SizedBox(height: isTablet ? 14.h : 10.h),
                          CardOne(selectedProvider: _selectedProvider),
                          SizedBox(height: isTablet ? 24.h : 20.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 14.0 : 17.h,
                              horizontal: isTablet ? 16.0 : 10.w,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(isTablet ? 16.0 : 15.r),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Electricity Service',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 15.0 : 16.sp,
                                      ),
                                ),
                                SizedBox(height: isTablet ? 10.0 : 10.h),
                                ...dataPlans
                                    .map(
                                      (tx) => Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 10.0 : 8.h,
                                          horizontal: isTablet ? 14.0 : 18.w,
                                        ),
                                        margin: EdgeInsets.symmetric(
                                          vertical: isTablet ? 6.0 : 6.h,
                                          horizontal: isTablet ? 4.0 : 7.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            isTablet ? 10.0 : 8.r,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: isTablet ? 40.0 : 35.h,
                                              width: isTablet ? 40.0 : 35.w,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: Image.asset(
                                                'assets/svg/bank.png',
                                                height: isTablet ? 22.0 : 20.h,
                                              ),
                                            ),
                                            SizedBox(
                                              width: isTablet ? 14.0 : 15.w,
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontSize: isTablet
                                                              ? 14.0
                                                              : 15.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  SizedBox(height: isTablet ? 2.0 : 2.h),
                                                  Text(
                                                    tx.dateTime,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontSize: isTablet
                                                              ? 12.0
                                                              : 11.sp,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_outlined,
                                              size: isTablet ? 14.0 : 12.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 20.0 : 25.h),
                        ],
                      ),
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
}

class CardOne extends ConsumerStatefulWidget {
  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;

  const CardOne({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  @override
  ConsumerState<CardOne> createState() => _CardOneState();
}

class _CardOneState extends ConsumerState<CardOne> {
  Map<String, dynamic>? _selectedProvider;
  String _phoneNumber = '';
  Timer? _debounce;
  String? _customerName;
  String? _address;
  String? _minPurchaseAmount;
  bool _isVerifying = false;
  bool _saveAsBeneficiary = false;
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
    _nameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _isFormValid {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final balance = _getWalletBalance();

    final isMeterValid =
        _meterController.text.isNotEmpty &&
        _customerName != null &&
        _customerName != "Invalid meter" &&
        !_isVerifying;

    double minAmount = 0;
    if (_minPurchaseAmount != null && _minPurchaseAmount!.isNotEmpty) {
      minAmount = double.tryParse(_minPurchaseAmount!) ?? 0;
    }

    final isAmountValid = amount > 0 && amount >= minAmount;
    final hasSufficientBalance = amount <= balance;

    return widget.selectedProvider != null &&
        isMeterValid &&
        isAmountValid &&
        hasSufficientBalance;
  }

  bool showInsufficientFundsWarning = false;
  double walletBalance = 0.0;

  double _getWalletBalance() {
    final box = Hive.box('authBox');
    final balanceStr = box.get('balance', defaultValue: '0').toString();
    return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
  }
  bool showMinimumAmountWarning = false;
  void _validateAmount(int amount) {
    final balance = _getWalletBalance();

    double minAmount = 0;
    if (_minPurchaseAmount != null && _minPurchaseAmount!.isNotEmpty) {
      minAmount = double.tryParse(_minPurchaseAmount!) ?? 0;
    }

    setState(() {
      walletBalance = balance;

      showInsufficientFundsWarning = amount > 0 && amount > balance;

      showMinimumAmountWarning =
          amount > 0 && amount < minAmount;
    });
  }

  void _onMeterChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _customerName = null; // reset until valid
      _address = null;
      _minPurchaseAmount = null;
    });

    // 🚫 Manual verification preferred now
  }

  @override
  void didUpdateWidget(covariant CardOne oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedProvider != oldWidget.selectedProvider) {
      final meter = _meterController.text.trim();
      if (meter.isNotEmpty) {
        _verifyMeter(meter);
      }
    }
  }

  Future<void> _verifyMeter(String meter) async {
    final serviceId = widget.selectedProvider?['serviceID'];

    if (serviceId == null) return;

    setState(() {
      _isVerifying = true;
      _customerName = null;
      _address = null;
    });

    final providerName = widget.selectedProvider?['name']?.toString().toLowerCase() ?? "";
    final type = providerName.contains("postpaid") ? "postpaid" : "prepaid";

    final repo = ProviderScope.containerOf(
      context,
    ).read(dashboardRepositoryProvider);

    final result = await repo.verifyElectricityMeter(
      serviceId: serviceId,
      meterNumber: meter,
      type: type,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _customerName = result['Customer_Name'];
        _address = result['Address'];
        _minPurchaseAmount = result['Min_Purchase_Amount']?.toString();
        _isVerifying = false;
      });
      final amount = int.tryParse(_amountController.text) ?? 0;
      _validateAmount(amount);
    } else {
      setState(() {
        _customerName = "Invalid meter";
        _address = "";
        _minPurchaseAmount = null;
        _isVerifying = false;
      });
      final amount = int.tryParse(_amountController.text) ?? 0;
      _validateAmount(amount);
    }
  }

  // Controllers removed here as they are moved up to state variables level

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final isDesktop = constraints.maxWidth >= 1200;

        final cardPadding = isDesktop
            ? EdgeInsets.symmetric(vertical: 22.h, horizontal: 48.w)
            : (isTablet
                  ? const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0)
                  : EdgeInsets.symmetric(vertical: 7.h, horizontal: 25.w));

        final fontSize = isDesktop ? 16.0 : (isTablet ? 14.0 : 14.sp);
        final titleFontSize = isDesktop ? 18.0 : (isTablet ? 15.0 : 16.sp);
        final inputHeight = isDesktop ? 54.0 : (isTablet ? 48.0 : 50.h);
        final buttonHeight = isDesktop ? 54.0 : (isTablet ? 48.0 : 55.h);
        final theme = Theme.of(context);

        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(isTablet ? 16.0 : 15.r),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 2.0 : 1.w,
              vertical: isTablet ? 6.0 : 5.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter Meter Number',
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 10.0 : 10.h),
                Container(
                  height: inputHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14.0 : 12.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.4),
                    borderRadius: BorderRadius.all(
                      Radius.circular(isTablet ? 12.0 : 10.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          hint: 'Meter Number',
                          keyboardType: TextInputType.number,
                          controller: _meterController,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                          onChanged: (value) {
                            _onMeterChanged(value);
                            setState(() {});
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: _meterController.text.isNotEmpty &&
                                !_isVerifying
                            ? () => _verifyMeter(_meterController.text)
                            : null,
                        child: _isVerifying
                            ? SizedBox(
                                height: isTablet ? 18.0 : 20.h,
                                width: isTablet ? 18.0 : 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : Text(
                                'Verify',
                                style: TextStyle(
                                  color: _meterController.text.isNotEmpty
                                      ? primaryColor
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 14.0 : 14.sp,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                if (_customerName != "Invalid meter" && _minPurchaseAmount != null && _minPurchaseAmount!.isNotEmpty)
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      'Min Amount: ₦$_minPurchaseAmount',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: isTablet ? 12.5 : 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (_isVerifying)
                  Padding(
                    padding: EdgeInsets.only(top: isTablet ? 8.0 : 8.h),
                    child: Row(
                      children: [
                        SizedBox(
                          width: isTablet ? 16.0 : 14.w,
                          height: isTablet ? 16.0 : 14.h,
                          child: PulsingLogoIndicator(
                            logoPath: 'assets/svg/logo-b.png',
                            size: 40,
                            pulseColor: primaryColor,
                          ),
                        ),
                        SizedBox(width: isTablet ? 8.0 : 10.w),
                        Text(
                          "Verifying meter...",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_customerName != null)
                  Padding(
                    padding: EdgeInsets.only(top: isTablet ? 10.0 : 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 14.5 : 15.sp,
                            color: _customerName == "Invalid meter"
                                ? errorColor
                                : successColor,
                          ),
                        ),
                        if (_address != null && _address!.isNotEmpty)
                          Text(
                            _address!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isTablet ? 12.0 : 12.sp,
                            ),
                          ),
                      ],
                    ),
                  ),

                SizedBox(height: isTablet ? 10.0 : 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: isTablet ? 20.0 : 24.w,
                      height: isTablet ? 20.0 : 24.h,
                      child: Checkbox(
                        value: _saveAsBeneficiary,
                        onChanged: (v) {
                          setState(() {
                            _saveAsBeneficiary = v ?? false;
                          });
                        },
                        activeColor: primaryColor,
                      ),
                    ),
                    SizedBox(width: isTablet ? 8.0 : 8.w),
                    Text(
                      'Save as beneficiary',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: isTablet ? 13.5 : 14.sp,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                if (_saveAsBeneficiary) ...[
                  SizedBox(height: isTablet ? 8.0 : 10.h),
                  Container(
                    height: inputHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 14.0 : 12.w,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(width: 0.4),
                      borderRadius: BorderRadius.all(
                        Radius.circular(isTablet ? 12.0 : 10.r),
                      ),
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: const Color(0xFF1E293B),
                        fontSize: isTablet ? 13.5 : 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter beneficiary name (e.g. My Meter)',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        counterText: "",
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
                SizedBox(height: isTablet ? 18.0 : 20.h),
                Text(
                  'Amount',
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 10.0 : 10.h),
                Container(
                  height: inputHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14.0 : 12.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.4),
                    borderRadius: BorderRadius.all(
                      Radius.circular(isTablet ? 12.0 : 10.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          hint: 'Amount',
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final amount = int.tryParse(value) ?? 0;
                            _validateAmount(amount);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 12.0 : 12.h),
                Wrap(
                  spacing: isTablet ? 8.0 : 10.w,
                  runSpacing: isTablet ? 8.0 : 10.h,
                  children: [200, 500, 1000, 2000, 3000, 5000, 10000, 20000].map((presetAmount) {
                    double minAmount = 0;
                    if (_minPurchaseAmount != null && _minPurchaseAmount!.isNotEmpty) {
                      minAmount = double.tryParse(_minPurchaseAmount!) ?? 0;
                    }
                    final isEnabled = presetAmount >= minAmount;

                    return GestureDetector(
                      onTap: isEnabled
                          ? () {
                              _amountController.text = presetAmount.toString();
                              _validateAmount(presetAmount);
                              setState(() {});
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 12.0 : 16.w,
                          vertical: isTablet ? 6.0 : 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isEnabled ? Colors.white : Colors.grey.shade200,
                          border: Border.all(
                            color: isEnabled ? primaryColor : Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 8.0 : 8.r),
                        ),
                        child: Text(
                          '₦$presetAmount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isEnabled ? primaryColor : Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 13.0 : 12.sp,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (showMinimumAmountWarning)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, left: 4.w),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: errorColor, size: 16.sp),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            "Minimum amount is ₦${_minPurchaseAmount ?? '0'}",
                            style: TextStyle(
                              color: errorColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 12.sp : 11.sp,
                            ),
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
                        Icon(
                          Icons.error_outline,
                          color: errorColor,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            "Insufficient balance. Your balance is ₦${NumberFormat('#,##0.00').format(walletBalance)}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: errorColor,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 12.sp : 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: isTablet ? 32.h : 20.h),
                SizedBox(
                  height: buttonHeight,
                  child: CustomButton(
                    buttonName: 'PAY',
                    buttonColor: _isFormValid
                        ? Colors.lightBlueAccent
                        : Colors.grey, // 👈 disabled color
                    buttonTextColor: Colors.white,
                    //fontSize: isTablet ? 18.sp : 16.sp,
                    onPressed: _isFormValid
                        ? () async {
                            final serviceId =
                                widget.selectedProvider?['serviceID'];
                            final meter = _meterController.text.trim();
                            final amountText = _amountController.text.trim();

                            if (serviceId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Select provider"),
                                ),
                              );
                              return;
                            }

                            if (meter.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Enter meter number"),
                                ),
                              );
                              return;
                            }

                            if (_customerName == null ||
                                _customerName == "Invalid meter") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Invalid meter")),
                              );
                              return;
                            }

                            if (amountText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Enter amount")),
                              );
                              return;
                            }

                            final amount = int.tryParse(amountText) ?? 0;

                            /// 🚫 BLOCK HERE
                            final balance = _getWalletBalance();

                            if (amount > balance) {
                              setState(() {
                                showInsufficientFundsWarning = true;
                                walletBalance = balance;
                              });
                              return;
                            }

                            /// ✅ ONLY REACH HERE IF VALID
                            // Resolve cashback dynamically (await future to ensure completed fetch)
                            final cashbackRule = await ref
                                .read(billCashbackProvider('ELECTRICITY').future)
                                .catchError((_) => null);
                            final cashbackLabel = cashbackRule?.displayLabel(
                                transactionAmount: amount.toDouble());
                            final hasCashback =
                                cashbackLabel != null && cashbackLabel.isNotEmpty;

                            if (!mounted) return;

                            ConfirmationBottomSheet.show(
                              context: context,
                              config: BottomSheetConfig(
                                title: "Confirm Electricity",
                                subtitle: "electricity",
                                amount: amount.toDouble(),
                                showCashback: hasCashback,
                                cashbackAmount: hasCashback ? cashbackLabel : null,
                                details: [
                                  BottomSheetDetailItem(
                                    label: "Provider",
                                    value:
                                        widget.selectedProvider?['name'] ?? "",
                                  ),
                                  BottomSheetDetailItem(
                                    label: "Meter Number",
                                    value: meter,
                                  ),
                                  BottomSheetDetailItem(
                                    label: "Customer",
                                    value: _customerName ?? "",
                                    isHighlighted: true,
                                  ),
                                  BottomSheetDetailItem(
                                    label: "Amount",
                                    value: "₦$amount",
                                  ),
                                  BottomSheetDetailItem(
                                    label: "serviceId",
                                    value: serviceId,
                                  ),
                                  BottomSheetDetailItem(
                                    label: "variationCode",
                                    value: "prepaid",
                                  ),
                                ],
                              ),
                              onConfirm: (pin) async {
                                final authBox = Hive.box('authBox');
                                final phone = authBox.get('phone', defaultValue: '');
                                final providerName = widget.selectedProvider?['name']?.toString().toLowerCase() ?? "";
                                final variationCode = providerName.contains("postpaid") ? "postpaid" : "prepaid";

                                LoadingHelper.show('');
                                
                                final controller = ref.read(dashboardControllerProvider.notifier);
                                
                                final response = await controller.buyElectricity(
                                  context,
                                  serviceId: serviceId.toString(),
                                  meterNumber: meter,
                                  variationCode: variationCode,
                                  amount: amount,
                                  phone: phone,
                                  pin: pin,
                                  saveBeneficiary: _saveAsBeneficiary,
                                  beneficiaryName: _nameController.text.trim(),
                                );
                                
                                LoadingHelper.dismiss();

                                if (!context.mounted) return;

                                  if (response != null && response.responseSuccessful) {
                                    ref.invalidate(billBeneficiariesProvider('ELECTRICITY'));
                                    context.goNamed(
                                      RouteList.successScreen,
                                      extra: {
                                        "type": "success",
                                        "amount": amount.toString(),
                                        "recipientName": widget.selectedProvider?['name'] ?? '',
                                        "recipientAccount": meter,
                                        "reference": response.responseBody?.reference ?? '',
                                        "channel": "Electricity",
                                        "token": response.responseBody?.token ?? '',
                                        "meterName": _customerName ?? '',
                                        "address": _address ?? '',
                                        "serviceType": "ELECTRICITY_BILL",
                                      },
                                    );
                                  } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response?.responseMessage ?? "Transaction failed"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            );
                          }
                        : null,
                  ),
                ),
                SizedBox(height: 20.h),
                _ElectricityBeneficiarySection(
                  onSelect: (name, account) {
                    _meterController.text = account;
                    _verifyMeter(account);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CardTwo extends ConsumerStatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onChanged;

  const CardTwo({super.key, this.onChanged});

  @override
  ConsumerState<CardTwo> createState() => _CardTwoState();
}

class _CardTwoState extends ConsumerState<CardTwo> {
  Map<String, dynamic>? _selectedProvider;
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final isDesktop = constraints.maxWidth >= 1200;

        final cardPadding = isDesktop
            ? EdgeInsets.symmetric(horizontal: 48.w, vertical: 28.h)
            : (isTablet
                  ? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0)
                  : EdgeInsets.symmetric(horizontal: 20.w, vertical: 19.h));

        final fontSize = isDesktop ? 16.0 : (isTablet ? 13.5 : 14.sp);
        final titleFontSize = isDesktop ? 18.0 : (isTablet ? 15.0 : 16.sp);

        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 16.0 : 15.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Service Provider',
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isTablet ? 10.0 : 10.h),
              NetworkDropdown(
                fontSize: fontSize,
                onChanged: (provider) {
                  setState(() => _selectedProvider = provider);
                  widget.onChanged?.call(provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class NetworkDropdown extends ConsumerStatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final ValueChanged<String>? onPhoneChanged;
  final double? fontSize;

  const NetworkDropdown({
    super.key,
    this.onChanged,
    this.onPhoneChanged,
    this.fontSize,
  });

  @override
  ConsumerState<NetworkDropdown> createState() => _NetworkDropdownState();
}

class _NetworkDropdownState extends ConsumerState<NetworkDropdown> {
  Map<String, dynamic>? _selectedProvider;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final fontSize = widget.fontSize ?? (isTablet ? 13.5 : 14.sp);
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final providersAsync = ref.watch(electricityProviderListProvider);

        // 🔥 Handle loading states with LoadingHelper
        providersAsync.when(
          loading: () => LoadingHelper.show('Loading providers...'),
          error: (_, __) => LoadingHelper.dismiss(),
          data: (_) => LoadingHelper.dismiss(),
        );

        return providersAsync.when(
          loading: () => const SizedBox.shrink(), // Empty while loading
          error: (err, _) => Text(
            "Error loading providers",
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: fontSize),
          ),
          data: (providers) {
            if (providers.isEmpty) {
              return Text(
                "No providers available",
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: fontSize),
              );
            }

            if (_selectedProvider == null ||
                !providers.contains(_selectedProvider)) {
              _selectedProvider = providers.first;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onChanged?.call(_selectedProvider!);
              });
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;

                return Container(
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 14.0 : 12.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      value: _selectedProvider,
                      menuMaxHeight: isTablet ? 320.0 : 300.h,
                      borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: fontSize,
                      ),
                      items: providers.map((provider) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: provider,
                          child: Text(
                            provider['name'],
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: transparentBlack87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedProvider = value);
                        widget.onChanged?.call(value);
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }
}

class _ElectricityBeneficiarySection extends ConsumerWidget {
  final void Function(String name, String account) onSelect;

  const _ElectricityBeneficiarySection({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiariesAsync = ref.watch(billBeneficiariesProvider('ELECTRICITY'));
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline_rounded, color: primaryColor, size: isTablet ? 18.0 : 15.sp),
            SizedBox(width: isTablet ? 6.0 : 6.w),
            Text(
              'Select Beneficiary',
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: isTablet ? 15.0 : 14.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 10.0 : 12.h),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 260.h,
            minHeight: 140.h,
          ),
          child: beneficiariesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading: $err')),
            data: (data) {
              final recents = data?.recent.map((e) => {
                "name": e.destination,
                "account": e.destination,
              }).toList() ?? [];

              return BeneficiaryTabSection(
                favorites: const [],
                recents: recents,
                onSelectBeneficiary: onSelect,
                onSearchTap: () => debugPrint('Search tapped'),
                showProgress: false,
                showLogo: true,
              );
            },
          ),
        ),
      ],
    );
  }
}


