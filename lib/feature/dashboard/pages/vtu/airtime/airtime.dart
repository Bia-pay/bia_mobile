import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/custom_textfiels_with_contact.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../send_money/widget/tabs.dart';

// ==================== RESPONSIVE HELPERS ====================

class ResponsiveConfig {
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide > 600;

  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.w;
    if (width > 600) return 24.w;
    return 16.w;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 320) return 3;
    if (width < 400) return 4;
    if (width > 600) return 6;
    return 4;
  }
}

// ==================== STATE PROVIDERS ====================

final airtimeFormProvider =
    StateNotifierProvider<AirtimeFormNotifier, AirtimeFormState>((ref) {
      return AirtimeFormNotifier();
    });

class AirtimeFormState {
  final Map<String, dynamic>? selectedProvider;
  final String phoneNumber;
  final int? amount;
  final bool isLoading;
  final String? error;

  const AirtimeFormState({
    this.selectedProvider,
    this.phoneNumber = '',
    this.amount,
    this.isLoading = false,
    this.error,
  });

  AirtimeFormState copyWith({
    Map<String, dynamic>? selectedProvider,
    String? phoneNumber,
    int? amount,
    bool? isLoading,
    String? error,
  }) {
    return AirtimeFormState(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isValid =>
      phoneNumber.length >= 10 &&
      amount != null &&
      amount! >= 50 &&
      selectedProvider != null;
}

class AirtimeFormNotifier extends StateNotifier<AirtimeFormState> {
  AirtimeFormNotifier() : super(const AirtimeFormState());

  void setProvider(Map<String, dynamic> provider) {
    state = state.copyWith(selectedProvider: provider);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void setAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clear() {
    state = const AirtimeFormState();
  }
}

// ==================== MAIN SCREEN ====================

class Airtime extends ConsumerStatefulWidget {
  const Airtime({super.key});

  @override
  ConsumerState<Airtime> createState() => _AirtimeState();
}

class _AirtimeState extends ConsumerState<Airtime> {
  @override
  void initState() {
    super.initState();
    // Clear state on load to avoid stale values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(airtimeFormProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveConfig.isTablet(context);
    final padding = ResponsiveConfig.getPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Airtime',
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
            padding: EdgeInsets.only(right: padding),
            child: SvgPicture.asset(
              bell,
              width: isTablet ? 28.w : 24.w,
              height: isTablet ? 28.h : 24.h,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTwo().animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
        SizedBox(height: 16.h),
        const CardOne().animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.05),
        SizedBox(height: 16.h),
       // const CardThree().animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              const CardTwo(),
              SizedBox(height: 20.h),
              const CardOne(),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        // const Expanded(
        //   flex: 4,
        //   child: CardThree(),
        // ),
      ],
    );
  }
}

// ==================== CARD TWO: NETWORK & PHONE ====================

class CardTwo extends ConsumerStatefulWidget {
  const CardTwo({super.key});

