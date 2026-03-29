import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../../../app/utils/custom_loader.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/utils/widgets/toast_helper.dart';
import '../../../../../app/view/widget/custom_textfiels_with_contact.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/transaction.dart';

class Data extends ConsumerStatefulWidget {
  const Data({super.key});
  static const String routeName = '/data';

  @override
  ConsumerState<Data> createState() => _DataState();
}

class _DataState extends ConsumerState<Data> with RouteAware {
  Map<String, dynamic>? _selectedProvider;
  String _phoneNumber = '';
  Map<String, dynamic>? _selectedPlan;

  void _handlePlanSelected(Map<String, dynamic> plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  // Helper to determine device type based on screen width
  bool _isTablet(double width) => width > 600;
  bool _isDesktop(double width) => width > 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Data',
        onBackPressed: () async {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          // Check if context is still valid before using it
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
            final screenWidth = constraints.maxWidth;
            final isTablet = _isTablet(screenWidth);
            final isDesktop = _isDesktop(screenWidth);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: isDesktop ? 800 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32.w : 20.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardTwo(
                        onProviderChanged: (provider) {
                          setState(() => _selectedProvider = provider);
                        },
                        onPhoneChanged: (phone) {
                          setState(() => _phoneNumber = phone);
                        },
                      ),
                      SizedBox(height: isTablet ? 24.h : 20.h),
                      CardOne(
                        selectedProvider: _selectedProvider,
                        phoneNumber: _phoneNumber,
                        selectedPlan: _selectedPlan,
                        onPlanSelected: _handlePlanSelected,
                        isTablet: isTablet,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: isTablet ? 24.h : 20.h),
                      CardThree(isTablet: isTablet),
                      SizedBox(height: isTablet ? 24.h : 20.h),
                      _buildDataServiceSection(context, isTablet, screenWidth),
                      SizedBox(height: 25.h),
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

  Widget _buildDataServiceSection(BuildContext context, bool isTablet, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 20 : 17,
        horizontal: isTablet ? 16 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Data Service',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 16.sp : 14.sp,
            ),
          ),
          SizedBox(height: isTablet ? 12.h : 10.h),
          // Fixed: Use SizedBox with calculated height instead of LayoutBuilder inside IntrinsicHeight
          SizedBox(
            height: isTablet ? 200.h : 180.h,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 10 : 8,
                horizontal: 0,
              ),
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: dataPlans.length,
              itemBuilder: (context, index) {
                final tx = dataPlans[index];
                final itemHeight = isTablet ? 80.h : 70.h;

                return Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 10 : 8,
                    horizontal: isTablet ? 20 : 18,
                  ),
                  margin: EdgeInsets.symmetric(
                    vertical: isTablet ? 8 : 6,
                    horizontal: isTablet ? 10 : 7,
                  ),
                  height: itemHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: isTablet ? 40.h : 35.h,
                        width: isTablet ? 40.w : 35.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Image.asset(
                          'assets/svg/bank.png',
                          height: isTablet ? 24.h : 20.h,
                        ),
                      ),
                      SizedBox(width: isTablet ? 18.h : 15.h),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: isTablet ? 16.sp : 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tx.dateTime,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: isTablet ? 12.sp : 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_outlined,
                        size: isTablet ? 14.sp : 12.sp,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── CARD ONE ───
class CardOne extends ConsumerStatefulWidget {
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;
  final Map<String, dynamic>? selectedPlan;
  final Function(Map<String, dynamic>)? onPlanSelected;
  final bool isTablet;
  final double screenWidth;

  const CardOne({
    super.key,
    this.selectedProvider,
    this.phoneNumber,
    this.selectedPlan,
    this.onPlanSelected,
    this.isTablet = false,
    required this.screenWidth,
  });

