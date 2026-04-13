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
import '../../../../../core/easy_loading_config.dart';
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
  bool showInsufficientFundsWarning = false;
  double walletBalance = 0.0;

  void _validateAmount(int amount) {
    final balance = _getWalletBalance();

    setState(() {
      walletBalance = balance;
      showInsufficientFundsWarning =
          amount > 0 && amount > balance;
    });
  }
  bool get _isFormValid {
    final hasProvider = widget.selectedProvider != null;
    final hasPhone = (widget.phoneNumber ?? '').length == 11;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final hasAmount = amount > 0;

    final balance = _getWalletBalance();
    final hasBalance = amount <= balance;

    return hasProvider && hasPhone && hasAmount && hasBalance;
  }

  @override
  void didUpdateWidget(covariant CardOne oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlan != null && widget.selectedPlan != oldWidget.selectedPlan) {
      _amountController.text = widget.selectedPlan!['price'].toString();
    }
    if (widget.selectedPlan != null &&
        widget.selectedPlan != oldWidget.selectedPlan) {
      final price = widget.selectedPlan!['price'];

      _amountController.text = price.toString();
      _validateAmount(price); // 🔥 THIS WAS MISSING
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
        horizontal: isTablet ? 20 : 10,
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
                    keyboardType: TextInputType.none, // 🔥 no keyboard
                    readOnly: true, // 🔥 disables typing
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12.w : 10.w),
              SizedBox(
                width: isTablet ? 100.w : 80.w,
                height: isTablet ? 52.h : 48.h,
                child: CustomButton(
                  buttonName: 'PAY',
                  buttonColor: _isFormValid ? primaryColor : grey300,
                  buttonTextColor: lightBackground,
                  onPressed: _isFormValid ? _handlePurchase : null,                ),
              ),
            ],
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
                      "Insufficient balance. Your balance is ₦${walletBalance.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith (
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 12.sp : 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
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



double _getWalletBalance() {
  final box = Hive.box('authBox');
  final balanceStr = box.get('balance', defaultValue: '0').toString();
  return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
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
            horizontal: isTablet ? 20 : 10,
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
  int? selectedAmount;
  int? selectedIndex;

  final List<String> _tabs = ['Gifting', 'Corporate', 'SME', 'Hot', 'Exclusive'];

  late final TabController _tabController;

  /// 🔥 ALL EMPTY BY DEFAULT
  final Map<String, List<Map<String, dynamic>>> categorizedPlans = {
    'Gifting': [],
    'Corporate': [],
    'SME': [],
    'Hot': [],
    'Exclusive': [],
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
    super.dispose();
  }

  /// 🔥 LOAD SME (FIXED)
  Future<void> _loadSmePlans() async {
    try {
      final result = await ref
          .read(dashboardControllerProvider.notifier)
          .fetchSmePlans(context);

      if (result.isNotEmpty) {
        final formatted = result.map((plan) {
          int price = _parseAmount(plan.amount);

          /// 🔥 FALLBACK (CRITICAL FIX)
          if (price == 0 && plan.name != null) {
            price = _extractPriceFromName(plan.name!);
          }

          return {
            'data': _extractData(plan.name ?? ''),
            'price': price,
            'duration': _extractDuration(plan.name ?? ''),
            'bonus': 'SME',
            'variation_code': plan.variationCode,
          };
        }).where((e) => (e['price'] as int) > 0).toList();

        if (mounted) {
          setState(() {
            categorizedPlans['SME'] = formatted;
            isLoadingSme = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingSme = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingSme = false);
    }
  }

  /// 🔥 PARSE AMOUNT
  int _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount;
    if (amount is double) return amount.toInt();
    if (amount is String) {
      final clean = amount
          .replaceAll(',', '')
          .replaceAll('₦', '')
          .replaceAll('N', '')
          .trim();
      return int.tryParse(clean) ?? 0;
    }
    return 0;
  }

  /// 🔥 EXTRACT PRICE FROM NAME
  int _extractPriceFromName(String name) {
    final regExp = RegExp(r'[₦N]\s*([\d,]+)');
    final match = regExp.firstMatch(name);

    if (match != null) {
      final clean = match.group(1)!.replaceAll(',', '');
      return int.tryParse(clean) ?? 0;
    }

    return 0;
  }

  /// 🔥 EXTRACT DATA (e.g 1GB, 500MB)
  String _extractData(String name) {
    final reg = RegExp(r'(\d+(\.\d+)?\s?(GB|MB))', caseSensitive: false);
    final match = reg.firstMatch(name);
    return match?.group(0) ?? '';
  }

  /// 🔥 EXTRACT DURATION
  String _extractDuration(String name) {
    final reg = RegExp(r'(\d+\s?(day|days|month|months))', caseSensitive: false);
    final match = reg.firstMatch(name);
    return match?.group(0)?.toUpperCase() ?? '30 DAYS';
  }

  int _getCrossAxisCount(double width) {
    if (width > 900) return 5;
    if (width > 600) return 4;
    return 3;
  }

  double _getChildAspectRatio(double width) {
    if (width > 900) return 1.0;
    if (width > 600) return 0.9;
    return 0.80;
  }

  /// 🔥 EMPTY STATE UI
  Widget _buildEmptyState(BuildContext context, String tabName) {
    final theme = Theme.of(context);

    String message;
    switch (tabName) {
      case 'Gifting':
        message = "Gifting plans coming soon";
        break;
      case 'Corporate':
        message = "Corporate plans coming soon";
        break;
      case 'Hot':
        message = "Hot deals coming soon";
        break;
      case 'Exclusive':
        message = "Exclusive plans coming soon";
        break;
      default:
        message = "No plans available";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 40, color: primaryColor),
          SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = widget.isTablet;
    final screenWidth = widget.screenWidth;

    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final childAspectRatio = _getChildAspectRatio(screenWidth);
    final tabViewHeight = isTablet ? 280.h : 220.h;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor: grey,
          indicatorColor: primaryColor,
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),

        SizedBox(
          height: tabViewHeight,
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {

              /// 🔥 SME LOADER
              if (tabName == 'SME' && isLoadingSme) {
                return Center(
                  child: PulsingLogoIndicator(
                    logoPath: 'assets/svg/logo.png',
                    size: 40,
                    pulseColor: primaryColor,
                  ),
                );
              }

              final plans = categorizedPlans[tabName] ?? [];

              /// 🔥 EMPTY STATE
              if (plans.isEmpty) {
                return _buildEmptyState(context, tabName);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected =
                      selectedAmount == plan['price'] && selectedIndex == index;

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
                      padding: EdgeInsets.all(isTablet ? 8 : 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.1)
                            : grey50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected ? primaryColor : transparent,
                          width: isTablet ? 1.5 : 1,
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14.sp : 12.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.h : 2.h),
                          Flexible(
                            child: Text(
                              "₦${plan['price']}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                                fontSize: isTablet ? 13.sp : 11.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.h : 2.h),
                          Flexible(
                            child: Text(
                              plan['duration'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: isTablet ? 10.sp : 9.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 4.h : 2.h),
                          if (plan['bonus'] != null)
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 6 : 4,
                                  vertical: isTablet ? 2 : 1,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  plan['bonus'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isTablet ? 9.sp : 7.sp,
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