  @override
  ConsumerState<CardTwo> createState() => _CardTwoState();
}

class _CardTwoState extends ConsumerState<CardTwo> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'MTN', 'logo': 'assets/svg/mtn.jpg', 'id': 'mtn', 'color': pendingColor},
    {'name': 'Airtel', 'logo': 'assets/svg/airtel.png', 'id': 'airtel', 'color': errorColor},
    {'name': 'Glo', 'logo': 'assets/svg/glo.jpg', 'id': 'glo', 'color':  successColor},
    {'name': '9mobile', 'logo': 'assets/svg/9mobile.png', 'id': '9mobile', 'color': const Color(0xFF005F54)},
  ];

  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();
  bool _isVerifying = false;
  String? _selectedContactName;

  @override
  void initState() {
    super.initState();
    // Listen to provider changes to support autofill/beneficiary sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneController.addListener(() {
        final formPhone = ref.read(airtimeFormProvider).phoneNumber;
        if (_phoneController.text != formPhone) {
          _phoneController.text = formPhone;
          _phoneController.selection = TextSelection.fromPosition(
            TextPosition(offset: _phoneController.text.length),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _detectNetwork(String input) {
    if (input.length < 4) return;
    final prefix = input.substring(0, 4);

    Map<String, dynamic>? detected;
    final mtnPrefixes = ['0803', '0806', '0703', '0706', '0813', '0816', '0810', '0814', '0903', '0906', '0913', '0916'];
    final airtelPrefixes = ['0802', '0808', '0708', '0812', '0701', '0902', '0907', '0901', '0912', '0911'];
    final gloPrefixes = ['0805', '0807', '0811', '0705', '0815', '0905', '0915'];
    final etisalatPrefixes = ['0809', '0818', '0817', '0909', '0908'];

    if (mtnPrefixes.contains(prefix)) {
      detected = _providers[0];
    } else if (airtelPrefixes.contains(prefix)) {
      detected = _providers[1];
    } else if (gloPrefixes.contains(prefix)) {
      detected = _providers[2];
    } else if (etisalatPrefixes.contains(prefix)) {
      detected = _providers[3];
    }

    if (detected != null && detected != _selectedProvider) {
      setState(() => _selectedProvider = detected);
      ref.read(airtimeFormProvider.notifier).setProvider(detected);
    }
  }

  void _onContactSelected(String phoneNumber, String? contactName) {
    // Clean phone number: remove any non-digit chars and truncate to 11
    final cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final finalPhone = cleaned.length > 11 ? cleaned.substring(cleaned.length - 11) : cleaned;

    setState(() {
      _selectedContactName = contactName;
      _phoneController.text = finalPhone;
    });
    
    _detectNetwork(finalPhone);
    ref.read(airtimeFormProvider.notifier).setPhoneNumber(finalPhone);

    if (finalPhone.length == 11) {
      _verifyPhoneNumber(finalPhone);
    }
  }

  Future<void> _verifyPhoneNumber(String phone) async {
    if (phone.length != 11) return;
    setState(() => _isVerifying = true);
    await ref.read(dashboardControllerProvider.notifier).verifyPhone(context, phone);
    if (mounted) setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = ResponsiveConfig.isSmallScreen(context);
    final formState = ref.watch(airtimeFormProvider);

    // Sync state if changed externally (e.g. from beneficiary tab)
    if (formState.phoneNumber != _phoneController.text) {
      _phoneController.text = formState.phoneNumber;
      _detectNetwork(formState.phoneNumber);
    }

    return Container(
      padding: EdgeInsets.all(isSmall ? 16.w : 20.w),
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Network',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12.h),

          // Horizontal brand badges selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _providers.map((provider) {
              final isSelected = _selectedProvider?['id'] == provider['id'] || 
                                 (formState.selectedProvider?['id'] == provider['id']);
              if (isSelected && _selectedProvider != provider) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedProvider = provider);
                });
              }

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedProvider = provider);
                  ref.read(airtimeFormProvider.notifier).setProvider(provider);
                },
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSmall ? 52.w : 58.w,
                          height: isSmall ? 52.w : 58.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? provider['color'] as Color : const Color(0xFFE2E8F0),
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: (provider['color'] as Color).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ] : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              provider['logo'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(3.r),
                              decoration: BoxDecoration(
                                color: provider['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      provider['name'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? provider['color'] as Color : const Color(0xFF64748B),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 20.h),
          Text(
            'Phone Number',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),

          // High-end responsive phone field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: _phoneController.text.length == 11 ? primaryColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextFieldWithContacts(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    hint: 'Enter 11-digit Phone Number',
                    maxLength: 11,
                    onChanged: (value) {
                      setState(() => _selectedContactName = null);
                      _detectNetwork(value);
                      ref.read(airtimeFormProvider.notifier).setPhoneNumber(value);
                      if (value.length == 11) {
                        _verifyPhoneNumber(value);
                      }
                    },
                    onContactSelected: _onContactSelected,
                  ),
                ),
                if (_isVerifying)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
              ],
            ),
          ),

          if (_selectedContactName != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h, left: 4.w),
              child: Row(
                children: [
                  Icon(Icons.person, size: 14.sp, color: primaryColor),
                  SizedBox(width: 4.w),
                  Text(
                    _selectedContactName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
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
}

// ==================== CARD ONE: AMOUNT SELECTOR ====================

class CardOne extends ConsumerStatefulWidget {
  const CardOne({super.key});

  @override
  ConsumerState<CardOne> createState() => _CardOneState();
}

class _CardOneState extends ConsumerState<CardOne> {
  final TextEditingController _amountController = TextEditingController();
  final List<int> amounts = [50, 100, 200, 500, 1000, 2000, 5000, 10000];
  int? selectedAmount;
  bool showMinimumAmountWarning = false;
  bool showInsufficientFundsWarning = false;
  double walletBalance = 0.0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _getWalletBalance() {
    final box = Hive.box('authBox');
    final balanceStr = box.get('balance', defaultValue: '0').toString();
    return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(airtimeFormProvider);
    final isSmall = ResponsiveConfig.isSmallScreen(context);
    final crossAxisCount = ResponsiveConfig.getGridCrossAxisCount(context);

    // Sync amount if changed externally
    if (formState.amount != selectedAmount && formState.amount != null) {
      selectedAmount = formState.amount;
      _amountController.text = formState.amount.toString();
    }

    return Container(
      padding: EdgeInsets.all(isSmall ? 16.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recharge Amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12.h),

          // Amount Field with integrated Pay button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: selectedAmount != null && selectedAmount! >= 50 ? primaryColor.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '₦',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          hint: 'Min 50',
                          onChanged: (value) {
                            final amount = int.tryParse(value) ?? 0;
                            final balance = _getWalletBalance();

                            setState(() {
                              selectedAmount = amount;
                              walletBalance = balance;
                              showMinimumAmountWarning = amount > 0 && amount < 50;
                              showInsufficientFundsWarning = amount > balance;
                            });

                            ref.read(airtimeFormProvider.notifier).setAmount(amount);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              CustomButton(
                buttonName: 'PAY',
                buttonColor: formState.isValid ? primaryColor : const Color(0xFFCBD5E1),
                buttonTextColor: Colors.white,
                onPressed: formState.isValid ? _handlePay : null,
              ),
            ],
          ),

          // Warnings Panel
          if (showMinimumAmountWarning)
            Padding(
              padding: EdgeInsets.only(top: 8.h, left: 4.w),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: errorColor, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    "Minimum purchase is ₦50",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (showInsufficientFundsWarning)
            Padding(
              padding: EdgeInsets.only(top: 8.h, left: 4.w),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: errorColor, size: 14.sp),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      "Insufficient Balance (₦${walletBalance.toStringAsFixed(2)})",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 20.h),
          Text(
            'Quick Selection',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 10.h),

          // Clean wrapping grid quick amounts
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: 8.h,
                children: amounts.map((amount) {
                  final isSelected = selectedAmount == amount;

                  return GestureDetector(
                    onTap: () {
                      final balance = _getWalletBalance();
                      setState(() {
                        selectedAmount = amount;
                        _amountController.text = amount.toString();
                        walletBalance = balance;
                        showInsufficientFundsWarning = amount > balance;
                        showMinimumAmountWarning = false;
                      });
                      ref.read(airtimeFormProvider.notifier).setAmount(amount);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: itemWidth,
                      height: 38.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ] : null,
                      ),
                      child: Text(
                        '₦$amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handlePay() async {
    final formState = ref.read(airtimeFormProvider);
    if (!formState.isValid) return;

    final provider = formState.selectedProvider!;
    final amount = formState.amount!;
    final phone = formState.phoneNumber;
    final walletBalance = _getWalletBalance();

    if (amount > walletBalance) {
      setState(() {
        showInsufficientFundsWarning = true;
        this.walletBalance = walletBalance;
      });
      return;
    }

    ConfirmationBottomSheet.show(
      context: context,
      config: BottomSheetConfig(
        title: '${Constants.nairaCurrencySymbol}$amount.00',
        subtitle: 'Confirm Airtime Recharge',
        showCashback: true,
        amount: amount.toDouble(),
        cashbackAmount: '+${Constants.nairaCurrencySymbol}1 Cashback',
        details: [
          BottomSheetDetailItem(
            label: 'Network',
            value: provider['name'],
            logo: provider['logo'],
          ),
          BottomSheetDetailItem(label: 'Phone Number', value: phone),
          BottomSheetDetailItem(
            label: 'Amount Paid',
            value: '${Constants.nairaCurrencySymbol}$amount.00',
          ),
        ],
      ),
      onConfirm: (pin) async {
        ref.read(airtimeFormProvider.notifier).setLoading(true);

        final result = await ref
            .read(dashboardControllerProvider.notifier)
            .buyAirtime(
              context,
              phone: phone,
              amount: amount,
              network: provider['id'],
              pin: pin,
            );

        ref.read(airtimeFormProvider.notifier).setLoading(false);
        if (!mounted) return;

        final isSuccess = result?.responseSuccessful == true ||
                          result?.responseBody?.status == "SUCCESS";

        context.goNamed(
          RouteList.successScreen,
          extra: {
            "type": isSuccess ? "success" : "failed",
            "amount": amount.toString(),
            "recipientName": provider['name'],
            "recipientAccount": phone,
            "reference": result?.responseBody?.reference ?? '',
            "channel": "Airtime",
          },
        );
      },
    );
  }
}

// // ==================== CARD THREE: BENEFICIARY ====================
//
// class CardThree extends ConsumerStatefulWidget {
//   const CardThree({super.key});
//
//   @override
//   ConsumerState<CardThree> createState() => _CardThreeState();
// }
//
// class _CardThreeState extends ConsumerState<CardThree> {
//   @override
//   Widget build(BuildContext context) {
//     final isSmall = ResponsiveConfig.isSmallScreen(context);
//     final isTablet = ResponsiveConfig.isTablet(context);
//
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: isSmall ? 16.w : (isTablet ? 24.w : 20.w),
//         vertical: isSmall ? 16.h : (isTablet ? 24.h : 20.h),
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.03),
//             blurRadius: 15,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Select Beneficiary',
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//               fontSize: 15.sp,
//               color: const Color(0xFF1E293B),
//             ),
//           ),
//           SizedBox(height: 12.h),
//
//           ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: isSmall ? 140.h : 165.h,
//               maxHeight: isTablet ? 400.h : 260.h,
//             ),
//             child: BeneficiaryTabSection(
//               favorites: const [
//                 {"name": "Mustapha Garba", "account": "08034567890"},
//                 {"name": "Aisha Bello", "account": "08014567890"},
//               ],
//               recents: const [
//                 {"name": "Fatima Yusuf", "account": "08023456789"},
//                 {"name": "John Musa", "account": "08034567891"},
//               ],
//               onSelectBeneficiary: (name, account) {
//                 debugPrint('Selected $name - $account');
//                 ref.read(airtimeFormProvider.notifier).setPhoneNumber(account);
//               },
//               onSearchTap: () => debugPrint('Search tapped'),
//               showProgress: false,
//               showLogo: true,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
