import 'dart:async';

import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

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
import '../../../model/recent_transaction.dart';
import '../../../widgets/transaction.dart';
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
              child: SvgPicture.asset(bell),
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
                              vertical: isTablet ? 24.h : 17.h,
                              horizontal: isTablet ? 20.w : 10.w,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(isTablet ? 20.r : 15.r),
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
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 18.sp : 16.sp,
                                      ),
                                ),
                                SizedBox(height: isTablet ? 16.h : 10.h),
                                ...dataPlans
                                    .map(
                                      (tx) => Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 12.h : 8.h,
                                          horizontal: isTablet ? 24.w : 18.w,
                                        ),
                                        margin: EdgeInsets.symmetric(
                                          vertical: isTablet ? 8.h : 6.h,
                                          horizontal: isTablet ? 10.w : 7.w,
                                        ),
                                        height: isTablet ? 85.h : 70.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            isTablet ? 12.r : 8.r,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: isTablet ? 45.h : 35.h,
                                              width: isTablet ? 45.w : 35.w,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                border: Border.all(),
                                              ),
                                              child: Image.asset(
                                                'assets/svg/bank.png',
                                                height: isTablet ? 28.h : 20.h,
                                              ),
                                            ),
                                            SizedBox(
                                              width: isTablet ? 20.w : 15.w,
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
                                                              ? 17.sp
                                                              : 15.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  Text(
                                                    tx.dateTime,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          fontSize: isTablet
                                                              ? 13.sp
                                                              : 11.sp,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_outlined,
                                              size: isTablet ? 16.sp : 12.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 32.h : 25.h),
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

class CardOne extends StatefulWidget {
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
  State<CardOne> createState() => _CardOneState();
}

class _CardOneState extends State<CardOne> {
  Map<String, dynamic>? _selectedProvider;
  String _phoneNumber = '';
  Timer? _debounce;
  String? _customerName;
  String? _address;
  String? _minPurchaseAmount;
  bool _isVerifying = false;

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

  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final isDesktop = constraints.maxWidth >= 1200;

        final cardPadding = isDesktop
            ? EdgeInsets.symmetric(vertical: 22.h, horizontal: 48.w)
            : (isTablet
                  ? EdgeInsets.symmetric(vertical: 14.h, horizontal: 32.w)
                  : EdgeInsets.symmetric(vertical: 7.h, horizontal: 25.w));

        final fontSize = isDesktop ? 18.sp : (isTablet ? 16.sp : 14.sp);
        final titleFontSize = isDesktop ? 20.sp : (isTablet ? 18.sp : 16.sp);
        final inputHeight = isDesktop ? 70.h : (isTablet ? 60.h : 50.h);
        final buttonHeight = isDesktop ? 65.h : (isTablet ? 60.h : 55.h);
        final theme = Theme.of(context);

        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(isTablet ? 20.r : 15.r),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 2.w : 1.w,
              vertical: isTablet ? 10.h : 5.h,
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
                  ),
                ),
                SizedBox(height: isTablet ? 16.h : 10.h),
                Container(
                  height: inputHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16.w : 12.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.4),
                    borderRadius: BorderRadius.all(
                      Radius.circular(isTablet ? 14.r : 10.r),
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
                                .digitsOnly, // 👈 numbers only
                          ],

                          //fontSize: fontSize,
                          onChanged: (value) {
                            _onMeterChanged(value);
                            setState(() {}); // 👈 ADD THIS
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
                                height: 20.h,
                                width: 20.w,
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
                                  fontSize: isTablet ? 16.sp : 14.sp,
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
                        fontSize: isTablet ? 14.sp : 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (_isVerifying)
                  Padding(
                    padding: EdgeInsets.only(top: isTablet ? 12.h : 8.h),
                    child: Row(
                      children: [
                        SizedBox(
                          width: isTablet ? 18.w : 14.w,
                          height: isTablet ? 18.h : 14.h,
                          child:   PulsingLogoIndicator(
                            logoPath: 'assets/svg/logo-b.png', // 🔥 your logo
                            size: 40,
                            pulseColor: primaryColor,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12.w : 10.w),
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
                    padding: EdgeInsets.only(top: isTablet ? 14.h : 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 17.sp : 15.sp,
                            color: _customerName == "Invalid meter"
                                ? errorColor
                                : successColor,
                          ),
                        ),
                        if (_address != null && _address!.isNotEmpty)
                          Text(
                            _address!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: isTablet ? 14.sp : 12.sp,
                            ),
                          ),

                      ],
                    ),
                  ),

                SizedBox(height: isTablet ? 28.h : 20.h),
                Text(
                  'Amount',
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: titleFontSize,
                  ),
                ),
                SizedBox(height: isTablet ? 16.h : 10.h),
                Container(
                  height: inputHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16.w : 12.w,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.4),
                    borderRadius: BorderRadius.all(
                      Radius.circular(isTablet ? 14.r : 10.r),
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
                            setState(() {}); // 👈 ADD THIS
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 16.h : 12.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
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
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isEnabled ? Colors.white : Colors.grey.shade200,
                          border: Border.all(
                            color: isEnabled ? primaryColor : Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '₦$presetAmount',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isEnabled ? primaryColor : Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 14.sp : 12.sp,
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
                            "Insufficient balance. Your balance is ₦${walletBalance.toStringAsFixed(2)}",
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
                        ? () {
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
                            ConfirmationBottomSheet.show(
                              context: context,
                              config: BottomSheetConfig(
                                title: "Confirm Electricity",
                                subtitle: "electricity",
                                amount: amount.toDouble(),
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
                                
                                final controller = ProviderScope.containerOf(context).read(dashboardControllerProvider.notifier);
                                
                                final response = await controller.buyElectricity(
                                  context,
                                  serviceId: serviceId.toString(),
                                  meterNumber: meter,
                                  variationCode: variationCode,
                                  amount: amount,
                                  phone: phone,
                                  pin: pin,
                                );
                                
                                LoadingHelper.dismiss();

                                if (!context.mounted) return;

                                if (response != null && response.responseSuccessful) {
                                  // Construct a TransactionItem to pass to the details screen
                                  final transaction = TransactionItem(
                                    id: response.responseBody?.transactionId ?? 0,
                                    amount: amount.toDouble(),
                                    isCredit: false,
                                    serviceType: 'ELECTRICITY_BILL',
                                    provider: widget.selectedProvider?['name'],
                                    status: 'SUCCESSFUL',
                                    reference: response.responseBody?.reference,
                                    createdAt: DateTime.now(),
                                    metadata: {
                                      'info': {
                                        'meterNumber': meter,
                                        'Customer_Name': _customerName,
                                        'address': _address,
                                        'token': response.responseBody?.token, // Recharge token
                                        'provider': widget.selectedProvider?['name'],
                                      }
                                    },
                                  );

                                  context.push(
                                    RouteList.transactionDetailsScreen,
                                    extra: transaction,
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
                  ? EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h)
                  : EdgeInsets.symmetric(horizontal: 20.w, vertical: 19.h));

        final fontSize = isDesktop ? 18.sp : (isTablet ? 16.sp : 14.sp);
        final titleFontSize = isDesktop ? 20.sp : (isTablet ? 18.sp : 16.sp);

        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 20.r : 15.r),
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
                ),
              ),
              SizedBox(height: isTablet ? 16.h : 10.h),
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
    final fontSize = widget.fontSize ?? 14.sp;
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
                    borderRadius: BorderRadius.circular(isTablet ? 14.r : 10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.w : 12.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      value: _selectedProvider,
                      menuMaxHeight: isTablet ? 400.h : 300.h,
                      borderRadius: BorderRadius.circular(isTablet ? 14.r : 10.r),
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