  @override
  ConsumerState<CardOne> createState() => _CardOneState();
}

class _CardOneState extends ConsumerState<CardOne> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void didUpdateWidget(covariant CardOne oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlan != null && widget.selectedPlan != oldWidget.selectedPlan) {
      _amountController.text = widget.selectedPlan!['price'].toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getServiceId(String providerName) {
    final map = {
      'MTN': 'mtn-data',
      'Airtel': 'airtel-data',
      'Glo': 'glo-data',
      '9mobile': 'etisalat-data',
    };
    return map[providerName] ?? 'mtn-data';
  }

  Future<void> _handlePurchase() async {

    if (widget.selectedProvider == null) {
      ToastHelper.showToast(
        context: context,
        message: "Please select a network provider",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return;
    }

    if (widget.phoneNumber == null || widget.phoneNumber!.length < 11) {
      ToastHelper.showToast(
        context: context,
        message: "Please enter a valid 11-digit phone number",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      ToastHelper.showToast(
        context: context,
        message: "Please enter a valid amount",
        icon: Icons.error,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return;
    }

    final provider = widget.selectedProvider!;
    final phone = widget.phoneNumber!;

    final serviceId = _getServiceId(provider['name']);
    String variationCode;
    if (widget.selectedPlan != null &&
        widget.selectedPlan!['variation_code'] != null) {
      variationCode = widget.selectedPlan!['variation_code'];
    } else {
      variationCode = '$serviceId-${amount}mb-$amount';
    }

    ConfirmationBottomSheet.show(
      context: context,
      config: BottomSheetConfig(
        title: '${Constants.nairaCurrencySymbol}$amount.00',
        subtitle: 'Confirm Data Purchase',
        showCashback: true,
        amount: amount.toDouble(),
        cashbackAmount: '+${Constants.nairaCurrencySymbol}1 Cashback',
        details: [
          BottomSheetDetailItem(
            label: 'Network',
            value: provider['name'],
            logo: provider['logo'],
          ),
          BottomSheetDetailItem(
            label: 'Phone Number',
            value: phone,
          ),
          BottomSheetDetailItem(
            label: 'Amount',
            value: '${Constants.nairaCurrencySymbol}$amount.00',
          ),
          BottomSheetDetailItem(
            label: 'Variation Code',
            value: variationCode,
          ),
        ],
      ),
      onConfirm: (pin) async {
        if (pin.length != 4) {
          ToastHelper.showToast(
            context: context,
            message: "PIN must be 4 digits",
            icon: Icons.error,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
          return;
        }

        EasyLoading.show(
          indicator: const CustomLoader(),
          maskType: EasyLoadingMaskType.black,
          dismissOnTap: false,
        );

        final response = await ref
            .read(dashboardControllerProvider.notifier)
            .buyData(
          context,
          phone: phone,
          serviceId: serviceId,
          variationCode: variationCode,
          amount: amount,
          pin: pin,
        );

        EasyLoading.dismiss();

        if (response == null) {
          ToastHelper.showToast(
            context: context,
            message: "No response from server. Please try again.",
            icon: Icons.error,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
          return;
        }

        if (response.responseSuccessful == true) {
          if (context.mounted) {
            context.goNamed(
              RouteList.successScreen,
              extra: {
                "type": "success",
                "amount": amount.toString(),
                "recipientName": provider['name'] ?? 'Unknown',
                "recipientAccount": phone,
                "reference": response.responseBody?.reference ?? '',
                "channel": "Data Purchase",
                "date": DateTime.now().toIso8601String(),
              },
            );
          }
        } else if (response.responseMessage?.toLowerCase().contains("pending") == true) {
          if (context.mounted) {
            context.goNamed(
              RouteList.successScreen,
              extra: {
                "type": "pending",
                "amount": amount.toString(),
                "recipientName": provider['name'] ?? 'Unknown',
                "recipientAccount": phone,
                "reference": response.responseBody?.reference ?? '',
                "channel": "Data Purchase",
                "date": DateTime.now().toIso8601String(),
                "message": response.responseMessage ?? "Transaction is pending",
              },
            );
          }
        } else if (response.responseMessage?.toLowerCase().contains("insufficient") == true) {
          ToastHelper.showToast(
            context: context,
            message: "Insufficient wallet balance. Please fund your wallet.",
            icon: Icons.account_balance_wallet,
            iconColor: pendingColor,
            position: ToastPosition.top,
          );
        } else if (response.statusCode == 401) {
          ToastHelper.showToast(
            context: context,
            message: "Session expired. Please login again.",
            icon: Icons.lock,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
        } else {
          if (context.mounted) {
            context.goNamed(
              RouteList.successScreen,
              extra: {
                "type": "failed",
                "amount": amount.toString(),
                "recipientName": provider['name'] ?? 'Unknown',
                "recipientAccount": phone,
                "reference": response.responseBody?.reference ?? '',
                "channel": "Data Purchase",
                "date": DateTime.now().toIso8601String(),
                "message": response.responseMessage ?? "Transaction failed",
              },
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 20 : 17,
        horizontal: isTablet ? 30 : 25,
      ),
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.all(Radius.circular(15.r)),
        boxShadow: [
          BoxShadow(
            color: darkBackground.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 18.sp : null,
            ),
          ),
          SizedBox(height: isTablet ? 12.h : 10.h),
          Row(
            children: [
              Expanded(
                flex: isTablet ? 6 : 5,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: grey300),
                    borderRadius: BorderRadius.all(Radius.circular(10.r)),
                  ),
                  child: CustomTextField(
                    hint: 'Amount',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12.w : 10.w),
              SizedBox(
                width: isTablet ? 100.w : 80.w,
                height: isTablet ? 52.h : 48.h,
                child: CustomButton(
                  buttonName: 'PAY',
                  buttonColor: primaryColor,
                  buttonTextColor: lightBackground,
                  onPressed: _handlePurchase,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 18.h : 15.h),
          DataAmountSelector(
            selectedProvider: widget.selectedProvider,
            phoneNumber: widget.phoneNumber ?? '',
            onPlanSelected: widget.onPlanSelected,
            isTablet: isTablet,
            screenWidth: widget.screenWidth,
          ),
        ],
      ),
    );
  }
}

/// ─── RESPONSIVE BOTTOM SHEET WITH PIN ───
void showDataConfirmationSheet(
    BuildContext context, {
      required int amount,
      required String networkName,
      required String networkLogo,
      required String recipientNumber,
      required Function(String pin) onConfirm,
    }) {
  final currencySymbol = Constants.nairaCurrencySymbol;
  final pinController = TextEditingController();
  final ValueNotifier<bool> useCashback = ValueNotifier<bool>(false);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: transparent,
    builder: (BuildContext modalContext) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isTablet = screenWidth > 600;
          final maxWidth = isTablet ? 500.0 : double.infinity;

          return AnimatedPadding(
            padding: MediaQuery.of(modalContext).viewInsets,
            duration: const Duration(milliseconds: 100),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.w : 24.w,
                  vertical: isTablet ? 28.h : 24.h,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: grey300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: isTablet ? 28.h : 24.h),

                      // Amount
                      Text(
                        '$currencySymbol$amount.00',
                        style: TextStyle(
                          fontSize: isTablet ? 28.sp : 25.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Confirm Payment',
                        style: TextStyle(
                          fontSize: isTablet ? 14.sp : 12.sp,
                          color: grey600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 28.h : 24.h),

                      // Details Card
                      _buildDetailsCard(
                        modalContext,
                        networkName: networkName,
                        networkLogo: networkLogo,
                        recipientNumber: recipientNumber,
                        amount: amount,
                        currencySymbol: currencySymbol,
                        useCashback: useCashback,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: isTablet ? 28.h : 24.h),

                      // PIN Input - Responsive sizing
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 80.w : 60.w,
                        ),
                        child: PinCodeTextField(
                          length: 4,
                          controller: pinController,
                          obscureText: true,
                          appContext: modalContext,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(10.r),
                            fieldHeight: isTablet ? 45.h : 35.h,
                            fieldWidth: isTablet ? 45.h : 35.h,
                            inactiveColor: grey300,
                            activeColor: primaryColor,
                            selectedColor: primaryColor,
                            activeFillColor: lightBackground,
                            inactiveFillColor: lightBackground,
                            selectedFillColor: lightBackground,
                          ),
                          animationType: AnimationType.fade,
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          keyboardType: TextInputType.number,
                          onCompleted: (code) {
                            if (pinController.text.length == 4) {
                              onConfirm(pinController.text);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: isTablet ? 20.h : 16.h),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

double _getWalletBalance() {
  final box = Hive.box('authBox');
  final balanceStr = box.get('balance', defaultValue: '0').toString();
  return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
}

Widget _buildDetailsCard(
    BuildContext context, {
      required String networkName,
      required String networkLogo,
      required String recipientNumber,
      required int amount,
      required String currencySymbol,
      required ValueNotifier<bool> useCashback,
      bool isTablet = false,
    }) {
  return Container(
    padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
    decoration: BoxDecoration(
      color: grey50,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: grey200),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDetailRow(
          context,
          label: 'Network',
          value: networkName,
          logo: networkLogo,
          isTablet: isTablet,
        ),
        Divider(height: isTablet ? 28.h : 24.h, color: grey300),
        _buildDetailRow(
          context,
          label: 'Phone Number',
          value: recipientNumber,
          isTablet: isTablet,
        ),
        Divider(height: isTablet ? 28.h : 24.h, color: grey300),
        _buildDetailRow(
          context,
          label: 'Amount',
          value: '$currencySymbol$amount.00',
          isTablet: isTablet,
        ),

        // Cashback bonus row
        Divider(height: isTablet ? 28.h : 24.h, color: grey300),
        _buildCashbackBonusRow(
          context,
          '+${currencySymbol}1 Cashback',
          isTablet: isTablet,
        ),

        // Cashback toggle row
        ValueListenableBuilder<bool>(
          valueListenable: useCashback,
          builder: (context, isUsing, child) {
            return _buildSummaryRow(
              context,
              'Use Cashback (${currencySymbol}34.00)',
              '-${currencySymbol}34.00',
              hasToggle: true,
              isToggled: isUsing,
              onToggle: (value) => useCashback.value = value,
              isTablet: isTablet,
            );
          },
        ),

        // Wallet balance row
        Divider(height: isTablet ? 28.h : 24.h, color: grey300),
        _buildWalletBalanceRow(
          context,
          balance: _getWalletBalance().toStringAsFixed(2),
          currencySymbol: currencySymbol,
          isTablet: isTablet,
        ),
      ],
    ),
  );
}

Widget _buildCashbackBonusRow(BuildContext context, String value, {bool isTablet = false}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: isTablet ? 8.h : 6.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox.shrink(),
        Text(
          value,
          style: TextStyle(
            color: primaryGreenColor600,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 13.sp : 11.sp,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(
    BuildContext context, {
      required String label,
      required String value,
      String? logo,
      bool isTablet = false,
    }) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: grey600,
          fontSize: isTablet ? 13.sp : 11.sp,
        ),
      ),
      Row(
        children: [
          if (logo != null)
            Container(
              width: isTablet ? 24.w : 20.w,
              height: isTablet ? 24.h : 20.h,
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(logo),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Text(
            value,
            style: TextStyle(
              color: transparentBlack87,
              fontSize: isTablet ? 13.sp : 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildSummaryRow(
    BuildContext context,
    String title,
    String value, {
      bool bonus = false,
      bool hasToggle = false,
      bool isToggled = false,
      ValueChanged<bool>? onToggle,
      bool isTablet = false,
    }) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: isTablet ? 8.h : 6.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: grey600,
            fontSize: isTablet ? 13.sp : 11.sp,
          ),
        ),
        Row(
          children: [
            if (bonus)
              Text(
                value,
                style: TextStyle(
                  color: primaryGreenColor600,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 13.sp : 11.sp,
                ),
              )
            else
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isTablet ? 13.sp : 11.sp,
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
                  width: isTablet ? 48.w : 40.w,
                  height: isTablet ? 26.h : 22.h,
                  decoration: BoxDecoration(
                    color: isToggled ? primaryColor : grey300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: isToggled ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: isTablet ? 22.w : 18.w,
                      height: isTablet ? 22.h : 18.h,
                      margin: EdgeInsets.symmetric(horizontal: 2),
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

Widget _buildWalletBalanceRow(
    BuildContext context, {
      required String balance,
      required String currencySymbol,
      bool isTablet = false,
    }) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      vertical: isTablet ? 18 : 16,
      horizontal: isTablet ? 20 : 18,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: grey300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.account_balance_wallet,
          color: primaryColor,
          size: isTablet ? 28 : 24,
        ),
        SizedBox(width: isTablet ? 12.w : 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: grey600,
                  fontSize: isTablet ? 13.sp : null,
                ),
              ),
              Text(
                '$currencySymbol$balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 16.sp : null,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: primaryColor,
          size: isTablet ? 28 : 24,
        ),
      ],
    ),
  );
}

/// ─── CARD TWO ───
class CardTwo extends StatefulWidget {
  final Function(Map<String, dynamic>)? onProviderChanged;
  final Function(String)? onPhoneChanged;

  const CardTwo({
    super.key,
    this.onProviderChanged,
    this.onPhoneChanged,
  });

  @override
  State<CardTwo> createState() => _CardTwoState();
}

class _CardTwoState extends State<CardTwo> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'MTN', 'logo': 'assets/svg/mtn.jpg', 'serviceId': 'mtn-data'},
    {'name': 'Airtel', 'logo': 'assets/svg/airtel.png', 'serviceId': 'airtel-data'},
    {'name': 'Glo', 'logo': 'assets/svg/glo.jpg', 'serviceId': 'glo-data'},
    {'name': '9mobile', 'logo': 'assets/svg/9mobile.png', 'serviceId': 'etisalat-data'},
  ];

  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onProviderChanged?.call(_selectedProvider!);
    });
  }

  void _detectNetwork(String input) {
    if (input.length < 4) return;
    final prefix = input.substring(0, 4);
    Map<String, dynamic>? detected;

    if (['0803', '0806', '0703', '0706', '0813', '0816', '0903', '0906', '0913', '0916'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'MTN', orElse: () => _providers.first);
    } else if (['0802', '0808', '0812', '0701', '0902', '0901', '0904', '0907', '0912'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'Airtel', orElse: () => _providers.first);
    } else if (['0805', '0807', '0811', '0705', '0905', '0915'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'Glo', orElse: () => _providers.first);
    } else if (['0809', '0818', '0817', '0909', '0908'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == '9mobile', orElse: () => _providers.first);
    }

    if (detected != null && detected != _selectedProvider) {
      setState(() => _selectedProvider = detected);
      widget.onProviderChanged?.call(detected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 20 : 17,
            horizontal: isTablet ? 30 : 25,
          ),
          decoration: BoxDecoration(
            color: lightBackground,
            borderRadius: BorderRadius.all(Radius.circular(15.r)),
            boxShadow: [
              BoxShadow(
                color: darkBackground.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Network',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 18.sp : null,
                ),
              ),
              SizedBox(height: isTablet ? 18.h : 15.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      padding: EdgeInsets.zero,
                      isExpanded: false,
                      alignment: Alignment.center,
                      menuMaxHeight: 250,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: lightBackground,
                      value: _selectedProvider,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: transparentBlack54,
                        size: isTablet ? 24 : 20,
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return _providers.map<Widget>((provider) {
                          return Container(
                            height: isTablet ? 48.h : 40.h,
                            width: isTablet ? 48.h : 40.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(provider['logo']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: _providers.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Row(
                            children: [
                              Container(
                                height: isTablet ? 36.h : 30.h,
                                width: isTablet ? 36.h : 30.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  image: DecorationImage(
                                    image: AssetImage(provider['logo']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                provider['name'],
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: isTablet ? 14.sp : 12.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedProvider = value);
                        widget.onProviderChanged?.call(value!);
                      },
                    ),
                  ),
                  SizedBox(width: isTablet ? 14.w : 10.w),
                  Expanded(
                    child: CustomTextFieldWithContacts(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: 'Enter phone number',
                      maxLength: 11,

                      /// 🔥 NORMAL TYPING
                      onChanged: (value) {
                        _detectNetwork(value);
                        widget.onPhoneChanged?.call(value);
                      },

                      /// 🔥 CONTACT PICK
                      onContactSelected: (phone, name) {
                        _phoneController.text = phone;

                        _detectNetwork(phone);
                        widget.onPhoneChanged?.call(phone);

                        // Optional: show who was picked
                        if (name != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected: $name'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ─── CARD THREE ───
class CardThree extends StatelessWidget {
  final bool isTablet;

  const CardThree({super.key, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 20 : 17,
        horizontal: isTablet ? 30 : 25,
      ),
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.all(Radius.circular(15.r)),
        boxShadow: [
          BoxShadow(
            color: darkBackground.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 18.sp : null,
            ),
          ),
          SizedBox(height: isTablet ? 18.h : 15.h),
          Container(
            height: isTablet ? 120.h : 100.h,
            alignment: Alignment.center,
            child: Text(
              'No recent transactions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: grey,
                fontSize: isTablet ? 16.sp : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── RESPONSIVE DATA SELECTOR ───
class DataAmountSelector extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onPlanSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;
  final bool isTablet;
  final double screenWidth;

  const DataAmountSelector({
    super.key,
    this.onPlanSelected,
    this.selectedProvider,
    this.phoneNumber,
    this.isTablet = false,
    required this.screenWidth,
  });

  @override
  ConsumerState<DataAmountSelector> createState() => _DataAmountSelectorState();
}

class _DataAmountSelectorState extends ConsumerState<DataAmountSelector>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  int? selectedAmount;
  int? selectedIndex;

  final List<String> _tabs = ['Gifting', 'Corporate', 'SME', 'Hot', 'Exclusive'];

  late final TabController _tabController;

  final Map<String, List<Map<String, dynamic>>> categorizedPlans = {
    'Gifting': [
      {'data': '110MB', 'price': 100, 'duration': '1 DAY', 'bonus': 'Facebook', 'variation_code': 'mtn-110mb-100'},
      {'data': '150MB', 'price': 200, 'duration': '1 DAY', 'bonus': 'TikTok', 'variation_code': 'mtn-150mb-200'},
      {'data': '350MB', 'price': 300, 'duration': '7 DAYS', 'bonus': 'WhatsApp', 'variation_code': 'mtn-350mb-300'},
    ],
    'Corporate': [
      {'data': '2GB', 'price': 1500, 'duration': '14 DAYS', 'bonus': 'Team', 'variation_code': 'mtn-2gb-1500'},
      {'data': '5GB', 'price': 3000, 'duration': '30 DAYS', 'bonus': 'Biz', 'variation_code': 'mtn-5gb-3000'},
    ],
    'SME': [],
    'Hot': [
      {'data': '1.5GB', 'price': 500, 'duration': '1 DAY', 'bonus': '🔥', 'variation_code': 'mtn-1.5gb-500'},
      {'data': '3GB', 'price': 1000, 'duration': '7 DAYS', 'bonus': 'Hot', 'variation_code': 'mtn-3gb-1000'},
    ],
    'Exclusive': [
      {'data': '15GB', 'price': 3500, 'duration': '30 DAYS', 'bonus': 'VIP', 'variation_code': 'mtn-15gb-3500'},
      {'data': '40GB', 'price': 10000, 'duration': '30 DAYS', 'bonus': 'Gold', 'variation_code': 'mtn-40gb-10000'},
    ],
  };

  bool isLoadingSme = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadSmePlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadSmePlans() async {
    // Add this at the start of _loadSmePlans()
    final testResult = await ref.read(dashboardControllerProvider.notifier).fetchSmePlans(context);
    if (testResult.isNotEmpty) {
      final first = testResult.first;
      // Print every property
      debugPrint('Plan object: $first');
      debugPrint('Amount: ${first.amount} (type: ${first.amount.runtimeType})');
      // If it's a custom class, check all fields
      // debugPrint('All fields: ${first.toJson()}'); // if available
    }
    try {
      final result = await ref
          .read(dashboardControllerProvider.notifier)
          .fetchSmePlans(context);

      // DEBUG: Print the raw result to see what fields are available
      if (result.isNotEmpty) {
        debugPrint('=== SME PLANS DEBUG ===');
        debugPrint('First plan type: ${result.first.runtimeType}');
        debugPrint('First plan fields: ${result.first.toString()}');
        // Try to print all available getters
        final first = result.first;
        debugPrint('amount value: ${first.amount}');
        debugPrint('amount type: ${first.amount?.runtimeType}');
      }

      if (result.isNotEmpty) {
        final formatted = result.map((plan) {
          final parsed = _parsePlan(plan.name);

          // FIXED: Robust amount parsing
          int price = _parseAmount(plan.amount);

          // If price is still 0, try to extract from plan name (e.g., "1GB - 30 Days - N1000")
          if (price == 0 && plan.name != null) {
            price = _extractPriceFromName(plan.name!);
          }

          debugPrint('SME Plan: ${plan.name} -> Parsed Price: $price');

          return {
            'data': parsed['data'],
            'price': price,
            'duration': parsed['duration'],
            'bonus': 'SME',
            'variation_code': plan.variationCode ?? '${plan.serviceId}-${price}mb-$price',
            'service_id': plan.serviceId,
          };
        }).toList();

        // Filter out plans with 0 price
        final validPlans = formatted.where((plan) => (plan['price'] as int) > 0).toList();
        debugPrint('Valid SME plans loaded: ${validPlans.length}');

        if (mounted) {
          setState(() {
            categorizedPlans['SME'] = validPlans;
            isLoadingSme = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => isLoadingSme = false);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading SME plans: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => isLoadingSme = false);
      }
    }
  }

// Helper: Parse amount from any type
  int _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount;
    if (amount is double) return amount.toInt();
    if (amount is String) {
      // Handle formats like "1000", "1,000", "₦1000", "1000.00"
      final clean = amount
          .replaceAll(',', '')
          .replaceAll('₦', '')
          .replaceAll('N', '')
          .replaceAll('\$', '')
          .trim();
      return int.tryParse(clean) ?? double.tryParse(clean)?.toInt() ?? 0;
    }
    return 0;
  }

// Helper: Extract price from plan name if amount field is empty
// Handles names like "MTN 1GB - 30 Days - N1000" or "1GB (N500)"
  int _extractPriceFromName(String name) {
    // Try to find price patterns like N1000, ₦500, N 1000, etc.
    final regExp = RegExp(r'[₦N]\s*(\d{1,6})', caseSensitive: false);
    final match = regExp.firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }

    // Try generic number at end: "1GB - 1000"
    final endNumber = RegExp(r'(\d{3,6})\s*$');
    final endMatch = endNumber.firstMatch(name);
    if (endMatch != null) {
      return int.tryParse(endMatch.group(1)!) ?? 0;
    }

    return 0;
  }
  Map<String, String> _parsePlan(String name) {
    String data = '';
    String duration = '';

    final parts = name.split(' ');
    for (var p in parts) {
      if (p.toLowerCase().contains('gb') || p.toLowerCase().contains('mb')) {
        data = p;
      }
    }

    if (name.contains('-')) {
      duration = name.split('-').last.trim();
    }

    return {
      'data': data,
      'duration': duration.isEmpty ? '30 DAYS' : duration,
    };
  }

  // Calculate responsive grid columns based on screen width
// Calculate responsive grid columns based on screen width
  int _getCrossAxisCount(double width) {
    if (width > 900) return 5;      // Desktop/large tablet
    if (width > 600) return 4;      // Tablet
    return 3;                       // ALL phones get 3 columns (no matter the size)
  }

  // Calculate responsive aspect ratio
// Calculate responsive aspect ratio
  double _getChildAspectRatio(double width) {
    if (width > 900) return 1.0;    // Desktop
    if (width > 600) return 0.9;    // Tablet
    return 0.80;                    // Phones - slightly taller for 3 columns
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;
    final screenWidth = widget.screenWidth;

    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final childAspectRatio = _getChildAspectRatio(screenWidth);

    // Dynamic height based on grid configuration
    final maxPlans = categorizedPlans.values.map((e) => e.length).fold(0, (prev, curr) => curr > prev ? curr : prev);
    final rowCount = (maxPlans / crossAxisCount).ceil().clamp(1, 3);
// OLD (might be too tall):

// NEW (more compact):
    final calculatedHeight = (screenWidth / crossAxisCount / childAspectRatio * rowCount) + 40.h;
// Force smaller height for 3-column layout
    final tabViewHeight = isTablet ? 280.h : 220.h;  // Reduced from 350/280
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor: grey,
          indicatorColor: primaryColor,
          labelStyle: TextStyle(
            fontSize: isTablet ? 14.sp : 12.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: isTablet ? 14.sp : 12.sp,
          ),
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),
        SizedBox(
          height: tabViewHeight,
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {
              if (tabName == 'SME' && isLoadingSme) {
                return const Center(child: CircularProgressIndicator());
              }

              final plans = categorizedPlans[tabName] ?? [];

              if (plans.isEmpty) {
                return Center(
                  child: Text(
                    'No plans available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: grey,
                      fontSize: isTablet ? 16.sp : null,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(isTablet ? 8 : 6),  // Reduced from 10/12
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isTablet ? 12 : 8,  // Reduced from 16/12
                  mainAxisSpacing: isTablet ? 12 : 8,   // Reduced from 16/12
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = selectedAmount == plan['price'] && selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = plan['price'];
                        selectedIndex = index;
                      });
                      widget.onPlanSelected?.call(plan);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(isTablet ? 8 : 6),  // Reduced from 10/8
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha:0.1)
                            : grey50,
                        borderRadius: BorderRadius.circular(8.r),  // Reduced from 12.r
                        border: Border.all(
                          color: isSelected ? primaryColor : transparent,
                          width: isTablet ? 1.5 : 1,  // Reduced from 2/1.5
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              plan['data'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14.sp : 12.sp,  // Reduced from 16/14
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.h : 2.h),  // Reduced from 6/4
                          Flexible(
                            child: Text(
                              "₦${plan['price']}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                                fontSize: isTablet ? 13.sp : 11.sp,  // Smaller
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.h : 2.h),  // Reduced from 6/4
                          Flexible(
                            child: Text(
                              plan['duration'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: isTablet ? 10.sp : 9.sp,  // Smaller
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.h : 2.h),  // Reduced from 6/4
                          if (plan['bonus'] != null)
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 6 : 4,  // Reduced from 8/6
                                  vertical: isTablet ? 2 : 1,   // Reduced from 4/2
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha:0.08),
                                  borderRadius: BorderRadius.circular(12),  // Reduced from 20
                                ),
                                child: Text(
                                  plan['bonus'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isTablet ? 9.sp : 7.sp,  // Reduced from 10/8
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}